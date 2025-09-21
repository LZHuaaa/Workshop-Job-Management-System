import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/notification.dart';
import '../services/notification_service_factory.dart';
import '../services/inventory_service.dart';
import '../screens/item_details_screen.dart';
import '../screens/inventory_usage_screen.dart';
import '../screens/inventory_screen.dart';

class NotificationDetailView extends StatefulWidget {
  final AppNotification notification;

  const NotificationDetailView({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  State<NotificationDetailView> createState() => _NotificationDetailViewState();
}

class _NotificationDetailViewState extends State<NotificationDetailView> {
  final INotificationService _notificationService = NotificationServiceFactory.getService();
  final InventoryService _inventoryService = InventoryService();
  bool _isMarkingAsRead = false;

  @override
  void initState() {
    super.initState();
    // Automatically mark as read when viewed
    _markAsReadIfNeeded();
  }

  Future<void> _markAsReadIfNeeded() async {
    if (!widget.notification.isRead) {
      setState(() {
        _isMarkingAsRead = true;
      });
      
      try {
        await _notificationService.markAsRead(widget.notification.id);
        print('✅ Marked notification as read: ${widget.notification.id}');
      } catch (e) {
        print('❌ Failed to mark notification as read: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isMarkingAsRead = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPink,
        foregroundColor: Colors.white,
        title: Text(
          'Notification Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with priority indicator
                  Row(
                    children: [
                      _buildPriorityIndicator(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.notification.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (_isMarkingAsRead)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  Text(
                    widget.notification.message,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Metadata
                  _buildMetadataSection(),
                  
                  // Action Data (if available)
                  if (widget.notification.actionData != null) ...[
                    const SizedBox(height: 20),
                    _buildActionDataSection(),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    Color color;
    IconData icon;
    
    switch (widget.notification.priority) {
      case NotificationPriority.critical:
        color = AppColors.errorRed;
        icon = Icons.error;
        break;
      case NotificationPriority.high:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case NotificationPriority.medium:
        color = Colors.blue;
        icon = Icons.info;
        break;
      case NotificationPriority.low:
        color = Colors.grey;
        icon = Icons.info_outline;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildMetadataRow('Type', widget.notification.type.displayName),
        _buildMetadataRow('Priority', widget.notification.priority.displayName),
        _buildMetadataRow('Created', _formatDateTime(widget.notification.createdAt)),
        _buildMetadataRow('Status', widget.notification.isRead ? 'Read' : 'Unread'),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDataSection() {
    final actionData = widget.notification.actionData!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...actionData.entries.where((entry) => entry.key != 'navigationTarget').map(
          (entry) {
            String value = entry.key == 'totalCost' && entry.value is num
                ? 'RM ${(entry.value as num).toStringAsFixed(2)}'
                : entry.value.toString();
            return _buildMetadataRow(
              _formatActionDataKey(entry.key),
              value,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handlePrimaryAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              _getPrimaryActionText(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Secondary action button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleDeleteNotification,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorRed,
              side: BorderSide(color: AppColors.errorRed),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.delete_outline),
            label: Text(
              'Delete Notification',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getPrimaryActionText() {
    switch (widget.notification.type) {
      case NotificationType.inventoryAlert:
        return 'View Item Details';
      case NotificationType.usageVerificationAlert:
        return 'Go to Usage Management';
      case NotificationType.orderStatusUpdate:
        return 'View Inventory';
      default:
        return 'Take Action';
    }
  }

  void _handlePrimaryAction() {
    final navigationTarget = widget.notification.actionData?['navigationTarget'] as String?;
    
    switch (navigationTarget) {
      case 'inventory_details':
        _navigateToItemDetails();
        break;
      case 'usage_management':
        _navigateToUsageManagement();
        break;
      case 'inventory':
      default:
        _navigateToInventory();
        break;
    }
  }

  void _navigateToItemDetails() async {
    final itemId = widget.notification.relatedItemId;
    if (itemId == null) {
      _navigateToInventory();
      return;
    }

    try {
      final item = await _inventoryService.getItemById(itemId);
      if (item != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ItemDetailsScreen(
              item: item,
              onItemUpdated: (updatedItem) {
                // Handle item update if needed
                print('Item updated: ${updatedItem.name}');
              },
            ),
          ),
        );
      } else {
        _navigateToInventory();
      }
    } catch (e) {
      print('❌ Failed to load item details: $e');
      _navigateToInventory();
    }
  }

  void _navigateToUsageManagement() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const InventoryUsageScreen(),
        ),
      );
    }
  }

  void _navigateToInventory() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const InventoryScreen(),
        ),
      );
    }
  }

  void _handleDeleteNotification() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Notification',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this notification?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notificationService.deleteNotification(widget.notification.id);
        if (mounted) {
          Navigator.of(context).pop(); // Go back to notification panel
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
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatActionDataKey(String key) {
    switch (key) {
      case 'alertType':
        return 'Alert Type';
      case 'currentStock':
        return 'Current Stock';
      case 'minStock':
        return 'Minimum Stock';
      case 'itemName':
        return 'Item Name';
      case 'usedBy':
        return 'Used By';
      case 'totalCost':
        return 'Total Cost';
      case 'oldStatus':
        return 'Old Status';
      case 'newStatus':
        return 'New Status';
      default:
        return key.replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }
}
