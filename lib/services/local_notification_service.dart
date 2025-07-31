import 'dart:async';
import '../models/notification.dart';
import 'notification_persistence_service.dart';

/// Temporary local notification service that works without Firestore
/// This demonstrates the notification system functionality while Firestore permissions are being resolved
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _notificationsController =
      StreamController<List<AppNotification>>.broadcast();
  final StreamController<int> _countController = StreamController<int>.broadcast();
  final NotificationPersistenceService _persistenceService = NotificationPersistenceService();

  bool _isInitialized = false;

  // Initialize the local notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔔 Initializing Local Notification Service...');

    // Load persisted notifications
    final persistedNotifications = await _persistenceService.loadNotifications();
    _notifications.clear();
    _notifications.addAll(persistedNotifications);

    // Sort by creation date (newest first)
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _isInitialized = true;
    print('✅ Local Notification Service initialized with ${_notifications.length} persisted notifications');

    // Emit initial data
    _updateStreams();
  }



  // Get all notifications as stream
  Stream<List<AppNotification>> getAllNotifications() {
    if (!_isInitialized) initialize();

    print('🔔 LocalNotificationService: getAllNotifications called, returning ${_notifications.length} notifications');

    // Create a new stream controller for this specific request
    final controller = StreamController<List<AppNotification>>();

    // Immediately emit current data
    controller.add(List.from(_notifications));

    // Listen to updates and forward them
    final subscription = _notificationsController.stream.listen(
      (data) => controller.add(data),
      onError: (error) => controller.addError(error),
    );

    // Clean up when stream is cancelled
    controller.onCancel = () => subscription.cancel();

    return controller.stream;
  }

  // Get unread notifications count
  Stream<int> getUnreadNotificationsCount() {
    if (!_isInitialized) initialize();

    // Calculate current unread count and emit immediately
    final currentUnreadCount = _notifications.where((n) => !n.isRead).length;
    print('🔔 LocalNotificationService: getUnreadNotificationsCount called, returning $currentUnreadCount unread notifications');

    // Create a new stream controller for this specific request
    final controller = StreamController<int>();

    // Immediately emit current count
    controller.add(currentUnreadCount);

    // Listen to updates and forward them
    final subscription = _countController.stream.listen(
      (data) => controller.add(data),
      onError: (error) => controller.addError(error),
    );

    // Clean up when stream is cancelled
    controller.onCancel = () => subscription.cancel();

    return controller.stream;
  }

  // Get unread notifications
  Stream<List<AppNotification>> getUnreadNotifications() {
    if (!_isInitialized) initialize();

    // Get current unread notifications and emit immediately
    final currentUnread = _notifications.where((n) => !n.isRead).toList();
    print('🔔 LocalNotificationService: getUnreadNotifications called, returning ${currentUnread.length} unread notifications');

    // Create a new stream controller for this specific request
    final controller = StreamController<List<AppNotification>>();

    // Immediately emit current unread notifications
    controller.add(currentUnread);

    // Listen to updates and forward filtered data
    final subscription = _notificationsController.stream.listen(
      (notifications) {
        final unread = notifications.where((n) => !n.isRead).toList();
        controller.add(unread);
      },
      onError: (error) => controller.addError(error),
    );

    // Clean up when stream is cancelled
    controller.onCancel = () => subscription.cancel();

    return controller.stream;
  }

  // Get notifications by type
  Stream<List<AppNotification>> getNotificationsByType(NotificationType type) {
    if (!_isInitialized) initialize();

    // Get current notifications of type and emit immediately
    final currentByType = _notifications.where((n) => n.type == type).toList();
    print('🔔 LocalNotificationService: getNotificationsByType called, returning ${currentByType.length} notifications of type ${type.value}');

    // Create a new stream controller for this specific request
    final controller = StreamController<List<AppNotification>>();

    // Immediately emit current notifications of type
    controller.add(currentByType);

    // Listen to updates and forward filtered data
    final subscription = _notificationsController.stream.listen(
      (notifications) {
        final byType = notifications.where((n) => n.type == type).toList();
        controller.add(byType);
      },
      onError: (error) => controller.addError(error),
    );

    // Clean up when stream is cancelled
    controller.onCancel = () => subscription.cancel();

    return controller.stream;
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _persistenceService.saveNotifications(_notifications);
      _updateStreams();
      print('✅ Marked notification as read: $notificationId');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    await _persistenceService.saveNotifications(_notifications);
    _updateStreams();
    print('✅ Marked all notifications as read');
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _persistenceService.saveNotifications(_notifications);
    _updateStreams();
    print('✅ Deleted notification: $notificationId');
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    final count = _notifications.length;
    _notifications.clear();
    await _persistenceService.saveNotifications(_notifications);
    _updateStreams();
    print('✅ Deleted all notifications ($count total)');
  }

  // Add a new notification
  Future<String> addNotification(AppNotification notification) async {
    // Check if notification already exists to prevent duplicates
    final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
    if (existingIndex != -1) {
      print('⚠️ Notification already exists: ${notification.id}');
      return notification.id;
    }

    _notifications.insert(0, notification); // Add at beginning (newest first)
    await _persistenceService.saveNotifications(_notifications);
    _updateStreams();
    print('✅ Added new notification: ${notification.title}');
    return notification.id;
  }





  // Update all streams
  void _updateStreams() {
    _notificationsController.add(List.from(_notifications));
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    _countController.add(unreadCount);
  }

  // Get current notification count for debugging
  int get notificationCount => _notifications.length;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Dispose
  void dispose() {
    _notificationsController.close();
    _countController.close();
    _notifications.clear();
    _isInitialized = false;
    print('🔔 Local Notification Service disposed');
  }
}
