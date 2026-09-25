import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/responsive/responsive_layout.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/journal_session_model.dart';
import '../../main_navigation/controllers/navigation_controller.dart';
import '../controllers/journal_controller.dart';
import 'journal_form_dialog.dart';

class JournalFormView extends StatelessWidget {
  const JournalFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(JournalController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildSemesterScheduleView(context, controller),
    );
  }

  // -------------------------------------------------------------
  // HALAMAN AWAL: DAFTAR SESI JADWAL 1 SEMESTER (TANGGAL <= TODAY)
  // -------------------------------------------------------------
  Widget _buildSemesterScheduleView(BuildContext context, JournalController controller) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return RefreshIndicator(
      onRefresh: () => controller.loadSemesterSessions(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: ResponsiveContainer(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card dengan Semester Title dan Info Proteksi Tanggal
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primarySubtle,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(
                                  () => Text(
                                    controller.semesterTitle.value,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Jadwal KBM 1 semester sesuai hari & tanggal berjalan. Sesi di hari mendatang otomatis terkunci dan baru muncul ketika hari KBM telah tiba.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppColors.primary),
                            tooltip: 'Muat Ulang Sesi',
                            onPressed: () => controller.loadSemesterSessions(),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.history_edu, size: 16),
                            label: const Text('Riwayat Jurnal'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              if (Get.isRegistered<NavigationController>()) {
                                Get.find<NavigationController>().changeIndex(4);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats Ringkasan Sesi Semester
                      Obx(() => _buildSemesterStats(context, controller, isDesktop)),
                    ],
                  ),
                ),
              ),

              // Banner Pintar Sesi Hari Ini (Quick Pop-up Trigger)
              Obx(() => _buildTodayQuickBanner(context, controller, isDesktop)),

              const SizedBox(height: 16),

              // Filter & Search Bar
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Filter Status Chips
                      Obx(
                        () => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusFilterChip(controller, 'semua', 'Semua Sesi (${controller.totalSesiSemester.value})'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip(controller, 'hari_ini', 'Hari Ini (${controller.totalHariIni.value})'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip(controller, 'belum_diisi', 'Belum Diisi (${controller.totalBelumDiisi.value})'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip(controller, 'sudah_diisi', 'Sudah Diisi (${controller.totalSudahDiisi.value})'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Search Field & Admin Teacher Filter
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (val) => controller.searchSessions(val),
                              decoration: InputDecoration(
                                hintText: 'Cari mata pelajaran, kelas, atau materi...',
                                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                            ),
                          ),
                          if (controller.isAdmin.value) ...[
                            const SizedBox(width: 10),
                            Obx(
                              () => DropdownButton<int?>(
                                value: controller.selectedFilterGuru.value,
                                hint: const Text('Filter Guru', style: TextStyle(fontSize: 12)),
                                items: [
                                  const DropdownMenuItem<int?>(value: null, child: Text('Semua Guru', style: TextStyle(fontSize: 12))),
                                  ...controller.guruList.map(
                                    (g) => DropdownMenuItem<int?>(
                                      value: g.id,
                                      child: Text(g.nama, style: const TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ],
                                onChanged: (val) => controller.filterByGuru(val),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Daftar Sesi
              Obx(() {
                if (controller.isLoadingSessions.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (controller.semesterSessions.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Column(
                          children: const [
                            Icon(Icons.event_available, size: 56, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text(
                              'Tidak ada sesi KBM untuk filter ini',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textMain),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Catatan: Sesi jadwal di masa depan tidak dimunculkan sampai hari KBM yang bersangkutan tiba.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.semesterSessions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final session = controller.semesterSessions[index];
                    return _buildSessionCard(context, controller, session);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterStats(BuildContext context, JournalController controller, bool isDesktop) {
    final stats = [
      {
        'title': 'Sesi Semester (s.d. Hari Ini)',
        'value': controller.totalSesiSemester.value.toString(),
        'icon': Icons.calendar_view_week,
        'color': AppColors.primary,
        'bgColor': AppColors.primarySubtle,
      },
      {
        'title': 'Sesi Hari Ini',
        'value': controller.totalHariIni.value.toString(),
        'icon': Icons.today,
        'color': Colors.amber.shade800,
        'bgColor': Colors.amber.shade50,
      },
      {
        'title': 'Perlu Diisi (Belum)',
        'value': controller.totalBelumDiisi.value.toString(),
        'icon': Icons.pending_actions,
        'color': AppColors.error,
        'bgColor': AppColors.errorSubtle,
      },
      {
        'title': 'Sudah Selesai Diisi',
        'value': controller.totalSudahDiisi.value.toString(),
        'icon': Icons.check_circle_outline,
        'color': AppColors.success,
        'bgColor': AppColors.successSubtle,
      },
    ];

    if (isDesktop) {
      return Row(
        children: stats.map((s) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: s['bgColor'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(s['icon'] as IconData, color: s['color'] as Color, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['value'] as String,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: s['color'] as Color,
                          ),
                        ),
                        Text(
                          s['title'] as String,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: stats.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: s['bgColor'] as Color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(s['icon'] as IconData, color: s['color'] as Color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s['value'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: s['color'] as Color,
                      ),
                    ),
                    Text(
                      s['title'] as String,
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusFilterChip(JournalController controller, String key, String label) {
    final isSelected = controller.selectedStatusFilter.value == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : AppColors.textMain,
      ),
      onSelected: (_) => controller.filterStatus(key),
    );
  }

  Widget _buildSessionCard(BuildContext context, JournalController controller, JournalSessionModel session) {
    final isToday = session.isToday;
    final isFilled = session.isSudahDiisi;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.5)
              : (isFilled ? AppColors.border : AppColors.error.withValues(alpha: 0.3)),
          width: isToday ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Tanggal & Badge Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 16,
                      color: isToday ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormatter.formatIndonesianDate(session.tanggal),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isToday ? AppColors.primary : AppColors.textMain,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade700, width: 0.8),
                        ),
                        child: Text(
                          'HARI INI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFilled ? AppColors.successSubtle : AppColors.errorSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFilled ? Icons.check_circle : Icons.pending,
                        size: 13,
                        color: isFilled ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFilled ? 'Sudah Diisi' : 'Belum Diisi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isFilled ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2: Mapel, Kelas, Jam
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.namaMapel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primarySubtle,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              session.namaKelas,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${session.jamMulai} - ${session.jamSelesai}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          if (session.namaGuru.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                session.namaGuru,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Jika sudah diisi dan ada ringkasan materi
            if (isFilled && session.materi != null && session.materi!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.article_outlined, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Materi: ${session.materi}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (session.hasFoto) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera_rounded, size: 12, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Ada Foto',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Lencana Kehadiran Siswa pada List Jurnal
            if (isFilled) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      session.totalKehadiran > 0
                          ? 'Kehadiran Siswa: ${session.totalHadir}/${session.totalKehadiran} Hadir'
                          : 'Presensi Siswa: Terdata',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    const Spacer(),
                    _buildAttendanceMiniBadge('H', session.totalHadir, AppColors.success, AppColors.successSubtle),
                    const SizedBox(width: 6),
                    _buildAttendanceMiniBadge('I', session.totalIzin, Colors.blue.shade700, Colors.blue.shade50),
                    const SizedBox(width: 6),
                    _buildAttendanceMiniBadge('S', session.totalSakit, Colors.amber.shade800, Colors.amber.shade50),
                    const SizedBox(width: 6),
                    _buildAttendanceMiniBadge('A', session.totalAlpa, AppColors.error, AppColors.errorSubtle),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.how_to_reg_outlined, size: 14, color: AppColors.textMuted),
                  SizedBox(width: 6),
                  Text(
                    'Presensi kehadiran siswa dicatat saat mengisi jurnal ini',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Row 3: Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isFilled)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_note, size: 16),
                    label: const Text('Lihat / Edit Jurnal & Presensi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => JournalFormDialog.show(context, session),
                  )
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: Text(isToday ? 'Isi Jurnal & Presensi Hari Ini' : 'Isi Jurnal & Presensi Sesi Ini'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isToday ? AppColors.primary : Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: () => JournalFormDialog.show(context, session),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceMiniBadge(String code, int count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$code: $count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  // -------------------------------------------------------------
  // BANNER PINTAR SESI HARI INI (QUICK POP-UP TRIGGER)
  // -------------------------------------------------------------
  Widget _buildTodayQuickBanner(BuildContext context, JournalController controller, bool isDesktop) {
    final todayUnfilled = controller.semesterSessions.firstWhereOrNull((s) => s.isToday && s.isBelumDiisi);
    if (todayUnfilled == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade50, Colors.orange.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Sesi KBM Hari Ini Siap Diisi!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Hari Ini',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF78350F)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${todayUnfilled.namaMapel} â€¢ ${todayUnfilled.namaKelas} (${todayUnfilled.jamMulai} - ${todayUnfilled.jamSelesai} WITA)',
                    style: TextStyle(fontSize: 13, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Buka Pop-up Isi Jurnal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => JournalFormDialog.show(context, todayUnfilled),
            ),
          ],
        ),
      ),
    );
  }
}
