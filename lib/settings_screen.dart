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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0; // gear icon

  // mockup palette
  static const cream = Color(0xFFFFF9DA);
  static const mint  = Color(0xFFB6FFB1);

  static const String _appVersion = '1.1';

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: _headerPill('Settings', (fontSize ?? 18) + 6),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              // --- three mint buttons as in mockup ---
              _mintActionButton(
                icon: Icons.notifications,
                label: 'Notifications',
                onTap: () {
                  Navigator.push(context, createFadeRoute(const NotificationsScreen()));
                },
                fontSize: fontSize,
              ),
              const SizedBox(height: 14),
              _mintActionButton(
                icon: Icons.tune,
                label: 'Preferences',
                // as requested: send to Notifications page
                onTap: () {
                  Navigator.push(context, createFadeRoute(const PreferencesScreen()));
                },
                fontSize: fontSize,
              ),
              const SizedBox(height: 14),
              _mintActionButton(
                icon: Icons.info_outline,
                label: 'App Info',
                onTap: _showVersionOverlay,
                fontSize: fontSize,
              ),

              const SizedBox(height: 28),
              _buildLogoutButton(fontSize),
            ],
          ),
        ),
      ),

      // keep your names, just new look
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  // ---------- UI bits ----------
  Widget _headerPill(String text, double size) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.black, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: const Offset(0, 3),
        )
      ],
    ),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: 'HappyMonkey',
        fontSize: size,
        color: Colors.black,
      ),
    ),
  );

  Widget _mintActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double? fontSize,
  }) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.black, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: (fontSize ?? 16) + 2,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(double? fontSize) {
    final softRed = const Color(0xFFF8B2B2);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLogoutConfirmation(fontSize),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
          decoration: BoxDecoration(
            color: softRed,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Text(
            'Logout',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: fontSize,
              color: Colors.black,
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
              Navigator.pushReplacement(context, createFadeRoute(const LoginScreen()));
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

  // -------- Bottom Nav (same names/vars, new style) --------
  Widget _buildCustomBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 32),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(icon: Icons.settings, index: 0, isHome: true),
          _buildNavItem(icon: Icons.auto_graph, index: 1),
          _buildNavItem(icon: Icons.home, index: 2),
          _buildNavItem(icon: Icons.self_improvement, index: 3),
          _buildNavItem(icon: Icons.person, index: 4),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index, bool isHome = false}) {
    final bool isSelected = (_selectedIndex == index);
    final Color bg = isSelected ? mint : Colors.white;
    const Color ic = Colors.black;

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() => _selectedIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(context, createFadeRoute(const SettingsScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, createFadeRoute(const InsightsScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, createFadeRoute(const HomeScreen()));
          } else if (index == 3) {
            Navigator.pushReplacement(context, createFadeRoute(const ActivitiesScreen()));
          } else if (index == 4) {
            Navigator.pushReplacement(context, createFadeRoute(const ProfileScreen()));
          }
        },
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          child: Icon(icon, color: ic, size: 26),
        ),
      ),
    );
  }
}
