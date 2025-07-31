import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  inventoryAlert,
  orderStatusUpdate,
  usageVerificationAlert,
}

enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.inventoryAlert:
        return 'inventory_alert';
      case NotificationType.orderStatusUpdate:
        return 'order_status_update';
      case NotificationType.usageVerificationAlert:
        return 'usage_verification_alert';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.inventoryAlert:
        return 'Inventory Alert';
      case NotificationType.orderStatusUpdate:
        return 'Order Status Update';
      case NotificationType.usageVerificationAlert:
        return 'Usage Verification Alert';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'inventory_alert':
        return NotificationType.inventoryAlert;
      case 'order_status_update':
        return NotificationType.orderStatusUpdate;
      case 'usage_verification_alert':
        return NotificationType.usageVerificationAlert;
      default:
        return NotificationType.inventoryAlert;
    }
  }
}

extension NotificationPriorityExtension on NotificationPriority {
  String get value {
    switch (this) {
      case NotificationPriority.low:
        return 'low';
      case NotificationPriority.medium:
        return 'medium';
      case NotificationPriority.high:
        return 'high';
      case NotificationPriority.critical:
        return 'critical';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.critical:
        return 'Critical';
    }
  }

  static NotificationPriority fromString(String value) {
    switch (value) {
      case 'low':
        return NotificationPriority.low;
      case 'medium':
        return NotificationPriority.medium;
      case 'high':
        return NotificationPriority.high;
      case 'critical':
        return NotificationPriority.critical;
      default:
        return NotificationPriority.medium;
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedItemId; // For inventory items
  final String? relatedUsageId; // For usage records
  final String? relatedOrderId; // For order requests
  final Map<String, dynamic>? actionData; // Additional data for navigation/actions

  AppNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.relatedItemId,
    this.relatedUsageId,
    this.relatedOrderId,
    this.actionData,
  });

  // Helper getters
  bool get isInventoryAlert => type == NotificationType.inventoryAlert;
  bool get isOrderStatusUpdate => type == NotificationType.orderStatusUpdate;
  bool get isUsageVerificationAlert => type == NotificationType.usageVerificationAlert;

  bool get isCritical => priority == NotificationPriority.critical;
  bool get isHigh => priority == NotificationPriority.high;
  bool get isMedium => priority == NotificationPriority.medium;
  bool get isLow => priority == NotificationPriority.low;

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? relatedItemId,
    String? relatedUsageId,
    String? relatedOrderId,
    Map<String, dynamic>? actionData,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      relatedUsageId: relatedUsageId ?? this.relatedUsageId,
      relatedOrderId: relatedOrderId ?? this.relatedOrderId,
      actionData: actionData ?? this.actionData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'priority': priority.value,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'relatedItemId': relatedItemId,
      'relatedUsageId': relatedUsageId,
      'relatedOrderId': relatedOrderId,
      'actionData': actionData,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      type: NotificationTypeExtension.fromString(json['type']),
      priority: NotificationPriorityExtension.fromString(json['priority']),
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
      relatedItemId: json['relatedItemId'],
      relatedUsageId: json['relatedUsageId'],
      relatedOrderId: json['relatedOrderId'],
      actionData: json['actionData'] != null 
          ? Map<String, dynamic>.from(json['actionData'])
          : null,
    );
  }

  // Factory methods for creating specific notification types
  factory AppNotification.inventoryAlert({
    required String id,
    required String title,
    required String message,
    required NotificationPriority priority,
    String? relatedItemId,
    Map<String, dynamic>? actionData,
  }) {
    return AppNotification(
      id: id,
      type: NotificationType.inventoryAlert,
      priority: priority,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      relatedItemId: relatedItemId,
      actionData: actionData,
    );
  }

  factory AppNotification.orderStatusUpdate({
    required String id,
    required String title,
    required String message,
    required NotificationPriority priority,
    String? relatedItemId,
    String? relatedOrderId,
    Map<String, dynamic>? actionData,
  }) {
    return AppNotification(
      id: id,
      type: NotificationType.orderStatusUpdate,
      priority: priority,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      relatedItemId: relatedItemId,
      relatedOrderId: relatedOrderId,
      actionData: actionData,
    );
  }

  factory AppNotification.usageVerificationAlert({
    required String id,
    required String title,
    required String message,
    required NotificationPriority priority,
    String? relatedUsageId,
    Map<String, dynamic>? actionData,
  }) {
    return AppNotification(
      id: id,
      type: NotificationType.usageVerificationAlert,
      priority: priority,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      relatedUsageId: relatedUsageId,
      actionData: actionData,
    );
  }
}
