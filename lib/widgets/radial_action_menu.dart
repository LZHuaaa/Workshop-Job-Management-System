import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Action item for the radial menu
class RadialAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? semanticLabel;

  const RadialAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.semanticLabel,
  });
}

/// A radial (pie) action menu that appears on long press
class RadialActionMenu extends StatefulWidget {
  final List<RadialAction> actions;
  final double radius;
  final double itemSize;
  final double startAngle;
  final Duration animationDuration;
  final Curve animationCurve;
  final VoidCallback? onDismiss;
  final bool showLabels;
  final Color backgroundColor;
  final Color highlightColor;

  const RadialActionMenu({
    super.key,
    required this.actions,
    this.radius = 80.0,
    this.itemSize = 48.0,
    this.startAngle = -math.pi / 2, // Start at top
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.elasticOut,
    this.onDismiss,
    this.showLabels = true,
    this.backgroundColor = Colors.white,
    this.highlightColor = Colors.blue,
  });

  @override
  State<RadialActionMenu> createState() => _RadialActionMenuState();
}

class _RadialActionMenuState extends State<RadialActionMenu>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _highlightController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startEntranceAnimation();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  void _startEntranceAnimation() {
    _animationController.forward();
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
  }

  void _startExitAnimation() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  /// Calculate the angle for each action item
  double _getAngleForIndex(int index) {
    final angleStep = (2 * math.pi) / widget.actions.length;
    return widget.startAngle + (index * angleStep);
  }

  /// Calculate the position for an action item
  Offset _getPositionForIndex(int index) {
    final angle = _getAngleForIndex(index);
    final x = math.cos(angle) * widget.radius;
    final y = math.sin(angle) * widget.radius;
    return Offset(x, y);
  }

  /// Detect which action is being hovered/selected based on touch position
  int? _getHoveredIndex(Offset localPosition) {
    // Convert to center-relative coordinates
    final center = Offset(widget.radius + widget.itemSize + 20,
        widget.radius + widget.itemSize + 20);
    final relative = localPosition - center;

    // Check if within safe radius
    final distance = relative.distance;
    if (distance > widget.radius + widget.itemSize / 2 ||
        distance < widget.itemSize / 2) {
      return null;
    }

    // Calculate angle
    final angle = math.atan2(relative.dy, relative.dx);

    // Normalize angle to 0-2π
    final normalizedAngle = (angle + 2 * math.pi) % (2 * math.pi);
    final startAngleNormalized =
        (widget.startAngle + 2 * math.pi) % (2 * math.pi);

    // Calculate which sector this angle falls into
    final angleStep = (2 * math.pi) / widget.actions.length;

    for (int i = 0; i < widget.actions.length; i++) {
      final itemAngle =
          (startAngleNormalized + (i * angleStep)) % (2 * math.pi);
      final minAngle =
          (itemAngle - angleStep / 2 + 2 * math.pi) % (2 * math.pi);
      final maxAngle = (itemAngle + angleStep / 2) % (2 * math.pi);

      bool inSector = false;
      if (minAngle < maxAngle) {
        inSector = normalizedAngle >= minAngle && normalizedAngle <= maxAngle;
      } else {
        // Handle wraparound case
        inSector = normalizedAngle >= minAngle || normalizedAngle <= maxAngle;
      }

      if (inSector) {
        return i;
      }
    }

    return null;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final newHoveredIndex = _getHoveredIndex(details.localPosition);

      if (newHoveredIndex != _hoveredIndex) {
        _hoveredIndex = newHoveredIndex;
        if (_hoveredIndex != null) {
          HapticFeedback.selectionClick();
          _highlightController.forward();
        } else {
          _highlightController.reverse();
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_hoveredIndex != null) {
      // Trigger the selected action
      final action = widget.actions[_hoveredIndex!];
      HapticFeedback.mediumImpact();

      // Dismiss the menu first, then execute action
      _startExitAnimation();

      // Delay action execution to allow menu to dismiss
      Future.delayed(const Duration(milliseconds: 100), () {
        action.onTap();
      });
    } else {
      _startExitAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = (widget.radius + widget.itemSize + 20) *
        2; // Added padding for better visibility

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: () => _startExitAnimation(), // Tap outside to dismiss
      child: Container(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Stack(
              children: [
                // Background circle (smaller)
                Positioned(
                  left: widget.itemSize + 20,
                  top: widget.itemSize + 20,
                  child: Opacity(
                    opacity: _opacityAnimation.value * 0.1,
                    child: Container(
                      width: widget.radius * 2,
                      height: widget.radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                // Action items
                ...widget.actions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final action = entry.value;
                  final position = _getPositionForIndex(index);
                  final isHovered = _hoveredIndex == index;

                  return AnimatedBuilder(
                    animation: _highlightController,
                    builder: (context, child) {
                      final scale = _scaleAnimation.value;
                      final rotation = _rotationAnimation.value;
                      final highlightScale = isHovered
                          ? 1.0 + (_highlightController.value * 0.2)
                          : 1.0;

                      return Positioned(
                        left: widget.radius +
                            widget.itemSize +
                            20 +
                            (position.dx * scale) -
                            widget.itemSize / 2,
                        top: widget.radius +
                            widget.itemSize +
                            20 +
                            (position.dy * scale) -
                            widget.itemSize / 2,
                        child: Transform.scale(
                          scale: scale * highlightScale,
                          child: Transform.rotate(
                            angle: rotation * 2 * math.pi,
                            child: Opacity(
                              opacity: _opacityAnimation.value,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _startExitAnimation();
                                  Future.delayed(
                                      const Duration(milliseconds: 100), () {
                                    action.onTap();
                                  });
                                },
                                child: Semantics(
                                  label: action.semanticLabel ?? action.label,
                                  button: true,
                                  onTap: action.onTap,
                                  child: Container(
                                    width: widget.itemSize,
                                    height: widget.itemSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isHovered
                                          ? action.color.withOpacity(0.9)
                                          : widget.backgroundColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                        if (isHovered)
                                          BoxShadow(
                                            color:
                                                action.color.withOpacity(0.5),
                                            blurRadius: 12,
                                            offset: const Offset(0, 0),
                                          ),
                                      ],
                                      border: Border.all(
                                        color: isHovered
                                            ? action.color
                                            : action.color.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          action.icon,
                                          color: isHovered
                                              ? Colors.white
                                              : action.color,
                                          size: 20,
                                        ),
                                        if (widget.showLabels && isHovered) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            action.label,
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Overlay manager for showing radial menus
class RadialMenuOverlay {
  static OverlayEntry? _currentOverlay;

  /// Show a radial menu at the specified position
  static void show({
    required BuildContext context,
    required Offset position,
    required List<RadialAction> actions,
    double radius = 80.0,
    double itemSize = 48.0,
    Duration animationDuration = const Duration(milliseconds: 300),
    bool showLabels = true,
  }) {
    // Remove any existing overlay
    dismiss();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final menuSize = (radius + itemSize) * 2;

    // Adjust position to keep menu on screen
    var adjustedPosition = position;
    if (adjustedPosition.dx + menuSize > size.width) {
      adjustedPosition = Offset(size.width - menuSize, adjustedPosition.dy);
    }
    if (adjustedPosition.dy + menuSize > size.height) {
      adjustedPosition = Offset(adjustedPosition.dx, size.height - menuSize);
    }
    if (adjustedPosition.dx < 0) {
      adjustedPosition = Offset(0, adjustedPosition.dy);
    }
    if (adjustedPosition.dy < 0) {
      adjustedPosition = Offset(adjustedPosition.dx, 0);
    }

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: adjustedPosition.dx,
        top: adjustedPosition.dy,
        child: Material(
          color: Colors.transparent,
          child: RadialActionMenu(
            actions: actions,
            radius: radius,
            itemSize: itemSize,
            animationDuration: animationDuration,
            showLabels: showLabels,
            onDismiss: dismiss,
          ),
        ),
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  /// Dismiss the current radial menu
  static void dismiss() {
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
    }
  }

  /// Check if a menu is currently showing
  static bool get isShowing => _currentOverlay != null;
}
