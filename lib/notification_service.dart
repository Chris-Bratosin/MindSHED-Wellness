import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iOSSettings = DarwinInitializationSettings(); // iOS fix

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings, // include iOS init settings
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  static Future<void> scheduleDailyReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final muteNotifications = prefs.getBool('muteNotifications') ?? false;
    final muteSounds = prefs.getBool('muteSounds') ?? false;

    if (muteNotifications) {
      await flutterLocalNotificationsPlugin.cancel(0);
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminder',
      channelDescription: 'Reminder to open the app',
      importance: Importance.max,
      priority: Priority.high,
      playSound: !muteSounds,
      enableVibration: !muteSounds,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    final now = tz.TZDateTime.now(tz.local);
    final targetTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9); // 9AM

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Daily Check-In',
      'Don’t forget to check in today!',
      targetTime.isBefore(now) ? targetTime.add(Duration(days: 1)) : targetTime,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}