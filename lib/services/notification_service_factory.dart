import '../models/notification.dart';
import 'notification_service.dart';
import 'local_notification_service.dart';

/// Factory class that provides the appropriate notification service
/// Uses local service as fallback when Firestore has permission issues
class NotificationServiceFactory {
  static final NotificationServiceFactory _instance = NotificationServiceFactory._internal();
  factory NotificationServiceFactory() => _instance;
  NotificationServiceFactory._internal();

  static const bool _useLocalService = true; // Set to true to use local service for demo

  // Get the appropriate notification service
  static INotificationService getService() {
    if (_useLocalService) {
      print('🔔 Using Local Notification Service (demo mode)');
      return LocalNotificationServiceAdapter();
    } else {
      print('🔔 Using Firestore Notification Service');
      return FirestoreNotificationServiceAdapter();
    }
  }
}

/// Interface for notification services
abstract class INotificationService {
  Stream<List<AppNotification>> getAllNotifications();
  Stream<int> getUnreadNotificationsCount();
  Stream<List<AppNotification>> getUnreadNotifications();
  Stream<List<AppNotification>> getNotificationsByType(NotificationType type);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  Future<void> deleteAllNotifications();
}

/// Adapter for the local notification service
class LocalNotificationServiceAdapter implements INotificationService {
  final LocalNotificationService _service = LocalNotificationService();

  @override
  Stream<List<AppNotification>> getAllNotifications() {
    return _service.getAllNotifications();
  }

  @override
  Stream<int> getUnreadNotificationsCount() {
    return _service.getUnreadNotificationsCount();
  }

  @override
  Stream<List<AppNotification>> getUnreadNotifications() {
    return _service.getUnreadNotifications();
  }

  @override
  Stream<List<AppNotification>> getNotificationsByType(NotificationType type) {
    return _service.getNotificationsByType(type);
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _service.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead() {
    return _service.markAllAsRead();
  }

  @override
  Future<void> deleteNotification(String notificationId) {
    return _service.deleteNotification(notificationId);
  }

  @override
  Future<void> deleteAllNotifications() {
    return _service.deleteAllNotifications();
  }
}

/// Adapter for the Firestore notification service
class FirestoreNotificationServiceAdapter implements INotificationService {
  final NotificationService _service = NotificationService();

  @override
  Stream<List<AppNotification>> getAllNotifications() {
    return _service.getAllNotifications();
  }

  @override
  Stream<int> getUnreadNotificationsCount() {
    return _service.getUnreadNotificationsCount();
  }

  @override
  Stream<List<AppNotification>> getUnreadNotifications() {
    return _service.getUnreadNotifications();
  }

  @override
  Stream<List<AppNotification>> getNotificationsByType(NotificationType type) {
    return _service.getNotificationsByType(type);
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _service.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead() {
    return _service.markAllAsRead();
  }

  @override
  Future<void> deleteNotification(String notificationId) {
    return _service.deleteNotification(notificationId);
  }

  @override
  Future<void> deleteAllNotifications() {
    return _service.deleteAllNotifications();
  }
}
