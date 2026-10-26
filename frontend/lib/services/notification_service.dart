import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ============================================================
  // MEDICINE NOTIFICATION TAP
  // ============================================================

  // Notification tap pannumbothu exact medicine reminder ID
  // inga store aagum.
  final ValueNotifier<String?> medicineReminderTapNotifier =
      ValueNotifier<String?>(null);

  String? pendingMedicineReminderId;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings settings =
        InitializationSettings(
      android: androidSettings,
    );

    // Notification tap callback
    await notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse:
          _onNotificationTapped,
    );

    final androidPlugin =
        notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    final notificationPermission =
        await androidPlugin
            ?.requestNotificationsPermission();

    final exactAlarmPermission =
        await androidPlugin
            ?.requestExactAlarmsPermission();

    print(
      '========================================',
    );

    print(
      'NOTIFICATION PERMISSION: '
      '$notificationPermission',
    );

    print(
      'EXACT ALARM PERMISSION: '
      '$exactAlarmPermission',
    );

    print(
      '========================================',
    );

    // ==========================================================
    // COLD START NOTIFICATION TAP
    // ==========================================================

    final launchDetails =
        await notificationsPlugin
            .getNotificationAppLaunchDetails();

    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp) {
      final payload =
          launchDetails.notificationResponse?.payload;

      if (payload != null &&
          payload.isNotEmpty) {
        pendingMedicineReminderId = payload;

        print(
          'App opened from notification.',
        );

        print(
          'Pending medicine reminder ID: $payload',
        );
      }
    }

    print(
      'Notification service initialized',
    );
  }

  // ============================================================
  // NOTIFICATION TAP CALLBACK
  // ============================================================

  void _onNotificationTapped(
    NotificationResponse response,
  ) {
    final payload = response.payload;

    if (payload == null || payload.isEmpty) {
      print(
        'Notification tapped without payload.',
      );

      return;
    }

    print(
      '========================================',
    );

    print(
      'NOTIFICATION TAPPED',
    );

    print(
      'Payload: $payload',
    );

    print(
      '========================================',
    );

    // Store exact medicine reminder ID
    pendingMedicineReminderId = payload;

    // Notify the app
    medicineReminderTapNotifier.value = payload;
  }

  // ============================================================
  // CLEAR NOTIFICATION TAP
  // ============================================================

  void clearMedicineNotificationTap() {
    pendingMedicineReminderId = null;
    medicineReminderTapNotifier.value = null;
  }

  // ============================================================
  // GET NOTIFICATION ID
  // ============================================================

  int getNotificationId(String id) {
    return id.codeUnits.fold(
      0,
      (previous, element) =>
          (previous * 31 + element) &
              0x7fffffff,
    );
  }

  // ============================================================
  // MEDICINE REMINDER NOTIFICATION
  // ============================================================

  Future<void> scheduleMedicineNotification({
    required String notificationId,
    required String medicine,
    required String foodTiming,
    required int hour,
    required int minute,
  }) async {
    try {
      final now =
          tz.TZDateTime.now(
        tz.local,
      );

      var scheduledDate =
          tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Today's time already passed
      // -> schedule tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate =
            scheduledDate.add(
          const Duration(days: 1),
        );
      }

      const AndroidNotificationDetails
          androidDetails =
          AndroidNotificationDetails(
        'medicine_reminder_channel',
        'Medicine Reminders',
        channelDescription:
            'Notifications for scheduled medicines',
        importance:
            Importance.max,
        priority:
            Priority.high,
      );

      const NotificationDetails
          notificationDetails =
          NotificationDetails(
        android: androidDetails,
      );

      await notificationsPlugin.zonedSchedule(
        getNotificationId(
          notificationId,
        ),
        'Medicine Reminder',
        'Time to take $medicine - $foodTiming',
        scheduledDate,
        notificationDetails,

        // ======================================================
        // IMPORTANT
        // ======================================================
        // Firestore reminder document ID is stored here.
        // Notification tap pannumbothu
        // exact reminder identify panna use aagum.
        payload: notificationId,

        androidScheduleMode:
            AndroidScheduleMode
                .exactAllowWhileIdle,

        // Every day same time
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
        'Food Timing: $foodTiming',
      );

      print(
        'Time: $scheduledDate',
      );

      print(
        'Reminder ID: $notificationId',
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
  // LOW STOCK NOTIFICATION
  // ============================================================

  Future<void> showLowStockNotification({
    required String medicine,
    required int quantity,
  }) async {
    try {
      const AndroidNotificationDetails
          androidDetails =
          AndroidNotificationDetails(
        'low_stock_channel',
        'Low Medicine Stock',
        channelDescription:
            'Notifications when medicine stock is low',
        importance:
            Importance.max,
        priority:
            Priority.high,
      );

      const NotificationDetails details =
          NotificationDetails(
        android: androidDetails,
      );

      await notificationsPlugin.show(
        getNotificationId(
          'low_stock_$medicine',
        ),
        'Low Medicine Stock',
        '$medicine stock is low. Only $quantity remaining.',
        details,
      );

      print(
        'LOW STOCK NOTIFICATION SENT: '
        '$medicine - $quantity',
      );
    } catch (e) {
      print(
        'LOW STOCK NOTIFICATION ERROR: $e',
      );
    }
  }

  // ============================================================
  // DOCTOR APPOINTMENT NOTIFICATIONS
  // ============================================================

  Future<void> scheduleAppointmentNotifications({
    required String appointmentId,
    required String doctor,
    required String specialization,
    required DateTime appointmentDateTime,
  }) async {
    try {
      final tomorrowNotificationTime =
          appointmentDateTime.subtract(
        const Duration(days: 1),
      );

      final oneHourNotificationTime =
          appointmentDateTime.subtract(
        const Duration(hours: 1),
      );

      const AndroidNotificationDetails
          androidDetails =
          AndroidNotificationDetails(
        'doctor_appointment_channel',
        'Doctor Appointments',
        channelDescription:
            'Notifications for doctor appointments',
        importance:
            Importance.max,
        priority:
            Priority.high,
      );

      const NotificationDetails details =
          NotificationDetails(
        android: androidDetails,
      );

      final now =
          tz.TZDateTime.now(
        tz.local,
      );

      // ========================================================
      // DAY BEFORE
      // ========================================================

      final tomorrowTime =
          tz.TZDateTime(
        tz.local,
        tomorrowNotificationTime.year,
        tomorrowNotificationTime.month,
        tomorrowNotificationTime.day,
        tomorrowNotificationTime.hour,
        tomorrowNotificationTime.minute,
      );

      if (tomorrowTime.isAfter(now)) {
        await notificationsPlugin.zonedSchedule(
          getNotificationId(
            '${appointmentId}_day',
          ),
          'Doctor Appointment Tomorrow',
          'You have an appointment with Dr. $doctor tomorrow.',
          tomorrowTime,
          details,
          androidScheduleMode:
              AndroidScheduleMode
                  .exactAllowWhileIdle,
        );
      }

      // ========================================================
      // ONE HOUR BEFORE
      // ========================================================

      final oneHourTime =
          tz.TZDateTime(
        tz.local,
        oneHourNotificationTime.year,
        oneHourNotificationTime.month,
        oneHourNotificationTime.day,
        oneHourNotificationTime.hour,
        oneHourNotificationTime.minute,
      );

      if (oneHourTime.isAfter(now)) {
        await notificationsPlugin.zonedSchedule(
          getNotificationId(
            '${appointmentId}_hour',
          ),
          'Doctor Appointment Reminder',
          'Your appointment with Dr. $doctor is in 1 hour.',
          oneHourTime,
          details,
          androidScheduleMode:
              AndroidScheduleMode
                  .exactAllowWhileIdle,
        );
      }

      print(
        '========================================',
      );

      print(
        'DOCTOR APPOINTMENT '
        'NOTIFICATIONS SCHEDULED',
      );

      print(
        'Doctor: $doctor',
      );

      print(
        'Specialization: $specialization',
      );

      print(
        'Appointment: $appointmentDateTime',
      );

      print(
        '========================================',
      );
    } catch (e) {
      print(
        'APPOINTMENT NOTIFICATION ERROR: $e',
      );
    }
  }

  // ============================================================
  // CANCEL APPOINTMENT NOTIFICATIONS
  // ============================================================

  Future<void> cancelAppointmentNotifications(
    String appointmentId,
  ) async {
    try {
      await notificationsPlugin.cancel(
        getNotificationId(
          '${appointmentId}_day',
        ),
      );

      await notificationsPlugin.cancel(
        getNotificationId(
          '${appointmentId}_hour',
        ),
      );

      print(
        'Appointment notifications '
        'cancelled: $appointmentId',
      );
    } catch (e) {
      print(
        'Appointment notification '
        'cancel error: $e',
      );
    }
  }

  // ============================================================
  // CANCEL NOTIFICATION
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
  // TEST NOTIFICATION
  // ============================================================

  Future<void> testNotification() async {
    try {
      const AndroidNotificationDetails
          androidDetails =
          AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription:
            'Test notification channel',
        importance:
            Importance.max,
        priority:
            Priority.high,
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