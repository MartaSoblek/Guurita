import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';

class MobileBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MobileBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex.clamp(0, 3),
        onDestinationSelected: onTap,
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: AppColors.primarySubtle,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: AppColors.primary),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note, color: AppColors.primary),
            label: 'Jurnal',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
