import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;

final FlutterLocalNotificationsPlugin localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const int maghribNotificationId = 1001;

enum AppLanguage { english, bangla }

final ValueNotifier<AppLanguage> appLanguageNotifier =
    ValueNotifier<AppLanguage>(AppLanguage.english);
final ValueNotifier<bool> maghribAlertEnabledNotifier = ValueNotifier<bool>(
  true,
);

Future<void> initializeNotifications() async {
  tz_data.initializeTimeZones();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();

  await localNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  await localNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();
  await localNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >()
      ?.requestPermissions(alert: true, badge: true, sound: true);
}
