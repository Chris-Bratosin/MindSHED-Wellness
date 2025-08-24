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
                  ? _buildEmptyNotificationsState(fontSize)
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
            _buildSettingsSection(fontSize),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotificationsState(double fontSize) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: fontSize + 1,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Set up your daily reminders and custom sounds in settings.',
            style: TextStyle(
              fontSize: fontSize - 1,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(double fontSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildToggleRow(
            label: 'Mute Notifications',
            value: muteNotifications,
            textColor: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: fontSize,
            onChanged: (val) async {
              setState(() => muteNotifications = val);
              await _handleNotificationToggle(val);
            },
          ),
          const SizedBox(height: 20),
          _buildToggleRow(
            label: 'Mute Sounds',
            value: muteSounds,
            textColor: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: fontSize,
            onChanged: (val) async {
              setState(() => muteSounds = val);
              await _handleSoundToggle(val);
            },
          ),
          const SizedBox(height: 24),
          // Customize button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showSoundCustomization(context, fontSize),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Customize Sounds',
                style: TextStyle(
                  fontFamily: 'HappyMonkey',
                  fontSize: fontSize - 1,
                ),
              ),
            ),
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

  void _showSoundCustomization(BuildContext context, double fontSize) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Customize Sounds',
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 20),
                _buildNotificationToggle('App Sounds', true, fontSize),
                const SizedBox(height: 8),
                _buildNotificationToggle(
                    'Notification Sounds', false, fontSize),
                const SizedBox(height: 8),
                _buildNotificationToggle('Ambient Audio', true, fontSize),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB6FFB1),
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: 'HappyMonkey',
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationToggle(
      String label, bool initialValue, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: fontSize,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Switch(
          value: initialValue,
          onChanged: (value) {
            // Placeholder logic for now
          },
          activeColor: const Color(0xFFB6FFB1),
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade300,
        ),
      ],
    );
  }
}
