import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants/app_colors.dart';
import '../../app/constants/app_constants.dart';
import '../utils/alert_helper.dart';
import '../../data/services/auth_service.dart';
import 'gurita_logo.dart';

class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _isCollapsed = false;

  List<Map<String, dynamic>> get _menuItems {
    final isAdmin = AuthService().currentUser?.isAdmin ?? false;
    return [
      {'title': 'Dashboard', 'index': 0, 'icon': Icons.dashboard_outlined, 'selectedIcon': Icons.dashboard},
      {'title': isAdmin ? 'Semua Jadwal' : 'Jadwal Mengajar', 'index': 1, 'icon': Icons.calendar_today_outlined, 'selectedIcon': Icons.calendar_today},
      {'title': 'Jurnal Mengajar', 'index': 3, 'icon': Icons.edit_note_outlined, 'selectedIcon': Icons.edit_note},
      {'title': 'Riwayat Jurnal', 'index': 4, 'icon': Icons.history_edu_outlined, 'selectedIcon': Icons.history_edu},
      {'title': 'Rekap Kehadiran', 'index': 5, 'icon': Icons.assessment_outlined, 'selectedIcon': Icons.assessment},
      if (isAdmin) ...[
        {'title': 'Mata Pelajaran', 'index': 6, 'icon': Icons.menu_book_outlined, 'selectedIcon': Icons.menu_book},
        {'title': 'Kelola Kelas', 'index': 7, 'icon': Icons.meeting_room_outlined, 'selectedIcon': Icons.meeting_room},
      ],
      {'title': isAdmin ? 'Profil Admin' : 'Profil Guru', 'index': 8, 'icon': Icons.person_outline, 'selectedIcon': Icons.person},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double width = _isCollapsed ? 80 : 260;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header Logo GURITA
          Container(
            height: 72,
            padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 12 : 20),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!_isCollapsed)
                  const Expanded(
                    child: GuritaLogo(size: 38, showText: true),
                  )
                else
                  const GuritaLogo(size: 38, showText: false),
                IconButton(
                  icon: Icon(
                    _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  tooltip: _isCollapsed ? 'Perlebar Sidebar' : 'Ciutkan Sidebar',
                  onPressed: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  },
                ),
              ],
            ),
          ),

          // Menu list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final targetIndex = item['index'] as int;
                final isSelected = widget.selectedIndex == targetIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Tooltip(
                    message: _isCollapsed ? item['title'] : '',
                    child: InkWell(
                      onTap: () => widget.onItemSelected(targetIndex),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primarySubtle : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                              : null,
                        ),
                        padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 0 : 16),
                        child: Row(
                          mainAxisAlignment: _isCollapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            Icon(
                              isSelected ? item['selectedIcon'] : item['icon'],
                              color: isSelected ? AppColors.primary : AppColors.textMuted,
                              size: 22,
                            ),
                            if (!_isCollapsed) ...[
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item['title'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.primary : AppColors.textMain,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer Logout & School Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                if (!_isCollapsed) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          AppConstants.appName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sistem Informasi Digital',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Tooltip(
                  message: _isCollapsed ? 'Keluar' : '',
                  child: InkWell(
                    onTap: () async {
                      final confirmed = await AlertHelper.showConfirmDialog(
                        title: 'Konfirmasi Keluar',
                        message: 'Apakah Anda yakin ingin keluar dari akun GURITA?',
                        confirmText: 'Keluar',
                        isDanger: true,
                      );
                      if (confirmed) {
                        await AuthService().logout();
                        Get.offAllNamed('/login');
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 42,
                      padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 0 : 12),
                      decoration: BoxDecoration(
                        color: AppColors.errorSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: _isCollapsed
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.logout, color: AppColors.error, size: 20),
                          if (!_isCollapsed) ...[
                            const SizedBox(width: 10),
                            const Text(
                              'Keluar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
