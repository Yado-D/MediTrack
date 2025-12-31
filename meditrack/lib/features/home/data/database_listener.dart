import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/common_modules/notification_model.dart';
import 'package:meditrack/services/notification_services.dart';

class DatabaseListener {
  // Track which med schedule IDs we are already listening to
  static final Set<String> _listeningIds = <String>{};
  static final Map<String, StreamSubscription> _subscriptions = {};

  // Fetch all med schedule docs for the user and start a listener per document.
  static Future<void> startListeningForUser(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('medSchedules')
          .get();

      for (final doc in snapshot.docs) {
        _startListeningToDoc(userId, doc.id);
      }
    } catch (e) {
      print('ERROR fetching medSchedules for user $userId: $e');
    }
  }

  static void _startListeningToDoc(String userId, String medScheduleId) {
    if (_listeningIds.contains(medScheduleId)) return;
    _listeningIds.add(medScheduleId);

    print('STARTED LISTENING TO FIREBASE for $medScheduleId...');

    final sub = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('medSchedules')
        .doc(medScheduleId)
        .snapshots()
        .listen((documentSnapshot) async {
      if (documentSnapshot.exists) {
        final Map<String, dynamic>? data =
            documentSnapshot.data() as Map<String, dynamic>?;

        if (data != null && data['device_triggered'] == true) {
          print(
              'CONDITION MET on $medScheduleId: device_triggered is TRUE. Sending notification...');

          final int notifId = medScheduleId.hashCode & 0x7fffffff;

          await NotificationService.createNotification(
            GeneralNotificationModel(
                msgTitle: "Time to take your pill",
                msgBody: "The machine is ready. Press the button.",
                date: DateTime.now()),
            payload: {
              'userId': userId,
              'scheduleId': medScheduleId,
            },
          );

          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('medSchedules')
                .doc(medScheduleId)
                .update({'device_triggered': false});
            print(
                'RESET: device_triggered for $medScheduleId set back to false.');
          } catch (e) {
            print('ERROR resetting device_triggered for $medScheduleId: $e');
          }
        }
      }
    }, onError: (error) {
      print('LISTEN ERROR for $medScheduleId: $error');
    });

    _subscriptions[medScheduleId] = sub;
  }

  // Optional: call this when you want to stop all listeners (not used by default)
  static Future<void> stopAllListeners() async {
    for (final sub in _subscriptions.values) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _listeningIds.clear();
  }
}
