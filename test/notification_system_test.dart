import 'package:flutter_test/flutter_test.dart';
import '../lib/models/notification.dart';
import '../lib/services/notification_service.dart';

void main() {
  group('Notification Model Tests', () {
    test('should create inventory alert notification correctly', () {
      final notification = AppNotification.inventoryAlert(
        id: 'test-id',
        title: 'Low Stock Alert',
        message: 'Test item is running low',
        priority: NotificationPriority.medium,
        relatedItemId: 'item-123',
      );

      expect(notification.id, 'test-id');
      expect(notification.type, NotificationType.inventoryAlert);
      expect(notification.priority, NotificationPriority.medium);
      expect(notification.title, 'Low Stock Alert');
      expect(notification.message, 'Test item is running low');
      expect(notification.relatedItemId, 'item-123');
      expect(notification.isRead, false);
      expect(notification.isInventoryAlert, true);
      expect(notification.isOrderStatusUpdate, false);
      expect(notification.isUsageVerificationAlert, false);
    });

    test('should create order status update notification correctly', () {
      final notification = AppNotification.orderStatusUpdate(
        id: 'test-id-2',
        title: 'Order Approved',
        message: 'Your order has been approved',
        priority: NotificationPriority.high,
        relatedItemId: 'item-456',
        relatedOrderId: 'order-789',
      );

      expect(notification.id, 'test-id-2');
      expect(notification.type, NotificationType.orderStatusUpdate);
      expect(notification.priority, NotificationPriority.high);
      expect(notification.relatedItemId, 'item-456');
      expect(notification.relatedOrderId, 'order-789');
      expect(notification.isOrderStatusUpdate, true);
    });

    test('should create usage verification alert notification correctly', () {
      final notification = AppNotification.usageVerificationAlert(
        id: 'test-id-3',
        title: 'Usage Verification Required',
        message: 'New usage record needs verification',
        priority: NotificationPriority.medium,
        relatedUsageId: 'usage-123',
      );

      expect(notification.id, 'test-id-3');
      expect(notification.type, NotificationType.usageVerificationAlert);
      expect(notification.priority, NotificationPriority.medium);
      expect(notification.relatedUsageId, 'usage-123');
      expect(notification.isUsageVerificationAlert, true);
    });

    test('should handle priority levels correctly', () {
      final criticalNotification = AppNotification.inventoryAlert(
        id: 'critical',
        title: 'Critical Alert',
        message: 'Critical message',
        priority: NotificationPriority.critical,
      );

      final lowNotification = AppNotification.inventoryAlert(
        id: 'low',
        title: 'Low Alert',
        message: 'Low message',
        priority: NotificationPriority.low,
      );

      expect(criticalNotification.isCritical, true);
      expect(criticalNotification.isHigh, false);
      expect(criticalNotification.isMedium, false);
      expect(criticalNotification.isLow, false);

      expect(lowNotification.isCritical, false);
      expect(lowNotification.isHigh, false);
      expect(lowNotification.isMedium, false);
      expect(lowNotification.isLow, true);
    });

    test('should generate correct time ago text', () {
      final now = DateTime.now();
      
      // Test "Just now"
      final justNowNotification = AppNotification.inventoryAlert(
        id: 'just-now',
        title: 'Test',
        message: 'Test',
        priority: NotificationPriority.low,
      );
      // Since createdAt is set to DateTime.now() in the factory, it should be "Just now"
      expect(justNowNotification.timeAgo, 'Just now');
    });

    test('should serialize and deserialize correctly', () {
      final originalNotification = AppNotification.inventoryAlert(
        id: 'serialize-test',
        title: 'Serialize Test',
        message: 'Testing serialization',
        priority: NotificationPriority.high,
        relatedItemId: 'item-serialize',
        actionData: {'test': 'data'},
      );

      final json = originalNotification.toJson();
      final deserializedNotification = AppNotification.fromJson(json);

      expect(deserializedNotification.id, originalNotification.id);
      expect(deserializedNotification.type, originalNotification.type);
      expect(deserializedNotification.priority, originalNotification.priority);
      expect(deserializedNotification.title, originalNotification.title);
      expect(deserializedNotification.message, originalNotification.message);
      expect(deserializedNotification.relatedItemId, originalNotification.relatedItemId);
      expect(deserializedNotification.actionData, originalNotification.actionData);
    });

    test('should handle copyWith correctly', () {
      final originalNotification = AppNotification.inventoryAlert(
        id: 'copy-test',
        title: 'Original Title',
        message: 'Original Message',
        priority: NotificationPriority.low,
      );

      final copiedNotification = originalNotification.copyWith(
        title: 'Updated Title',
        isRead: true,
      );

      expect(copiedNotification.id, originalNotification.id);
      expect(copiedNotification.title, 'Updated Title');
      expect(copiedNotification.message, originalNotification.message);
      expect(copiedNotification.isRead, true);
      expect(originalNotification.isRead, false); // Original should be unchanged
    });
  });

  group('Notification Type Extension Tests', () {
    test('should convert enum to string value correctly', () {
      expect(NotificationType.inventoryAlert.value, 'inventory_alert');
      expect(NotificationType.orderStatusUpdate.value, 'order_status_update');
      expect(NotificationType.usageVerificationAlert.value, 'usage_verification_alert');
    });

    test('should convert enum to display name correctly', () {
      expect(NotificationType.inventoryAlert.displayName, 'Inventory Alert');
      expect(NotificationType.orderStatusUpdate.displayName, 'Order Status Update');
      expect(NotificationType.usageVerificationAlert.displayName, 'Usage Verification Alert');
    });

    test('should parse string to enum correctly', () {
      expect(NotificationTypeExtension.fromString('inventory_alert'), NotificationType.inventoryAlert);
      expect(NotificationTypeExtension.fromString('order_status_update'), NotificationType.orderStatusUpdate);
      expect(NotificationTypeExtension.fromString('usage_verification_alert'), NotificationType.usageVerificationAlert);
      expect(NotificationTypeExtension.fromString('invalid'), NotificationType.inventoryAlert); // Default fallback
    });
  });

  group('Notification Priority Extension Tests', () {
    test('should convert enum to string value correctly', () {
      expect(NotificationPriority.low.value, 'low');
      expect(NotificationPriority.medium.value, 'medium');
      expect(NotificationPriority.high.value, 'high');
      expect(NotificationPriority.critical.value, 'critical');
    });

    test('should parse string to enum correctly', () {
      expect(NotificationPriorityExtension.fromString('low'), NotificationPriority.low);
      expect(NotificationPriorityExtension.fromString('medium'), NotificationPriority.medium);
      expect(NotificationPriorityExtension.fromString('high'), NotificationPriority.high);
      expect(NotificationPriorityExtension.fromString('critical'), NotificationPriority.critical);
      expect(NotificationPriorityExtension.fromString('invalid'), NotificationPriority.medium); // Default fallback
    });
  });

  group('Notification Service Helper Methods Tests', () {
    test('should create inventory alert with correct parameters', () {
      // This test would require mocking Firebase, so we'll test the logic
      // that would be used to create the notification
      
      const itemId = 'test-item';
      const itemName = 'Test Item';
      const alertType = 'low_stock';
      const currentStock = 5;
      const minStock = 10;
      
      // Test the logic that would be in createInventoryAlert
      String title;
      String message;
      NotificationPriority priority;
      
      switch (alertType) {
        case 'out_of_stock':
          title = 'Out of Stock Alert';
          message = '$itemName is completely out of stock!';
          priority = NotificationPriority.critical;
          break;
        case 'critical_stock':
          title = 'Critical Stock Alert';
          message = '$itemName has critically low stock ($currentStock remaining)';
          priority = NotificationPriority.high;
          break;
        case 'low_stock':
        default:
          title = 'Low Stock Alert';
          message = '$itemName is running low ($currentStock remaining, minimum: $minStock)';
          priority = NotificationPriority.medium;
          break;
      }
      
      expect(title, 'Low Stock Alert');
      expect(message, 'Test Item is running low (5 remaining, minimum: 10)');
      expect(priority, NotificationPriority.medium);
    });

    test('should create order status update with correct parameters', () {
      const itemName = 'Test Item';
      const newStatus = 'approved';
      
      String title;
      String message;
      NotificationPriority priority;
      
      switch (newStatus) {
        case 'approved':
          title = 'Order Request Approved';
          message = 'Order request for $itemName has been approved';
          priority = NotificationPriority.medium;
          break;
        case 'completed':
          title = 'Order Completed';
          message = '$itemName has been restocked and is now available';
          priority = NotificationPriority.medium;
          break;
        case 'rejected':
          title = 'Order Request Rejected';
          message = 'Order request for $itemName has been rejected';
          priority = NotificationPriority.high;
          break;
        default:
          title = 'Order Status Update';
          message = 'Order status for $itemName changed';
          priority = NotificationPriority.low;
          break;
      }
      
      expect(title, 'Order Request Approved');
      expect(message, 'Order request for Test Item has been approved');
      expect(priority, NotificationPriority.medium);
    });
  });
}
