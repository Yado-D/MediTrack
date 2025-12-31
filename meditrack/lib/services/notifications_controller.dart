import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code for notification creation goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code for notification display goes here
    print("Notification Displayed received: ${receivedNotification.id}");
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Check if payload exists
      if (receivedNotification.payload != null) {
        String? userId = receivedNotification.payload!['userId'];
        String? scheduleId = receivedNotification.payload!['scheduleId'];

        if (userId != null && scheduleId != null) {
          // Update Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('medSchedules')
              .doc(scheduleId)
              .update({'is_time_to_take_pill': true});
        }
      }
    } catch (e) {
      print("Error updating Firestore: $e");
    }
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code for notification dismissal goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print("Notification action received: ${receivedAction.id}");

    if (receivedAction.channelKey == 'basic_channel' && Platform.isIOS) {
      AwesomeNotifications().getGlobalBadgeCounter().then(
          (value) => AwesomeNotifications().setGlobalBadgeCounter(value - 1));
    }

    // Navigate to the desired page
    // Since static methods cannot access a BuildContext directly, use a global navigator key
    final navigatorKey = GlobalNavigator.navigatorKey;

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      "/notification_page",
      (route) => route.isFirst,
    );
  }
}

/// A global navigator key to allow navigation from anywhere
class GlobalNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
