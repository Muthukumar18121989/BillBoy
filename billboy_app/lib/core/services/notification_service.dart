import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../constants/app_constants.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> scheduleWarrantyReminder({
    required int id,
    required String productName,
    required DateTime warrantyEndDate,
  }) async {
    for (final days in AppConstants.warrantyReminderDays) {
      final reminderDate = warrantyEndDate.subtract(Duration(days: days));
      if (reminderDate.isAfter(DateTime.now())) {
        await _plugin.zonedSchedule(
          id * 100 + days,
          'Warranty Reminder',
          'Your $productName warranty expires in $days day${days == 1 ? '' : 's'}.',
          tz.TZDateTime.from(reminderDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'warranty_channel',
              'Warranty Reminders',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> cancelWarrantyReminders(int billId) async {
    for (final days in AppConstants.warrantyReminderDays) {
      await _plugin.cancel(billId.hashCode * 100 + days);
    }
  }

  Future<void> showInstant({required String title, required String body}) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general_channel',
          'General Notifications',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
