import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import 'transition_helper.dart';
import 'notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool muteNotifications = false;
  bool muteSounds = false;

  final List<Map<String, String>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      muteNotifications = prefs.getBool('muteNotifications') ?? false;
      muteSounds = prefs.getBool('muteSounds') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _handleNotificationToggle(bool val) async {
    muteNotifications = val;
    await _saveSetting('muteNotifications', val);
    if (val) {
      await flutterLocalNotificationsPlugin.cancel(0);
    } else {
      await _scheduleDailyReminder();
    }
  }

  Future<void> _handleSoundToggle(bool val) async {
    muteSounds = val;
    await _saveSetting('muteSounds', val);
    if (!muteNotifications) {
      await _scheduleDailyReminder(); // reschedule with new sound setting
    }
  }

  Future<void> _scheduleDailyReminder() async {
    final androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminder',
      channelDescription: 'Reminder to open the app',
      importance: Importance.high,
      priority: Priority.high,
      playSound: !muteSounds,
      enableVibration: !muteSounds,
    );

    final details = NotificationDetails(android: androidDetails);

    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 9, 0);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Daily Check-In',
      'Don’t forget to check in today!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color;
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 18;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: fontSize + 6,
            color: textColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'HappyMonkey',
                          fontSize: fontSize,
                          color: textColor?.withOpacity(0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif['title']!,
                                style: TextStyle(
                                  fontFamily: 'HappyMonkey',
                                  fontSize: fontSize,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif['description']!,
                                style: TextStyle(
                                  fontFamily: 'HappyMonkey',
                                  fontSize: fontSize - 2,
                                  color: textColor?.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            _buildToggleSection(theme, textColor, fontSize),
            const SizedBox(height: 20),
            _buildBackButton(fontSize),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSection(ThemeData theme, Color? textColor, double fontSize) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildToggleRow(
            label: 'Mute Notifications',
            value: muteNotifications,
            textColor: textColor,
            fontSize: fontSize,
            onChanged: (val) async {
              setState(() => muteNotifications = val);
              await _handleNotificationToggle(val);
            },
          ),
          const SizedBox(height: 10),
          _buildToggleRow(
            label: 'Mute Sounds',
            value: muteSounds,
            textColor: textColor,
            fontSize: fontSize,
            onChanged: (val) async {
              setState(() => muteSounds = val);
              await _handleSoundToggle(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required Color? textColor,
    required double fontSize,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: fontSize,
            color: textColor,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          inactiveThumbColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade400
              : Colors.black,
          inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.black26,
        ),
      ],
    );
  }

  Widget _buildBackButton(double fontSize) {
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          createFadeRoute(const SettingsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF40D404)
              : const Color(0xFFB6FFB1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          'Back',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: fontSize,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}