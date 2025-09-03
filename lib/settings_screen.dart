import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'activities_screen.dart';
import 'profile_screen.dart';
import 'insights_screen.dart';
import 'notifications_screen.dart';
import 'preferences_screen.dart';
import 'transition_helper.dart';
import 'package:hive/hive.dart';
import 'shared_navigation.dart';
import 'shared_ui_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0; // gear icon

  // mockup palette
  static const cream = SharedUIComponents.cream;
  static const mint = SharedUIComponents.mint;

  static const String _appVersion = '1.1';

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              SharedUIComponents.buildHeaderPill(
                'Settings',
                fontSize: (fontSize ?? 18) + 4,
              ),
              const SizedBox(height: 32),
              // Centered content container
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      // Settings options
                      SharedUIComponents.buildCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            SharedUIComponents.buildMintActionButton(
                              icon: Icons.notifications,
                              label: 'Notifications',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  createFadeRoute(const NotificationsScreen()),
                                );
                              },
                              fontSize: fontSize,
                            ),
                            const SizedBox(height: 16),
                            SharedUIComponents.buildMintActionButton(
                              icon: Icons.tune,
                              label: 'Preferences',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  createFadeRoute(const PreferencesScreen()),
                                );
                              },
                              fontSize: fontSize,
                            ),
                            const SizedBox(height: 16),
                            SharedUIComponents.buildMintActionButton(
                              icon: Icons.info_outline,
                              label: 'App Info',
                              onTap: _showVersionOverlay,
                              fontSize: fontSize,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Logout button
                      _buildLogoutButton(fontSize),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // keep your names, just new look
      bottomNavigationBar: SharedNavigation.buildBottomNavigation(
        selectedIndex: _selectedIndex,
        context: context,
      ),
    );
  }

  Widget _buildLogoutButton(double? fontSize) {
    final softRed = const Color(0xFFF8B2B2);
    return Container(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showLogoutConfirmation(fontSize),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: softRed,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(double? fontSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: fontSize,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: fontSize,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: fontSize,
                color: Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final sessionBox = await Hive.openBox('session');
              await sessionBox.clear();
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                createFadeRoute(const LoginScreen()),
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: fontSize,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------- App version overlay (tap anywhere to dismiss) --------
  void _showVersionOverlay() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'App Info',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque, // tap anywhere to close
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'App Version $_appVersion',
                style: const TextStyle(
                  fontFamily: 'HappyMonkey',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
