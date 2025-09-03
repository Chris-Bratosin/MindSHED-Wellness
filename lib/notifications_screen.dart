import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'shared_ui_components.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool muteNotifications = false;
  bool muteSounds = false;

  // EXISTING notifications list (logic unchanged)
  final List<Map<String, String>> notifications = [];

  // ---- UI-only state for the reminder rows (does not change your scheduling logic)
  final Map<String, bool> _reminderOn = {
    'Hydration Reminder': false,
    'Sleep Reminder': false,
    'Eating Reminder': false,
    'Exercise Reminder': false,
  };
  final Map<String, TimeOfDay?> _reminderTime = {
    'Hydration Reminder': null,
    'Sleep Reminder': null,
    'Eating Reminder': null,
    'Exercise Reminder': null,
  };

  // Palette for the mock
  static const cream = Color(0xFFFFF9DA);
  static const mint = Color(0xFFB6FFB1);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ---------------- EXISTING LOGIC (unchanged) ----------------
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
  // ------------------------------------------------------------

  // UI-only: show a time picker dialog and store the choice locally
  Future<void> _pickReminderTime(String label) async {
    final initial = _reminderTime[label] ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'When would you like to be reminded?',
      confirmText: 'Confirm',
    );
    if (!mounted) return;

    if (picked == null) {
      // user cancelled: turn the toggle back off
      setState(() {
        _reminderOn[label] = false;
      });
      return;
    }

    setState(() {
      _reminderTime[label] = picked;
    });

    // purely UI feedback; does not change your scheduling logic
    final t = picked.format(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label set for $t'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color;
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 18;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              SharedUIComponents.buildHeaderPill(
                'Notifications',
                fontSize: fontSize + 4,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Notification log button
                      SharedUIComponents.buildMintActionButton(
                        icon: Icons.history,
                        label: 'View Notification Log',
                        onTap: () =>
                            _showNotificationLog(context, fontSize, textColor),
                        fontSize: fontSize,
                      ),

                      const SizedBox(height: 10),

                      // Reminders section
                      _remindersCard(fontSize, textColor),

                      const SizedBox(height: 10),

                      // Bottom settings block (UNCHANGED logic/UI from your code)
                      _buildSettingsSection(fontSize),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              _backButton(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton() => Center(
    child: Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFB6FFB1),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Back',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),
    ),
  );

  // --------- UI building blocks (mockup styling) ---------

  Widget _remindersCard(double fontSize, Color? textColor) {
    return SharedUIComponents.buildCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Reminders header
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.black, size: 24),
              const SizedBox(width: 12),
              Text(
                'Daily Reminders',
                style: TextStyle(
                  fontFamily: 'HappyMonkey',
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Reminder items
          _buildCleanReminderRow(
            icon: Icons.water_drop,
            label: 'Hydration Reminder',
            subtitle: 'Stay hydrated throughout the day',
            fontSize: fontSize,
            textColor: textColor,
          ),
          const SizedBox(height: 12),

          _buildCleanReminderRow(
            icon: Icons.bedtime,
            label: 'Sleep Reminder',
            subtitle: 'Get your beauty sleep',
            fontSize: fontSize,
            textColor: textColor,
          ),
          const SizedBox(height: 12),

          _buildCleanReminderRow(
            icon: Icons.restaurant,
            label: 'Eating Reminder',
            subtitle: 'Don\'t skip your meals',
            fontSize: fontSize,
            textColor: textColor,
          ),
          const SizedBox(height: 12),

          _buildCleanReminderRow(
            icon: Icons.fitness_center,
            label: 'Exercise Reminder',
            subtitle: 'Time to move your body',
            fontSize: fontSize,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCleanReminderRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required double fontSize,
    required Color? textColor,
  }) {
    final enabled = _reminderOn[label] ?? false;
    final time = _reminderTime[label];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFB6FFB1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: enabled ? Colors.black : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time == null
                      ? subtitle
                      : '$subtitle • ${time.format(context)}',
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (val) async {
              setState(() => _reminderOn[label] = val);
              if (val) {
                await _pickReminderTime(label);
              } else {
                setState(() => _reminderTime[label] = null);
              }
            },
            activeThumbColor: const Color(0xFFB6FFB1),
            activeTrackColor: const Color(0xFFB6FFB1).withOpacity(0.3),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _reminderRow(String label, double fontSize, Color? textColor) {
    final enabled = _reminderOn[label] ?? false;
    final time = _reminderTime[label];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFFB6FFB1),
        border: Border.all(color: Colors.black, width: 1.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              time == null ? label : '$label  •  ${time.format(context)}',
              style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: fontSize - 1,
                color: textColor,
              ),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (val) async {
              setState(() => _reminderOn[label] = val);
              if (val) {
                await _pickReminderTime(label);
              } else {
                setState(() => _reminderTime[label] = null);
              }
            },
            activeThumbColor: Colors.black,
            inactiveThumbColor: Colors.black,
            inactiveTrackColor: Colors.black26,
          ),
        ],
      ),
    );
  }

  // --------- your existing empty state & settings section (unchanged) ---------

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
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(double fontSize) {
    return SharedUIComponents.buildCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Settings header
          Row(
            children: [
              Icon(Icons.settings, color: Colors.black, size: 24),
              const SizedBox(width: 12),
              Text(
                'Notification Settings',
                style: TextStyle(
                  fontFamily: 'HappyMonkey',
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Toggle options with better styling
          _buildCleanToggleRow(
            icon: Icons.notifications,
            label: 'Daily Notifications',
            subtitle: 'Receive daily wellness reminders',
            value: !muteNotifications,
            onChanged: (val) async {
              setState(() => muteNotifications = !val);
              await _handleNotificationToggle(!val);
            },
          ),
          const SizedBox(height: 16),

          _buildCleanToggleRow(
            icon: Icons.volume_up,
            label: 'Sound Alerts',
            subtitle: 'Play sounds for notifications',
            value: !muteSounds,
            onChanged: (val) async {
              setState(() => muteSounds = !val);
              await _handleSoundToggle(!val);
            },
          ),
          const SizedBox(height: 24),

          // Customize button with better styling
          SharedUIComponents.buildMintActionButton(
            icon: Icons.tune,
            label: 'Customize Sounds',
            onTap: () => _showSoundCustomization(context, fontSize),
            fontSize: fontSize,
          ),
        ],
      ),
    );
  }

  Widget _buildCleanToggleRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? const Color(0xFFB6FFB1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? Colors.black : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFB6FFB1),
            activeTrackColor: const Color(0xFFB6FFB1).withOpacity(0.3),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade300,
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
          activeThumbColor: Theme.of(context).brightness == Brightness.dark
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

  void _showNotificationLog(
    BuildContext context,
    double fontSize,
    Color? textColor,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.black, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Notification Log',
                      style: TextStyle(
                        fontFamily: 'HappyMonkey',
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (notifications.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontFamily: 'HappyMonkey',
                            fontSize: fontSize,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notification_important,
                                    color: Colors.orange.shade600,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      notif['title'] ?? '',
                                      style: TextStyle(
                                        fontFamily: 'HappyMonkey',
                                        fontSize: fontSize - 1,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notif['description'] ?? '',
                                style: TextStyle(
                                  fontFamily: 'HappyMonkey',
                                  fontSize: fontSize - 3,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: SharedUIComponents.buildMintButton(
                    label: 'Close',
                    onTap: () => Navigator.pop(context),
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                  'Notification Sounds',
                  false,
                  fontSize,
                ),
                const SizedBox(height: 8),
                _buildNotificationToggle('Ambient Audio', true, fontSize),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mint,
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
    String label,
    bool initialValue,
    double fontSize,
  ) {
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
            // Placeholder logic for now (UI only)
          },
          activeThumbColor: mint,
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade300,
        ),
      ],
    );
  }
}
