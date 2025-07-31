import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';

/// Service for persisting notifications and their read status locally
class NotificationPersistenceService {
  static final NotificationPersistenceService _instance = NotificationPersistenceService._internal();
  factory NotificationPersistenceService() => _instance;
  NotificationPersistenceService._internal();

  static const String _notificationsKey = 'persisted_notifications';
  static const String _notifiedUsageRecordsKey = 'notified_usage_records';
  static const String _notifiedInventoryAlertsKey = 'notified_inventory_alerts';
  static const String _lastOrderStatusKey = 'last_order_status';

  // Save notifications to local storage
  Future<void> saveNotifications(List<AppNotification> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = notifications.map((n) => _notificationToJson(n)).toList();
      await prefs.setString(_notificationsKey, jsonEncode(notificationsJson));
      print('💾 Saved ${notifications.length} notifications to local storage');
    } catch (e) {
      print('❌ Failed to save notifications: $e');
    }
  }

  // Load notifications from local storage
  Future<List<AppNotification>> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsString = prefs.getString(_notificationsKey);
      
      if (notificationsString == null) {
        print('💾 No persisted notifications found');
        return [];
      }

      final notificationsJson = jsonDecode(notificationsString) as List;
      final notifications = notificationsJson
          .map((json) => _notificationFromJson(json as Map<String, dynamic>))
          .toList();
      
      print('💾 Loaded ${notifications.length} notifications from local storage');
      return notifications;
    } catch (e) {
      print('❌ Failed to load notifications: $e');
      return [];
    }
  }

  // Save notified usage records
  Future<void> saveNotifiedUsageRecords(Set<String> usageRecordIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_notifiedUsageRecordsKey, usageRecordIds.toList());
      print('💾 Saved ${usageRecordIds.length} notified usage record IDs');
    } catch (e) {
      print('❌ Failed to save notified usage records: $e');
    }
  }

  // Load notified usage records
  Future<Set<String>> loadNotifiedUsageRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usageRecordIds = prefs.getStringList(_notifiedUsageRecordsKey) ?? [];
      print('💾 Loaded ${usageRecordIds.length} notified usage record IDs');
      return usageRecordIds.toSet();
    } catch (e) {
      print('❌ Failed to load notified usage records: $e');
      return <String>{};
    }
  }

  // Save notified inventory alerts
  Future<void> saveNotifiedInventoryAlerts(Map<String, Map<String, bool>> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = alerts.map((key, value) => MapEntry(key, jsonEncode(value)));
      await prefs.setString(_notifiedInventoryAlertsKey, jsonEncode(alertsJson));
      print('💾 Saved notified inventory alerts for ${alerts.length} items');
    } catch (e) {
      print('❌ Failed to save notified inventory alerts: $e');
    }
  }

  // Load notified inventory alerts
  Future<Map<String, Map<String, bool>>> loadNotifiedInventoryAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsString = prefs.getString(_notifiedInventoryAlertsKey);
      
      if (alertsString == null) {
        return {};
      }

      final alertsJson = jsonDecode(alertsString) as Map<String, dynamic>;
      final alerts = alertsJson.map((key, value) {
        final alertMap = jsonDecode(value as String) as Map<String, dynamic>;
        return MapEntry(key, alertMap.cast<String, bool>());
      });
      
      print('💾 Loaded notified inventory alerts for ${alerts.length} items');
      return alerts;
    } catch (e) {
      print('❌ Failed to load notified inventory alerts: $e');
      return {};
    }
  }

  // Save last order status
  Future<void> saveLastOrderStatus(Map<String, String?> orderStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = orderStatus.map((key, value) => MapEntry(key, value ?? ''));
      await prefs.setString(_lastOrderStatusKey, jsonEncode(statusJson));
      print('💾 Saved last order status for ${orderStatus.length} items');
    } catch (e) {
      print('❌ Failed to save last order status: $e');
    }
  }

  // Load last order status
  Future<Map<String, String?>> loadLastOrderStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusString = prefs.getString(_lastOrderStatusKey);
      
      if (statusString == null) {
        return {};
      }

      final statusJson = jsonDecode(statusString) as Map<String, dynamic>;
      final orderStatus = statusJson.map((key, value) {
        final status = value as String;
        return MapEntry(key, status.isEmpty ? null : status);
      });
      
      print('💾 Loaded last order status for ${orderStatus.length} items');
      return orderStatus;
    } catch (e) {
      print('❌ Failed to load last order status: $e');
      return {};
    }
  }

  // Clear all persisted data (for testing/reset)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      await prefs.remove(_notifiedUsageRecordsKey);
      await prefs.remove(_notifiedInventoryAlertsKey);
      await prefs.remove(_lastOrderStatusKey);
      print('💾 Cleared all persisted notification data');
    } catch (e) {
      print('❌ Failed to clear persisted data: $e');
    }
  }

  // Convert notification to JSON
  Map<String, dynamic> _notificationToJson(AppNotification notification) {
    return {
      'id': notification.id,
      'type': notification.type.value,
      'priority': notification.priority.value,
      'title': notification.title,
      'message': notification.message,
      'createdAt': notification.createdAt.toIso8601String(),
      'isRead': notification.isRead,
      'relatedItemId': notification.relatedItemId,
      'relatedUsageId': notification.relatedUsageId,
      'relatedOrderId': notification.relatedOrderId,
      'actionData': notification.actionData,
    };
  }

  // Convert JSON to notification
  AppNotification _notificationFromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      type: NotificationTypeExtension.fromString(json['type'] ?? 'inventory_alert'),
      priority: NotificationPriorityExtension.fromString(json['priority'] ?? 'medium'),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      relatedItemId: json['relatedItemId'],
      relatedUsageId: json['relatedUsageId'],
      relatedOrderId: json['relatedOrderId'],
      actionData: json['actionData'] != null
          ? Map<String, dynamic>.from(json['actionData'])
          : null,
    );
  }
}
