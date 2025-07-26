import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/vehicle.dart';

class MaintenanceNotificationService {
  static final MaintenanceNotificationService _instance = MaintenanceNotificationService._internal();
  factory MaintenanceNotificationService() => _instance;
  MaintenanceNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request notification permissions
    await _requestNotificationPermissions();

    // Initialize the plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _isInitialized = true;
  }

  Future<void> _requestNotificationPermissions() async {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      // Handle permission denied
      print('Notification permission denied');
    }
  }

  Future<void> _createNotificationChannels() async {
    // Service reminder channel
    const AndroidNotificationChannel serviceReminderChannel =
        AndroidNotificationChannel(
      'service_reminders',
      'Service Reminders',
      description: 'Notifications for vehicle service reminders',
      importance: Importance.high,
      playSound: true,
    );

    // Maintenance alert channel
    const AndroidNotificationChannel maintenanceAlertChannel =
        AndroidNotificationChannel(
      'maintenance_alerts',
      'Maintenance Alerts',
      description: 'Urgent maintenance alerts for vehicles',
      importance: Importance.max,
      playSound: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(serviceReminderChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(maintenanceAlertChannel);
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    final payload = notificationResponse.payload;
    if (payload != null) {
      // Parse payload and navigate to appropriate screen
      print('Notification tapped with payload: $payload');
    }
  }

  // Schedule service reminder for a vehicle
  Future<void> scheduleServiceReminder(Vehicle vehicle) async {
    if (!_isInitialized) await initialize();

    final notificationId = vehicle.id.hashCode;
    final scheduledDate = _calculateNextServiceDate(vehicle);

    if (scheduledDate.isBefore(DateTime.now())) {
      // Service is already overdue, show immediate notification
      await showServiceOverdueNotification(vehicle);
      return;
    }

    // Schedule notification for 7 days before service due date
    final reminderDate = scheduledDate.subtract(const Duration(days: 7));

    if (reminderDate.isAfter(DateTime.now())) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Service Reminder',
        '${vehicle.displayName} is due for service in 7 days',
        _convertToTZDateTime(reminderDate),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'service_reminders',
            'Service Reminders',
            channelDescription: 'Notifications for vehicle service reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'service_reminder:${vehicle.id}',
      );
    }

    // Schedule notification for service due date
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId + 1,
      'Service Due Today',
      '${vehicle.displayName} service is due today!',
      _convertToTZDateTime(scheduledDate),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maintenance_alerts',
          'Maintenance Alerts',
          channelDescription: 'Urgent maintenance alerts for vehicles',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFE91E63),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'service_due:${vehicle.id}',
    );
  }

  // Show immediate notification for overdue service
  Future<void> showServiceOverdueNotification(Vehicle vehicle) async {
    if (!_isInitialized) await initialize();

    final daysSinceService = vehicle.lastServiceDate != null
        ? DateTime.now().difference(vehicle.lastServiceDate!).inDays
        : 365; // Default to 1 year if no service date

    await _flutterLocalNotificationsPlugin.show(
      vehicle.id.hashCode + 1000,
      'Service Overdue!',
      '${vehicle.displayName} is $daysSinceService days overdue for service',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maintenance_alerts',
          'Maintenance Alerts',
          channelDescription: 'Urgent maintenance alerts for vehicles',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFE91E63),
          ongoing: true, // Make it persistent
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'service_overdue:${vehicle.id}',
    );
  }

  // Schedule mileage-based maintenance reminder
  Future<void> scheduleMileageReminder(Vehicle vehicle, int targetMileage) async {
    if (!_isInitialized) await initialize();

    final currentMileage = vehicle.mileage;
    final mileageUntilService = targetMileage - currentMileage;

    if (mileageUntilService <= 0) {
      // Already reached target mileage
      await showMileageMaintenanceNotification(vehicle, targetMileage);
      return;
    }

    // Estimate when vehicle will reach target mileage (assuming 1000 miles per month)
    final monthsUntilService = (mileageUntilService / 1000).ceil();
    final estimatedDate = DateTime.now().add(Duration(days: monthsUntilService * 30));

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      vehicle.id.hashCode + 2000,
      'Mileage Maintenance Due',
      '${vehicle.displayName} has reached $targetMileage miles - maintenance required',
      _convertToTZDateTime(estimatedDate),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maintenance_alerts',
          'Maintenance Alerts',
          channelDescription: 'Urgent maintenance alerts for vehicles',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'mileage_maintenance:${vehicle.id}:$targetMileage',
    );
  }

  // Show mileage-based maintenance notification
  Future<void> showMileageMaintenanceNotification(Vehicle vehicle, int targetMileage) async {
    if (!_isInitialized) await initialize();

    await _flutterLocalNotificationsPlugin.show(
      vehicle.id.hashCode + 2000,
      'Mileage Maintenance Required',
      '${vehicle.displayName} has reached $targetMileage miles',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maintenance_alerts',
          'Maintenance Alerts',
          channelDescription: 'Urgent maintenance alerts for vehicles',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'mileage_maintenance:${vehicle.id}:$targetMileage',
    );
  }

  // Cancel all notifications for a vehicle
  Future<void> cancelVehicleNotifications(String vehicleId) async {
    final notificationId = vehicleId.hashCode;
    
    await _flutterLocalNotificationsPlugin.cancel(notificationId); // Service reminder
    await _flutterLocalNotificationsPlugin.cancel(notificationId + 1); // Service due
    await _flutterLocalNotificationsPlugin.cancel(notificationId + 1000); // Service overdue
    await _flutterLocalNotificationsPlugin.cancel(notificationId + 2000); // Mileage maintenance
  }

  // Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Check and schedule notifications for all vehicles
  Future<void> scheduleNotificationsForAllVehicles(List<Vehicle> vehicles) async {
    for (final vehicle in vehicles) {
      await scheduleServiceReminder(vehicle);
      
      // Schedule mileage-based reminders at common intervals
      final currentMileage = vehicle.mileage;
      final nextMileageInterval = ((currentMileage / 10000).ceil() + 1) * 10000;
      
      if (nextMileageInterval > currentMileage) {
        await scheduleMileageReminder(vehicle, nextMileageInterval);
      }
    }
  }

  // Helper method to calculate next service date
  DateTime _calculateNextServiceDate(Vehicle vehicle) {
    if (vehicle.lastServiceDate == null) {
      // If no service date, assume service is needed now
      return DateTime.now();
    }
    
    // Service needed every 90 days (3 months)
    return vehicle.lastServiceDate!.add(const Duration(days: 90));
  }

  // Helper method to convert DateTime to TZDateTime
  dynamic _convertToTZDateTime(DateTime dateTime) {
    // For simplicity, using the system timezone
    // In a real app, you might want to use the timezone package
    return dateTime;
  }

  // Show daily summary of vehicles needing attention
  Future<void> showDailySummaryNotification(List<Vehicle> vehiclesNeedingAttention) async {
    if (!_isInitialized) await initialize();
    
    if (vehiclesNeedingAttention.isEmpty) return;

    final count = vehiclesNeedingAttention.length;
    final title = count == 1 ? '1 Vehicle Needs Attention' : '$count Vehicles Need Attention';
    final body = vehiclesNeedingAttention.length == 1
        ? '${vehiclesNeedingAttention.first.displayName} needs service'
        : 'Multiple vehicles require maintenance or service';

    await _flutterLocalNotificationsPlugin.show(
      9999, // Fixed ID for daily summary
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maintenance_alerts',
          'Maintenance Alerts',
          channelDescription: 'Urgent maintenance alerts for vehicles',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'daily_summary',
    );
  }
}
