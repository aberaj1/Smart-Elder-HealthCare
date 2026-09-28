import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ============================================================
  // INITIALIZE NOTIFICATIONS
  // ============================================================

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(
      android: androidSettings,
    );

    await notificationsPlugin.initialize(
      settings,
    );

    final androidPlugin =
        notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    final notificationPermission =
        await androidPlugin?.requestNotificationsPermission();

    final exactAlarmPermission =
        await androidPlugin?.requestExactAlarmsPermission();

    print('========================================');
    print(
      'NOTIFICATION PERMISSION: $notificationPermission',
    );
    print(
      'EXACT ALARM PERMISSION: $exactAlarmPermission',
    );
    print('========================================');

    print('Notification service initialized');
  }

  // ============================================================
  // 10 SECOND SCHEDULED TEST
  // ============================================================

  Future<void> testScheduledNotification() async {
    try {
      final now = tz.TZDateTime.now(
        tz.local,
      );

      final scheduledTime =
          now.add(const Duration(seconds: 10));

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'scheduled_test_channel',
        'Scheduled Test',
        channelDescription:
            'Testing scheduled notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails details =
          NotificationDetails(
        android: androidDetails,
      );

      await notificationsPlugin.zonedSchedule(
        888,
        'Scheduled Test',
        'Scheduled notification is working!',
        scheduledTime,
        details,
        androidScheduleMode:
            AndroidScheduleMode.inexactAllowWhileIdle,
      );

      print(
        '========================================',
      );
      print(
        'SCHEDULED TEST FOR: $scheduledTime',
      );
      print(
        '========================================',
      );
    } catch (e) {
      print(
        'SCHEDULED TEST ERROR: $e',
      );
    }
  }

  // ============================================================
  // NOTIFICATION ID
  // ============================================================

  int getNotificationId(String id) {
    return id.codeUnits.fold(
      0,
      (previous, element) =>
          (previous * 31 + element) & 0x7fffffff,
    );
  }

  // ============================================================
  // SCHEDULE MEDICINE NOTIFICATION
  // ============================================================

  Future<void> scheduleMedicineNotification({
    required String notificationId,
    required String medicine,
    required String strength,
    required int hour,
    required int minute,
  }) async {
    try {
      final now = tz.TZDateTime.now(
        tz.local,
      );

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If today's time has already passed,
      // schedule for tomorrow.
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(
          const Duration(days: 1),
        );
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'medicine_reminder_channel',
        'Medicine Reminders',
        channelDescription:
            'Notifications for scheduled medicines',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(
        android: androidDetails,
      );

      await notificationsPlugin.zonedSchedule(
        getNotificationId(notificationId),
        'Medicine Reminder',
        'Time to take $medicine $strength',
        scheduledDate,
        notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
            DateTimeComponents.time,
      );

      print(
        '========================================',
      );

      print(
        'MEDICINE NOTIFICATION SCHEDULED',
      );

      print(
        'Medicine: $medicine',
      );

      print(
        'Strength: $strength',
      );

      print(
        'Time: $scheduledDate',
      );

      print(
        '========================================',
      );
    } catch (e) {
      print(
        'MEDICINE NOTIFICATION ERROR: $e',
      );
    }
  }

  // ============================================================
  // CANCEL MEDICINE NOTIFICATION
  // ============================================================

  Future<void> cancelNotification(
    String id,
  ) async {
    try {
      await notificationsPlugin.cancel(
        getNotificationId(id),
      );

      print(
        'Notification cancelled: $id',
      );
    } catch (e) {
      print(
        'Notification cancel error: $e',
      );
    }
  }

  // ============================================================
  // IMMEDIATE TEST NOTIFICATION
  // ============================================================

  Future<void> testNotification() async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription:
            'Test notification channel',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails details =
          NotificationDetails(
        android: androidDetails,
      );

      await notificationsPlugin.show(
        999,
        'Test Notification',
        'Notification system is working!',
        details,
      );

      print(
        'TEST NOTIFICATION SENT',
      );
    } catch (e) {
      print(
        'TEST NOTIFICATION ERROR: $e',
      );
    }
  }
}