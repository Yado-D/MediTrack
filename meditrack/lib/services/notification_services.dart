import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import '../common_modules/notification_model.dart';
import '../utils/notifications_utils.dart';

class NotificationService {
  // 1. Instant Notification
  static Future<void> createNotification(GeneralNotificationModel noObj) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: createUniqueId(),
        channelKey: 'Basic_channel',
        title: 'MediTrack: ${noObj.msgTitle}',
        body: noObj.msgBody,
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
      ),
    );
  }

  // 2. Scheduled Notification with Medicine ID tracking
  static Future<void> createScheduledNotification({
    required int medicineId, // Pass the unique ID of the medicine from your DB
    required GeneralNotificationModel noObj,
    required List<int> daysToRepeat,
    required TimeOfDay time,
  }) async {
    String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();

    for (int day in daysToRepeat) {
      // Logic: MedicineID + Day (e.g., Medicine 10 on Monday (1) = ID 101)
      // This allows us to target specific pills later.
      int notificationId = int.parse("$medicineId$day");

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'schedule_channel',
          title: '💊 Time for ${noObj.msgTitle}!',
          body: noObj.msgBody ?? "Take your prescribed dose now.",
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.Default,
          // This makes the notification stick until "Mark Taken" is pressed
          fullScreenIntent: true,
          criticalAlert: true,
          wakeUpScreen: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: "MARK_DONE",
            label: "Mark Taken",
            actionType: ActionType.Default,
            color: Colors.green,
          ),
        ],
        schedule: NotificationCalendar(
          weekday: day,
          hour: time.hour,
          minute: time.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          timeZone: localTimeZone,
          preciseAlarm: true,
        ),
      );
    }
  }

  // 3. Cancel ONLY reminders for a specific medicine
  static Future<void> cancelMedicineReminders(int medicineId) async {
    // Loop through all 7 possible days to ensure all are cleared
    for (int day = 1; day <= 7; day++) {
      int idToCancel = int.parse("$medicineId$day");
      await AwesomeNotifications().cancel(idToCancel);
    }
  }

  // 4. Global Cancel (Keep as fallback)
  static Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAllSchedules();
  }
}
