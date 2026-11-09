import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PushService {
  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
        const InitializationSettings(android: androidInit));

    final token = await _messaging.getToken();
    if (token != null) await _saveTokenSafely(token);
    _messaging.onTokenRefresh.listen(_saveTokenSafely);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'motoshield_alerts',
            'MOTOSHIELD Alerts',
            channelDescription: 'Crash and SOS alerts',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  Future<void> _saveTokenSafely(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('riders').doc(uid);
    final snap = await ref.get();

    if (snap.exists) {
      await ref.update({'fcmToken': token});
    } else {
      final user = FirebaseAuth.instance.currentUser;
      await ref.set({
        'name': user?.displayName ?? 'Rider',
        'email': user?.email ?? '',
        'bike': '',
        'plate': '',
        'safetyScore': 100,
        'fcmToken': token,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
