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
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0; // gear icon

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: (fontSize ?? 18) + 6,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGreenBox(
                    title: 'Notifications',
                    icon: Icons.notifications,
                    onTap: () {
                      Navigator.push(
                        context,
                        createFadeRoute(const NotificationsScreen()),
                      );
                    },
                    fontSize: fontSize,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGreenBox(
                    title: 'Preferences',
                    icon: Icons.tune,
                    onTap: () {
                      Navigator.push(
                        context,
                        createFadeRoute(const PreferencesScreen()),
                      );
                    },
                    fontSize: fontSize,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _buildLogoutButton(fontSize),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget _buildGreenBox({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required double? fontSize,
  }) {
    return InkWell(
      onTap: onTap,
      child: Material(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF40D404)
                : const Color(0xFFB6FFB1),
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black, size: 50),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'HappyMonkey',
                  fontSize: fontSize,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(double? fontSize) {
    return InkWell(
      onTap: () => _showLogoutConfirmation(fontSize),
      child: Material(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFF00404)
                : const Color(0xFFF86464),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black),
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

  Widget _buildCustomBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

  Widget _buildNavItem(
      {required IconData icon, required int index, bool isHome = false}) {
    final bool isSelected = (_selectedIndex == index);
    Color fillColor = isSelected
        ? (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF40D404)
            : const Color(0xFFB6FFB1))
        : Theme.of(context).colorScheme.surface;

    final iconColor = isSelected ? Colors.black : Colors.grey[700];

    return Material(
      elevation: 3,
      shape: const CircleBorder(side: BorderSide(color: Colors.black)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(
                context, createFadeRoute(const SettingsScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(
                context, createFadeRoute(const InsightsScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(
                context, createFadeRoute(const HomeScreen()));
          } else if (index == 3) {
            Navigator.pushReplacement(
                context, createFadeRoute(const ActivitiesScreen()));
          } else if (index == 4) {
            Navigator.pushReplacement(
                context, createFadeRoute(const ProfileScreen()));
          }
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fillColor),
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}
