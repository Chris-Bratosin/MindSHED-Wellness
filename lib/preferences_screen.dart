import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'settings_screen.dart';
import 'transition_helper.dart';
import 'main.dart'; // to access themeNotifier

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool isDarkTheme = false;
  bool showQuotes = true;
  String fontSize = 'Normal';

  @override
  void initState() {
    super.initState();
    final prefs = Hive.box('prefs');
    isDarkTheme = prefs.get('darkMode', defaultValue: false);
    fontSize = prefs.get('fontSize', defaultValue: 'Normal');
  }

  @override
  Widget build(BuildContext context) {
    final currentFontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Preferences',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: currentFontSize + 6,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSwitchTile(
              title: 'Dark Theme',
              value: isDarkTheme,
              onChanged: (val) async {
                setState(() {
                  isDarkTheme = val;
                });
                final prefs = Hive.box('prefs');
                await prefs.put('darkMode', val);
                themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
              },
            ),
            const SizedBox(height: 20),
            _buildFontSizeSelector(currentFontSize),
            const Spacer(),
            _buildBackButton(currentFontSize),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final currentFontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: currentFontSize,
              color: Theme.of(context).textTheme.bodyMedium?.color,
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
      ),
    );
  }

  Widget _buildFontSizeSelector(double currentFontSize) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Font Size',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: currentFontSize,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Small', 'Normal', 'Large'].map((size) {
              bool isSelected = fontSize == size;
              return InkWell(
                onTap: () async {
                  setState(() {
                    fontSize = size;
                  });
                  final prefs = Hive.box('prefs');
                  await prefs.put('fontSize', size);
                  fontSizeNotifier.value = size;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF40D404)
                            : const Color(0xFFB6FFB1))
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Text(
                    size,
                    style: TextStyle(
                      fontFamily: 'HappyMonkey',
                      fontSize: currentFontSize,
                      color: isSelected && Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(double currentFontSize) {
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
            fontSize: currentFontSize,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
