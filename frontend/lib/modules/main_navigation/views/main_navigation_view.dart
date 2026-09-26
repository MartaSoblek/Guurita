import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/responsive/responsive_layout.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../../core/widgets/gurita_logo.dart';
import '../../../core/widgets/mobile_bottom_nav.dart';
import '../controllers/navigation_controller.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../schedule/views/schedule_view.dart';
import '../../attendance/views/attendance_view.dart';
import '../../journal/views/journal_form_view.dart';
import '../../journal/views/journal_history_view.dart';
import '../../report/views/report_view.dart';
import '../../subject/views/subject_view.dart';
import '../../class/views/class_view.dart';
import '../../teacher/views/teacher_view.dart';
import '../../profile/views/profile_view.dart';
import '../../../data/services/auth_service.dart';

class MainNavigationView extends GetView<NavigationController> {
  const MainNavigationView({super.key});

  static const List<Widget> _pages = [
    DashboardView(),      // 0
    ScheduleView(),       // 1
    AttendanceView(),     // 2
    JournalFormView(),    // 3
    JournalHistoryView(), // 4
    ReportView(),         // 5
    SubjectView(),        // 6
    ClassView(),          // 7
    TeacherView(),        // 8
    ProfileView(),        // 9
  ];

  static const List<String> _pageTitles = [
    'Dashboard Guru',
    'Jadwal Mengajar',
    'Presensi Kehadiran Siswa',
    'Jurnal Mengajar KBM',
    'Riwayat Jurnal KBM',
    'Rekapitulasi Kehadiran',
    'Mata Pelajaran',
    'Data Kelas',
    'Data Guru & Pendidik',
    'Profil Pengguna',
  ];

  static const List<String> _pageSubtitles = [
    'Ringkasan aktivitas pembelajaran & presensi hari ini',
    'Daftar jadwal mengajar mingguan',
    'Catat kehadiran siswa secara langsung per jam pelajaran',
    'Kelola materi, metode, dan kendala pembelajaran',
    'Arsip seluruh pencatatan kegiatan belajar mengajar',
    'Laporan agregasi kehadiran siswa per bulan dan kelas',
    'Kelola kurikulum dan data master mata pelajaran sekolah',
    'Kelola data rombongan belajar, tingkat jenjang, dan kapasitas siswa',
    'Kelola akun dinas guru, NIP, peran, dan penugasan mata pelajaran',
    'Informasi akun dinas dan pengaturan sistem GURITA',
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileScaffold(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    return Obx(() {
      final currentIdx = controller.currentIndex.value;

      // Map global index (0-9) to mobile bottom bar index (0-3)
      int mobileNavIndex = 0;
      if (currentIdx == 0) {
        mobileNavIndex = 0; // Dashboard
      } else if (currentIdx == 1) {
        mobileNavIndex = 1; // Jadwal
      } else if (currentIdx == 3) {
        mobileNavIndex = 2; // Jurnal
      } else if (currentIdx == 9) {
        mobileNavIndex = 3; // Profil
      } else {
        mobileNavIndex = 0;
      }

      final isAdmin = AuthService().currentUser?.isAdmin ?? false;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const GuritaLogo(size: 32, showText: true),
          actions: [
            // Quick access to schedules, reports, or subjects from mobile top bar
            PopupMenuButton<int>(
              icon: const Icon(Icons.more_vert, color: AppColors.textMain),
              tooltip: 'Menu Lainnya',
              onSelected: (idx) => controller.changeIndex(idx),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(isAdmin ? 'Semua Jadwal' : 'Jadwal Mengajar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 4,
                  child: Row(
                    children: [
                      const Icon(Icons.history_edu, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(isAdmin ? 'Semua Riwayat Jurnal' : 'Riwayat Jurnal'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 5,
                  child: Row(
                    children: [
                      Icon(Icons.assessment, size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Rekap Kehadiran'),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  const PopupMenuItem(
                    value: 8,
                    child: Row(
                      children: [
                        Icon(Icons.badge, size: 18, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text('Data Guru'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 6,
                    child: Row(
                      children: [
                        Icon(Icons.menu_book, size: 18, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text('Mata Pelajaran'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 7,
                    child: Row(
                      children: [
                        Icon(Icons.meeting_room, size: 18, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text('Data Kelas'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        body: IndexedStack(
          index: currentIdx.clamp(0, _pages.length - 1),
          children: _pages,
        ),
        bottomNavigationBar: MobileBottomNav(
          currentIndex: mobileNavIndex,
          onTap: (navIndex) {
            switch (navIndex) {
              case 0:
                controller.changeIndex(0); // Dashboard
                break;
              case 1:
                controller.changeIndex(1); // Jadwal
                break;
              case 2:
                controller.changeIndex(3); // Jurnal
                break;
              case 3:
                controller.changeIndex(9); // Profil
                break;
            }
          },
        ),
      );
    });
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Obx(() {
      final currentIdx = controller.currentIndex.value.clamp(0, _pages.length - 1);

      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Left Collapsible Sidebar
            AppSidebar(
              selectedIndex: currentIdx,
              onItemSelected: (index) => controller.changeIndex(index),
            ),

            // Right Main Content Panel
            Expanded(
              child: Column(
                children: [
                  // Desktop Header
                  AppHeader(
                    title: _pageTitles[currentIdx],
                    subtitle: _pageSubtitles[currentIdx],
                  ),

                  // Page Content
                  Expanded(
                    child: IndexedStack(
                      index: currentIdx,
                      children: _pages,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
