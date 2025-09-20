import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/notification.dart';
import '../screens/inventory_screen.dart';
import '../screens/inventory_usage_screen.dart';
import '../screens/item_details_screen.dart';
import '../services/inventory_service.dart';
import '../services/notification_service_factory.dart';
import '../theme/app_colors.dart';
import '../widgets/notification_item.dart';

class NotificationPanel extends StatefulWidget {
  final VoidCallback? onClose;

  const NotificationPanel({
    super.key,
    this.onClose,
  });

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  final INotificationService _notificationService = NotificationServiceFactory.getService();
  final InventoryService _inventoryService = InventoryService();
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Unread',
    'Inventory Alerts',
    'Order Updates',
    'Usage Verification',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                // Mark all as read button
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    await _notificationService.markAllAsRead();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'All notifications marked as read',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Mark all',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Delete all notifications button (for managers)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showDeleteAllConfirmation(),
                  child: Text(
                    'Delete all',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: widget.onClose,
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter tabs
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = filter == _selectedFilter;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: AppColors.backgroundLight,
                    selectedColor: AppColors.primaryPink,
                    checkmarkColor: Colors.white,
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),

          // Notifications list
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: _getFilteredNotifications(),
              builder: (context, snapshot) {
                print('🔔 NotificationPanel StreamBuilder: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}');
                if (snapshot.hasData) {
                  print('🔔 NotificationPanel StreamBuilder: data length=${snapshot.data?.length}');
                }
                if (snapshot.hasError) {
                  print('🔔 NotificationPanel StreamBuilder: error=${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  print('🔔 NotificationPanel: Showing loading indicator');
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  print('❌ Notification panel error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.errorRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your connection and try again',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Trigger rebuild to retry
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'All' 
                              ? 'No notifications yet'
                              : 'No ${_selectedFilter.toLowerCase()} notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    
                    return NotificationItem(
                      notification: notification,
                      onTap: () => _handleNotificationTap(notification),
                      onMarkAsRead: () => _markAsRead(notification),
                      onDelete: () => _deleteNotification(notification),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<AppNotification>> _getFilteredNotifications() {
    switch (_selectedFilter) {
      case 'Unread':
        return _notificationService.getUnreadNotifications();
      case 'Inventory Alerts':
        return _notificationService.getNotificationsByType(NotificationType.inventoryAlert);
      case 'Order Updates':
        return _notificationService.getNotificationsByType(NotificationType.orderStatusUpdate);
      case 'Usage Verification':
        return _notificationService.getNotificationsByType(NotificationType.usageVerificationAlert);
      case 'All':
      default:
        return _notificationService.getAllNotifications();
    }
  }

  void _handleNotificationTap(AppNotification notification) async {
    // Mark as read when tapped
    if (!notification.isRead) {
      await _markAsRead(notification);
    }

    // Navigate based on notification type and action data
    if (notification.actionData != null) {
      final navigationTarget = notification.actionData!['navigationTarget'];
      
      switch (navigationTarget) {
        case 'inventory_details':
          if (notification.relatedItemId != null) {
            // Navigate to inventory item details
            // This would require getting the item first
            _navigateToInventoryDetails(notification.relatedItemId!);
          }
          break;
        case 'usage_management':
          // Navigate to usage management screen
          _navigateToUsageManagement();
          break;
      }
    }

    // Close the panel
    widget.onClose?.call();
  }

  void _navigateToInventoryDetails(String itemId) async {
    try {
      // Get the inventory item
      final item = await _inventoryService.getInventoryItem(itemId);
      if (item != null && mounted) {
        Navigator.of(context).pop(); // Close the panel
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ItemDetailsScreen(
              item: item,
              onItemUpdated: (updatedItem) {
                // Handle item updates if needed
                // For now, just print the update
                print('Item updated: ${updatedItem.name}');
              },
            ),
          ),
        );
      } else {
        // Item not found, navigate to inventory screen instead
        Navigator.of(context).pop(); // Close the panel
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const InventoryScreen(),
          ),
        );
      }
    } catch (e) {
      // Error getting item, navigate to inventory screen
      Navigator.of(context).pop(); // Close the panel
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const InventoryScreen(),
        ),
      );
    }
  }

  void _navigateToUsageManagement() {
    Navigator.of(context).pop(); // Close the panel
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InventoryUsageScreen(),
      ),
    );
  }

  Future<void> _markAsRead(AppNotification notification) async {
    try {
      await _notificationService.markAsRead(notification.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to mark notification as read',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      await _notificationService.deleteNotification(notification.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification deleted',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete notification',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  // Show confirmation dialog for deleting all notifications
  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete All Notifications',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          content: Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllNotifications();
              },
              child: Text(
                'Delete All',
                style: GoogleFonts.poppins(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Delete all notifications
  void _deleteAllNotifications() async {
    try {
      // Get all notifications first
      final allNotifications = await _notificationService.getAllNotifications().first;

      // Delete each notification
      for (final notification in allNotifications) {
        await _notificationService.deleteNotification(notification.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All notifications deleted successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete notifications: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}
