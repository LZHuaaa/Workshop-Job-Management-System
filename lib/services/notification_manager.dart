import 'dart:async';
import '../services/notification_service_factory.dart';
import '../services/local_notification_service.dart';
import '../services/notification_persistence_service.dart';
import '../services/inventory_service.dart';
import '../services/inventory_usage_service.dart';
import '../models/inventory_item.dart';
import '../models/inventory_usage.dart';
import '../models/notification.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final LocalNotificationService _localNotificationService = LocalNotificationService();
  final NotificationPersistenceService _persistenceService = NotificationPersistenceService();
  final InventoryService _inventoryService = InventoryService();
  final InventoryUsageService _usageService = InventoryUsageService();

  StreamSubscription<List<InventoryItem>>? _inventorySubscription;
  StreamSubscription<List<InventoryUsage>>? _usageSubscription;
  
  final Map<String, bool> _lowStockNotified = {};
  final Map<String, bool> _criticalStockNotified = {};
  final Map<String, bool> _outOfStockNotified = {};
  final Map<String, OrderRequestStatus?> _lastOrderStatus = {};
  Set<String> _notifiedUsageRecords = {};

  bool _isInitialized = false;

  // Initialize the notification manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔔 Initializing Notification Manager...');

    // Initialize the local notification service
    await _localNotificationService.initialize();

    // Load persisted notification state
    await _loadPersistedState();

    // Start monitoring inventory levels
    _startInventoryMonitoring();

    // Start monitoring usage records
    _startUsageMonitoring();

    _isInitialized = true;
    print('✅ Notification Manager initialized successfully');
  }

  // Stop all monitoring
  void dispose() {
    _inventorySubscription?.cancel();
    _usageSubscription?.cancel();
    _isInitialized = false;
    print('🔔 Notification Manager disposed');
  }

  // Start monitoring inventory levels for stock alerts
  void _startInventoryMonitoring() {
    _inventorySubscription = _inventoryService.getInventoryItems().listen(
      (items) {
        _checkInventoryLevels(items);
        _checkOrderStatusChanges(items);
      },
      onError: (error) {
        print('❌ Error monitoring inventory: $error');
      },
    );
  }

  // Start monitoring usage records for verification alerts
  void _startUsageMonitoring() {
    _usageSubscription = _usageService.getAllUsageRecords().listen(
      (usageRecords) {
        _checkNewUsageRecords(usageRecords);
      },
      onError: (error) {
        print('❌ Error monitoring usage records: $error');
      },
    );
  }

  // Check inventory levels and generate stock alerts
  void _checkInventoryLevels(List<InventoryItem> items) {
    print('🔍 Checking inventory levels for ${items.length} items...');

    for (final item in items) {
      final itemId = item.id;

      // Debug logging
      print('📦 Item: ${item.name}, Stock: ${item.currentStock}, Min: ${item.minStock}');
      print('   - isOutOfStock: ${item.isOutOfStock}');
      print('   - isCriticalStock: ${item.isCriticalStock}');
      print('   - isLowStock: ${item.isLowStock}');

      // Check for out of stock
      if (item.isOutOfStock) {
        if (!_outOfStockNotified.containsKey(itemId) || !_outOfStockNotified[itemId]!) {
          print('🚨 Creating out of stock alert for ${item.name}');
          _createInventoryAlert(item, 'out_of_stock');
          _outOfStockNotified[itemId] = true;
          _criticalStockNotified[itemId] = true; // Also mark critical as notified
          _lowStockNotified[itemId] = true; // Also mark low stock as notified
        }
      }
      // Check for critical stock
      else if (item.isCriticalStock) {
        if (!_criticalStockNotified.containsKey(itemId) || !_criticalStockNotified[itemId]!) {
          print('⚠️ Creating critical stock alert for ${item.name}');
          _createInventoryAlert(item, 'critical_stock');
          _criticalStockNotified[itemId] = true;
          _lowStockNotified[itemId] = true; // Also mark low stock as notified
        }
      }
      // Check for low stock
      else if (item.isLowStock) {
        if (!_lowStockNotified.containsKey(itemId) || !_lowStockNotified[itemId]!) {
          print('📉 Creating low stock alert for ${item.name}');
          _createInventoryAlert(item, 'low_stock');
          _lowStockNotified[itemId] = true;
        }
      }
      // Reset notifications if stock is back to normal
      else {
        if (_lowStockNotified[itemId] == true || _criticalStockNotified[itemId] == true || _outOfStockNotified[itemId] == true) {
          print('✅ Stock levels normalized for ${item.name}, resetting notification flags');
        }
        _lowStockNotified[itemId] = false;
        _criticalStockNotified[itemId] = false;
        _outOfStockNotified[itemId] = false;
      }
    }

    print('✅ Inventory level check completed');
  }

  // Check for order status changes
  void _checkOrderStatusChanges(List<InventoryItem> items) {
    for (final item in items) {
      final itemId = item.id;
      final currentStatus = item.orderRequestStatus;
      final lastStatus = _lastOrderStatus[itemId];

      // Check if status has changed
      if (lastStatus != currentStatus && lastStatus != null) {
        _createOrderStatusNotification(item, lastStatus, currentStatus);
      }

      // Update the last known status
      _lastOrderStatus[itemId] = currentStatus;
    }
  }

  // Check for new usage records that need verification
  void _checkNewUsageRecords(List<InventoryUsage> usageRecords) {
    for (final usage in usageRecords) {
      // Only notify for unverified records that haven't been notified yet
      if (usage.status == UsageStatus.recorded && !_notifiedUsageRecords.contains(usage.id)) {
        _createUsageVerificationNotification(usage);
        _notifiedUsageRecords.add(usage.id);
      }
    }
  }

  // Create inventory alert notification
  Future<void> _createInventoryAlert(InventoryItem item, String alertType) async {
    try {
      // Create notification using local notification service
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      String title;
      String message;
      NotificationPriority priority;

      switch (alertType) {
        case 'out_of_stock':
          title = 'Out of Stock Alert';
          message = '${item.name} is completely out of stock!';
          priority = NotificationPriority.critical;
          break;
        case 'critical_stock':
          title = 'Critical Stock Alert';
          message = '${item.name} has critically low stock (${item.currentStock} remaining)';
          priority = NotificationPriority.high;
          break;
        case 'low_stock':
        default:
          title = 'Low Stock Alert';
          message = '${item.name} is running low (${item.currentStock} remaining, minimum: ${item.minStock})';
          priority = NotificationPriority.medium;
          break;
      }

      final notification = AppNotification.inventoryAlert(
        id: id,
        title: title,
        message: message,
        priority: priority,
        relatedItemId: item.id,
        actionData: {
          'alertType': alertType,
          'currentStock': item.currentStock,
          'minStock': item.minStock,
          'navigationTarget': 'inventory_details',
        },
      );

      await _localNotificationService.addNotification(notification);
      await _saveNotificationState(); // Save state after creating notification
      print('🔔 Created $alertType alert for ${item.name}');
    } catch (e) {
      print('❌ Failed to create inventory alert: $e');
    }
  }

  // Create order status update notification
  Future<void> _createOrderStatusNotification(
    InventoryItem item,
    OrderRequestStatus? oldStatus,
    OrderRequestStatus? newStatus,
  ) async {
    try {
      final oldStatusText = oldStatus?.value ?? 'none';
      final newStatusText = newStatus?.value ?? 'none';
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      String title;
      String message;
      NotificationPriority priority;

      switch (newStatusText) {
        case 'approved':
          title = 'Order Request Approved';
          message = 'Order request for ${item.name} has been approved';
          priority = NotificationPriority.medium;
          break;
        case 'completed':
          title = 'Order Completed';
          message = '${item.name} has been restocked and is now available';
          priority = NotificationPriority.medium;
          break;
        case 'rejected':
          title = 'Order Request Rejected';
          message = 'Order request for ${item.name} has been rejected';
          priority = NotificationPriority.high;
          break;
        default:
          title = 'Order Status Update';
          message = 'Order status for ${item.name} changed from $oldStatusText to $newStatusText';
          priority = NotificationPriority.low;
          break;
      }

      final notification = AppNotification.orderStatusUpdate(
        id: id,
        title: title,
        message: message,
        priority: priority,
        relatedItemId: item.id,
        relatedOrderId: item.orderRequestId,
        actionData: {
          'oldStatus': oldStatusText,
          'newStatus': newStatusText,
          'navigationTarget': 'inventory_details',
        },
      );

      await _localNotificationService.addNotification(notification);
      await _saveNotificationState(); // Save state after creating notification
      print('🔔 Created order status update for ${item.name}: $oldStatusText -> $newStatusText');
    } catch (e) {
      print('❌ Failed to create order status notification: $e');
    }
  }

  // Create usage verification notification
  Future<void> _createUsageVerificationNotification(InventoryUsage usage) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final notification = AppNotification.usageVerificationAlert(
        id: id,
        title: 'New Usage Record',
        message: '${usage.usedBy} used ${usage.itemName} (RM ${usage.totalCost.toStringAsFixed(2)}) - requires verification',
        priority: NotificationPriority.medium,
        relatedUsageId: usage.id,
        actionData: {
          'itemName': usage.itemName,
          'usedBy': usage.usedBy,
          'totalCost': usage.totalCost,
          'navigationTarget': 'usage_management',
        },
      );

      await _localNotificationService.addNotification(notification);
      await _saveNotificationState(); // Save state after creating notification
      print('🔔 Created usage verification alert for ${usage.itemName}');
    } catch (e) {
      print('❌ Failed to create usage verification notification: $e');
    }
  }

  // Manually trigger inventory check (useful for testing)
  Future<void> triggerInventoryCheck() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final items = await _inventoryService.getInventoryItems().first;
      _checkInventoryLevels(items);
      print('🔔 Manual inventory check completed');
    } catch (e) {
      print('❌ Failed to trigger inventory check: $e');
    }
  }

  // Manually trigger usage check (useful for testing)
  Future<void> triggerUsageCheck() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final usageRecords = await _usageService.getAllUsageRecords().first;
      _checkNewUsageRecords(usageRecords);
      print('🔔 Manual usage check completed');
    } catch (e) {
      print('❌ Failed to trigger usage check: $e');
    }
  }

  // Load persisted notification state
  Future<void> _loadPersistedState() async {
    try {
      // Load notified usage records
      _notifiedUsageRecords = await _persistenceService.loadNotifiedUsageRecords();

      // Load notified inventory alerts
      final inventoryAlerts = await _persistenceService.loadNotifiedInventoryAlerts();
      for (final entry in inventoryAlerts.entries) {
        final itemId = entry.key;
        final alerts = entry.value;
        _lowStockNotified[itemId] = alerts['lowStock'] ?? false;
        _criticalStockNotified[itemId] = alerts['criticalStock'] ?? false;
        _outOfStockNotified[itemId] = alerts['outOfStock'] ?? false;
      }

      // Load last order status
      final orderStatus = await _persistenceService.loadLastOrderStatus();
      for (final entry in orderStatus.entries) {
        _lastOrderStatus[entry.key] = entry.value != null
            ? OrderRequestStatusExtension.fromString(entry.value!)
            : null;
      }

      print('💾 Loaded persisted notification state');
    } catch (e) {
      print('❌ Failed to load persisted state: $e');
    }
  }

  // Save notification state to persistence
  Future<void> _saveNotificationState() async {
    try {
      // Save notified usage records
      await _persistenceService.saveNotifiedUsageRecords(_notifiedUsageRecords);

      // Save notified inventory alerts
      final inventoryAlerts = <String, Map<String, bool>>{};
      for (final itemId in {..._lowStockNotified.keys, ..._criticalStockNotified.keys, ..._outOfStockNotified.keys}) {
        inventoryAlerts[itemId] = {
          'lowStock': _lowStockNotified[itemId] ?? false,
          'criticalStock': _criticalStockNotified[itemId] ?? false,
          'outOfStock': _outOfStockNotified[itemId] ?? false,
        };
      }
      await _persistenceService.saveNotifiedInventoryAlerts(inventoryAlerts);

      // Save last order status
      final orderStatus = _lastOrderStatus.map((key, value) => MapEntry(key, value?.value));
      await _persistenceService.saveLastOrderStatus(orderStatus);

      print('💾 Saved notification state');
    } catch (e) {
      print('❌ Failed to save notification state: $e');
    }
  }

  // Reset notification flags (useful for testing)
  void resetNotificationFlags() {
    _lowStockNotified.clear();
    _criticalStockNotified.clear();
    _outOfStockNotified.clear();
    _lastOrderStatus.clear();
    _notifiedUsageRecords.clear();
    print('🔔 Notification flags reset');
  }

  // Get monitoring status
  bool get isMonitoring => _isInitialized;
  
  // Get notification statistics
  Map<String, int> get notificationStats => {
    'lowStockNotified': _lowStockNotified.values.where((v) => v).length,
    'criticalStockNotified': _criticalStockNotified.values.where((v) => v).length,
    'outOfStockNotified': _outOfStockNotified.values.where((v) => v).length,
    'usageRecordsNotified': _notifiedUsageRecords.length,
  };


}
