import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';



class NotificationServiceException implements Exception {
  final String message;
  NotificationServiceException(this.message);
  
  @override
  String toString() => 'NotificationServiceException: $message';
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'notifications';

  // Get notifications collection reference
  CollectionReference get _notificationsRef => _firestore.collection(_collection);

  // Check if user is authenticated
  bool get _isAuthenticated => _auth.currentUser != null;

  // Get all notifications as stream (ordered by creation date, newest first)
  Stream<List<AppNotification>> getAllNotifications() {
    // Check authentication first
    if (!_isAuthenticated) {
      print('⚠️ User not authenticated, returning empty notifications stream');
      return Stream.value(<AppNotification>[]);
    }

    return _notificationsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <AppNotification>[];
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToNotification(data);
      }).toList();
    }).handleError((error) {
      print('❌ Error in getAllNotifications stream: $error');
    });
  }

  // Get unread notifications count
  Stream<int> getUnreadNotificationsCount() {
    // Check authentication first
    if (!_isAuthenticated) {
      print('⚠️ User not authenticated, returning 0 notification count');
      return Stream.value(0);
    }

    return _notificationsRef
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      print('❌ Error in getUnreadNotificationsCount stream: $error');
    });
  }

  // Get unread notifications
  Stream<List<AppNotification>> getUnreadNotifications() {
    // Check authentication first
    if (!_isAuthenticated) {
      print('⚠️ User not authenticated, returning empty unread notifications stream');
      return Stream.value(<AppNotification>[]);
    }

    return _notificationsRef
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToNotification(data);
      }).toList();
    }).handleError((error) {
      print('❌ Error in getUnreadNotifications stream: $error');
    });
  }

  // Get notifications by type
  Stream<List<AppNotification>> getNotificationsByType(NotificationType type) {
    // Check authentication first
    if (!_isAuthenticated) {
      print('⚠️ User not authenticated, returning empty notifications by type stream');
      return Stream.value(<AppNotification>[]);
    }

    return _notificationsRef
        .where('type', isEqualTo: type.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToNotification(data);
      }).toList();
    }).handleError((error) {
      print('❌ Error in getNotificationsByType stream: $error');
    });
  }

  // Create a new notification
  Future<String> createNotification(AppNotification notification) async {
    try {
      // Check authentication first
      if (!_isAuthenticated) {
        print('⚠️ User not authenticated, skipping notification creation');
        return 'not_authenticated';
      }

      final docRef = await _notificationsRef.add(_notificationToMap(notification));
      
      // Update the notification with the generated ID
      await docRef.update({'id': docRef.id});
      
      print('✅ Notification created successfully: ${notification.title}');
      return docRef.id;
    } catch (e) {
      print('❌ Failed to create notification: ${e.toString()}');
      throw NotificationServiceException('Failed to create notification: ${e.toString()}');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (e) {
      throw NotificationServiceException('Failed to mark notification as read: ${e.toString()}');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _notificationsRef
          .where('isRead', isEqualTo: false)
          .get();
      
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      throw NotificationServiceException('Failed to mark all notifications as read: ${e.toString()}');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      throw NotificationServiceException('Failed to delete notification: ${e.toString()}');
    }
  }

  // Delete all read notifications
  Future<void> deleteAllReadNotifications() async {
    try {
      final batch = _firestore.batch();
      final readNotifications = await _notificationsRef
          .where('isRead', isEqualTo: true)
          .get();

      for (final doc in readNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw NotificationServiceException('Failed to delete read notifications: ${e.toString()}');
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final batch = _firestore.batch();
      final allNotifications = await _notificationsRef.get();

      for (final doc in allNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Deleted all notifications (${allNotifications.docs.length} total)');
    } catch (e) {
      throw NotificationServiceException('Failed to delete all notifications: ${e.toString()}');
    }
  }

  // Create inventory alert notification
  Future<String> createInventoryAlert({
    required String itemId,
    required String itemName,
    required String alertType, // 'low_stock', 'critical_stock', 'out_of_stock'
    required int currentStock,
    required int minStock,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
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
    
    final notification = AppNotification.inventoryAlert(
      id: id,
      title: title,
      message: message,
      priority: priority,
      relatedItemId: itemId,
      actionData: {
        'alertType': alertType,
        'currentStock': currentStock,
        'minStock': minStock,
        'navigationTarget': 'inventory_details',
      },
    );
    
    return await createNotification(notification);
  }

  // Create order status update notification
  Future<String> createOrderStatusUpdate({
    required String itemId,
    required String itemName,
    required String oldStatus,
    required String newStatus,
    String? orderId,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
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
        message = 'Order status for $itemName changed from $oldStatus to $newStatus';
        priority = NotificationPriority.low;
        break;
    }
    
    final notification = AppNotification.orderStatusUpdate(
      id: id,
      title: title,
      message: message,
      priority: priority,
      relatedItemId: itemId,
      relatedOrderId: orderId,
      actionData: {
        'oldStatus': oldStatus,
        'newStatus': newStatus,
        'navigationTarget': 'inventory_details',
      },
    );
    
    return await createNotification(notification);
  }

  // Create usage verification alert notification
  Future<String> createUsageVerificationAlert({
    required String usageId,
    required String itemName,
    required String usedBy,
    required double totalCost,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    final notification = AppNotification.usageVerificationAlert(
      id: id,
      title: 'New Usage Record',
      message: '$usedBy used $itemName (RM ${totalCost.toStringAsFixed(2)}) - requires verification',
      priority: NotificationPriority.medium,
      relatedUsageId: usageId,
      actionData: {
        'itemName': itemName,
        'usedBy': usedBy,
        'totalCost': totalCost,
        'navigationTarget': 'usage_management',
      },
    );
    
    return await createNotification(notification);
  }

  // Helper method to map Firestore data to AppNotification
  AppNotification _mapToNotification(Map<String, dynamic> data) {
    return AppNotification(
      id: data['id'] ?? '',
      type: NotificationTypeExtension.fromString(data['type'] ?? 'inventory_alert'),
      priority: NotificationPriorityExtension.fromString(data['priority'] ?? 'medium'),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt']))
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      relatedItemId: data['relatedItemId'],
      relatedUsageId: data['relatedUsageId'],
      relatedOrderId: data['relatedOrderId'],
      actionData: data['actionData'] != null
          ? Map<String, dynamic>.from(data['actionData'])
          : null,
    );
  }

  // Helper method to convert AppNotification to Firestore map
  Map<String, dynamic> _notificationToMap(AppNotification notification) {
    return {
      'id': notification.id,
      'type': notification.type.value,
      'priority': notification.priority.value,
      'title': notification.title,
      'message': notification.message,
      'createdAt': Timestamp.fromDate(notification.createdAt),
      'isRead': notification.isRead,
      'relatedItemId': notification.relatedItemId,
      'relatedUsageId': notification.relatedUsageId,
      'relatedOrderId': notification.relatedOrderId,
      'actionData': notification.actionData,
    };
  }
}
