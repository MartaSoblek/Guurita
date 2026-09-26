import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/responsive/responsive_layout.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/dashboard_metric_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/services/auth_service.dart';
import '../controllers/dashboard_controller.dart';
import '../../main_navigation/controllers/navigation_controller.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    final user = AuthService().currentUser;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(body: LoadingIndicator());
      }

      return RefreshIndicator(
        onRefresh: controller.loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: ResponsiveContainer(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Banner
                _buildGreetingBanner(user),
                const SizedBox(height: 16),

                // Admin Teacher Filter
                if (controller.isAdmin.value) ...[
                  _buildAdminFilter(context, controller),
                  const SizedBox(height: 16),
                ],

                // Metrics Row / Grid
                _buildMetrics(context, controller),
                const SizedBox(height: 24),

                // Quick Action Shortcuts
                _buildQuickActions(context, controller),
                const SizedBox(height: 24),

                // Today Schedules Section
                _buildTodaySchedules(context, controller),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAdminFilter(BuildContext context, DashboardController controller) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Filter Guru:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: controller.selectedFilterGuru.value,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'Pilih Guru',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Semua Guru (Seluruh Sekolah)', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  ...controller.guruList.map(
                    (g) => DropdownMenuItem<int?>(
                      value: g.id,
                      child: Text('${g.nama} (${g.mataPelajaran ?? "Guru"})'),
                    ),
                  ),
                ],
                onChanged: controller.filterByGuru,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingBanner(dynamic user) {
    final isAdmin = user != null && (user.role == 'admin' || user.isAdmin == true);
    final displayName = user?.nama ?? 'Bapak/Ibu Guru';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAdmin
              ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]
              : [AppColors.primary, const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isAdmin ? Icons.admin_panel_settings : Icons.verified, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      isAdmin ? 'Panel Administrator' : 'Portal Guru',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormatter.getTodayFormatted(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Selamat Datang, $displayName 👋',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAdmin
                ? 'Pantau seluruh kegiatan mengajar, kehadiran siswa, dan jurnal harian guru SMK 1 Abang.'
                : 'Kelola KBM, kehadiran siswa, dan jurnal harian Anda dengan mudah di GURITA.',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(BuildContext context, DashboardController controller) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final cards = [
      DashboardMetricCard(
        title: 'Kelas Hari Ini',
        value: '${controller.totalKelasHariIni.value}',
        subtitle: 'Sesi terjadwal',
        icon: Icons.meeting_room_outlined,
        accentColor: AppColors.primary,
        backgroundColor: AppColors.primarySubtle,
        onTap: () {
          final navController = Get.find<NavigationController>();
          navController.changeIndex(1); // Jadwal
        },
      ),
      DashboardMetricCard(
        title: 'Siswa Hadir',
        value: '${controller.totalSiswaHadir.value}',
        subtitle: 'Rekap kehadiran',
        icon: Icons.groups_outlined,
        accentColor: AppColors.success,
        backgroundColor: AppColors.successSubtle,
        onTap: () {
          final navController = Get.find<NavigationController>();
          navController.changeIndex(2); // Kehadiran
        },
      ),
      DashboardMetricCard(
        title: 'Jurnal Terisi',
        value: '${controller.totalJurnalHariIni.value}',
        subtitle: 'Aktivitas KBM',
        icon: Icons.assignment_outlined,
        accentColor: AppColors.warning,
        backgroundColor: AppColors.warningSubtle,
        onTap: () {
          final navController = Get.find<NavigationController>();
          navController.changeIndex(4); // Riwayat Jurnal
        },
      ),
      DashboardMetricCard(
        title: 'Rata-rata Hadir',
        value: controller.persentaseKehadiran.value,
        subtitle: 'Tingkat presensi',
        icon: Icons.trending_up,
        accentColor: AppColors.info,
        backgroundColor: AppColors.infoSubtle,
        onTap: () {
          final navController = Get.find<NavigationController>();
          navController.changeIndex(5); // Rekap
        },
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: c,
        ))).toList(),
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.15,
        children: cards,
      );
    }
  }

  Widget _buildQuickActions(BuildContext context, DashboardController controller) {
    final isAdmin = AuthService().currentUser?.isAdmin ?? false;
    final actions = [
      {'title': 'Isi Kehadiran', 'icon': Icons.how_to_reg, 'color': AppColors.primary, 'index': 2},
      {'title': 'Buat Jurnal', 'icon': Icons.edit_note, 'color': AppColors.success, 'index': 3},
      {'title': 'Jadwal Mengajar', 'icon': Icons.calendar_today, 'color': AppColors.warning, 'index': 1},
      {'title': 'Rekap Presensi', 'icon': Icons.assessment, 'color': AppColors.info, 'index': 5},
      if (isAdmin)
        {'title': 'Kelola Guru', 'icon': Icons.badge, 'color': const Color(0xFF8B5CF6), 'index': 8},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksi Cepat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isNarrow ? 2 : 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 70,
            ),
            itemBuilder: (context, index) {
              final act = actions[index];
              final color = act['color'] as Color;
              return InkWell(
                onTap: () {
                  if (act['title'] == 'Buat Jurnal' && controller.todaySchedules.isNotEmpty) {
                    final unfilled = controller.todaySchedules.firstWhereOrNull(
                          (s) => !controller.isJournalFilled(s.id),
                        ) ??
                        controller.todaySchedules.first;
                    controller.openJournalForm(context, unfilled);
                    return;
                  }
                  final targetIndex = act['index'] as int;
                  final navController = Get.find<NavigationController>();
                  navController.changeIndex(targetIndex);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(act['icon'] as IconData, color: color, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          act['title'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildTodaySchedules(BuildContext context, DashboardController controller) {
    final todayDayName = DateFormatter.getTodayDayName();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Text(
                    'Jadwal Mengajar Hari Ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      todayDayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                final navController = Get.find<NavigationController>();
                navController.changeIndex(1); // Jadwal
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Semua Jadwal'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (controller.todaySchedules.isEmpty)
          EmptyStateWidget(
            title: 'Tidak Ada Jadwal Hari Ini ($todayDayName)',
            message: 'Tidak ada jadwal mengajar untuk akun Anda pada hari $todayDayName.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.todaySchedules.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final schedule = controller.todaySchedules[index];
              final isFilled = controller.isJournalFilled(schedule.id);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isFilled
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: InkWell(
                  onTap: () => controller.openJournalForm(context, schedule),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 650;

                        final timeBadge = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isFilled ? AppColors.successSubtle : AppColors.primarySubtle,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isFilled ? Icons.check_circle_outline : Icons.access_time,
                                size: 16,
                                color: isFilled ? AppColors.success : AppColors.primary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                schedule.jamMulai,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isFilled ? AppColors.success : AppColors.primary,
                                ),
                              ),
                              Text(
                                schedule.jamSelesai,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );

                        final details = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    schedule.namaKelas ?? 'Kelas',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isFilled ? AppColors.successSubtle : AppColors.warningSubtle,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isFilled ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                        size: 13,
                                        color: isFilled ? AppColors.success : AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isFilled ? 'Sudah Diisi' : 'Belum Diisi',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isFilled ? AppColors.success : const Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  schedule.hari,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              schedule.namaMapel ?? 'Mata Pelajaran',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (schedule.namaGuru != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Pengampu: ${schedule.namaGuru}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        );

                        final presensiBtn = OutlinedButton.icon(
                          onPressed: () {
                            final navController = Get.find<NavigationController>();
                            navController.changeIndex(2); // Kehadiran
                          },
                          icon: const Icon(Icons.how_to_reg, size: 16),
                          label: const Text('Presensi'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        );

                        final jurnalBtn = ElevatedButton.icon(
                          onPressed: () => controller.openJournalForm(context, schedule),
                          icon: Icon(isFilled ? Icons.edit_note : Icons.add_task, size: 16),
                          label: Text(isFilled ? 'Edit Jurnal' : 'Isi Jurnal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFilled ? const Color(0xFF0F766E) : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        );

                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  timeBadge,
                                  const SizedBox(width: 14),
                                  Expanded(child: details),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: presensiBtn),
                                  const SizedBox(width: 8),
                                  Expanded(child: jurnalBtn),
                                ],
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              timeBadge,
                              const SizedBox(width: 16),
                              Expanded(child: details),
                              const SizedBox(width: 12),
                              presensiBtn,
                              const SizedBox(width: 8),
                              jurnalBtn,
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
