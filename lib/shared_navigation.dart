import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'insights_screen.dart';
import 'activities_screen.dart';
import 'profile_screen.dart';
import 'transition_helper.dart';

class SharedNavigation {
  static Widget buildBottomNavigation({
    required int selectedIndex,
    required BuildContext context,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.settings, 0, selectedIndex, context),
            _buildNavItem(Icons.auto_graph, 1, selectedIndex, context),
            _buildNavItem(Icons.home, 2, selectedIndex, context),
            _buildNavItem(Icons.self_improvement, 3, selectedIndex, context),
            _buildNavItem(Icons.person, 4, selectedIndex, context),
          ],
        ),
      ),
    );
  }

  static Widget _buildNavItem(
    IconData icon,
    int idx,
    int selectedIndex,
    BuildContext context,
  ) {
    final isSel = selectedIndex == idx;
    const mint = Color(0xFFB6FFB1);

    return Material(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (idx == 0) {
            Navigator.pushReplacement(
              context,
              createFadeRoute(const SettingsScreen()),
            );
          } else if (idx == 1) {
            Navigator.pushReplacement(
              context,
              createFadeRoute(const InsightsScreen()),
            );
          } else if (idx == 2) {
            Navigator.pushReplacement(
              context,
              createFadeRoute(const HomeScreen()),
            );
          } else if (idx == 3) {
            Navigator.pushReplacement(
              context,
              createFadeRoute(const ActivitiesScreen()),
            );
          } else if (idx == 4) {
            Navigator.pushReplacement(
              context,
              createFadeRoute(const ProfileScreen()),
            );
          }
        },
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? mint : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isSel ? Colors.black : Colors.grey[800],
            size: 26,
          ),
        ),
      ),
    );
  }
}
