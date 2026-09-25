import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/responsive/responsive_layout.dart';
import '../../../core/utils/alert_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/journal_session_model.dart';
import '../../../data/models/attendance_model.dart';
import '../controllers/journal_controller.dart';

class JournalFormDialog extends StatefulWidget {
  final JournalSessionModel session;

  const JournalFormDialog({super.key, required this.session});

  /// Buka modal pop-up pengisian jurnal dan presensi dengan animasi halus & menarik
  static Future<void> show(BuildContext context, JournalSessionModel session) async {
    final controller = Get.find<JournalController>();
    controller.selectSessionToFill(session);

    return Get.dialog<void>(
      JournalFormDialog(session: session),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 300),
      transitionCurve: Curves.easeOutBack,
    );
  }

  @override
  State<JournalFormDialog> createState() => _JournalFormDialogState();
}

class _JournalFormDialogState extends State<JournalFormDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _studentSearchController = TextEditingController();
  String _studentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  void _handleCancel(JournalController controller) {
    controller.closeForm();
    if (Get.isDialogOpen ?? false) {
      Get.back();
    } else if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _handleSave(JournalController controller) async {
    // Validasi materi pokok
    if (controller.materiController.text.trim().isEmpty) {
      _tabController.animateTo(0);
      AlertHelper.showWarning('Materi pokok pembelajaran wajib diisi pada tab Jurnal.');
      return;
    }

    final success = await controller.saveJournal();
    if (success && mounted) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      } else if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showKeteranganDialog(
    BuildContext context,
    JournalController controller,
    int originalIndex,
    AttendanceModel att,
  ) {
    final textController = TextEditingController(text: att.keterangan ?? '');
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.note_alt_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Presensi: ${att.namaSiswa}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Status saat ini: ${att.status}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Alasan / Keterangan',
                hint: 'Misal: Demam, Lomba Olahraga, Surat Dokter...',
                controller: textController,
                maxLines: 2,
                prefixIcon: Icons.edit_note,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      controller.updateAttendanceKeterangan(originalIndex, textController.text.trim());
                      Get.back();
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JournalController>();
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final size = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 20,
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 14,
        vertical: isDesktop ? 28 : 16,
      ),
      child: Container(
        width: isDesktop ? 900 : size.width * 0.96,
        height: isDesktop ? size.height * 0.88 : size.height * 0.94,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // 1. Header Dialog Menarik & Modern
            _buildDialogHeader(context, controller, isDesktop),

            // 2. Tab Navigation
            _buildTabBar(context, controller),

            // 3. Tab Contents (Jurnal & Presensi)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJournalTab(context, controller, isDesktop),
                  _buildAttendanceTab(context, controller, isDesktop),
                ],
              ),
            ),

            // 4. Sticky Footer Action Bar
            _buildDialogFooter(context, controller, isDesktop),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // HEADER DIALOG (GRADIENT & INFORMASI SESI)
  // -------------------------------------------------------------
  Widget _buildDialogHeader(BuildContext context, JournalController controller, bool isDesktop) {
    final session = widget.session;
    final isFilled = session.isSudahDiisi;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: isDesktop ? 18 : 14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isFilled ? 'Edit Jurnal & Presensi Siswa' : 'Isi Jurnal & Presensi KBM',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: isFilled
                                ? const Color(0xFF10B981)
                                : (session.isToday ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.25)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isFilled
                                ? 'Sudah Diisi'
                                : (session.isToday ? 'Hari Ini' : 'Belum Diisi'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.namaMapel} • ${session.namaKelas} • ${session.jamMulai} - ${session.jamSelesai}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                tooltip: 'Tutup Pop-up',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  padding: const EdgeInsets.all(8),
                ),
                onPressed: () => _handleCancel(controller),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chips Rincian Sesi
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildHeaderInfoChip(Icons.calendar_today_rounded, DateFormatter.formatIndonesianDate(session.tanggal)),
              _buildHeaderInfoChip(Icons.schedule_rounded, '${session.jamMulai} - ${session.jamSelesai} WITA'),
              _buildHeaderInfoChip(Icons.meeting_room_rounded, 'Kelas ${session.namaKelas}'),
              _buildHeaderInfoChip(Icons.person_outline_rounded, 'Guru: ${session.namaGuru}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB BAR INTERAKTIF
  // -------------------------------------------------------------
  Widget _buildTabBar(BuildContext context, JournalController controller) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3.5,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: [
          const Tab(
            icon: Icon(Icons.edit_note_rounded, size: 20),
            text: '1. Jurnal KBM',
          ),
          Tab(
            icon: const Icon(Icons.how_to_reg_rounded, size: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('2. Presensi Siswa'),
                const SizedBox(width: 8),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${controller.currentAttendance.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
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

  // -------------------------------------------------------------
  // TAB 1: FORMULIR JURNAL KBM
  // -------------------------------------------------------------
  Widget _buildJournalTab(BuildContext context, JournalController controller, bool isDesktop) {
    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Materi Pokok
            _buildSectionTitle(
              icon: Icons.topic_rounded,
              title: 'Materi Pokok',
              isRequired: true,
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Materi Pokok (Wajib)',
              hint: 'Tuliskan judul bab atau topik materi KBM hari ini...',
              controller: controller.materiController,
              prefixIcon: Icons.menu_book_rounded,
              validator: (val) => val == null || val.trim().isEmpty ? 'Materi pokok wajib diisi' : null,
            ),

            const SizedBox(height: 20),

            // Section 2: Kegiatan Pembelajaran
            _buildSectionTitle(
              icon: Icons.format_list_bulleted_rounded,
              title: 'Kegiatan Pembelajaran',
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Kegiatan Pembelajaran (Opsional)',
              hint: 'Misal: Pendahuluan apersepsi, Inti praktikum, Penutup evaluasi...',
              controller: controller.kegiatanController,
              prefixIcon: Icons.notes_rounded,
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            // Section 3: Metode & Media Pembelajaran
            _buildSectionTitle(
              icon: Icons.psychology_rounded,
              title: 'Metode & Media Pembelajaran',
            ),
            const SizedBox(height: 10),
            if (isDesktop)
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Metode Pembelajaran (Opsional)',
                      hint: 'Misal: Praktikum, Diskusi...',
                      controller: controller.metodeController,
                      prefixIcon: Icons.lightbulb_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Media / Alat Pembelajaran (Opsional)',
                      hint: 'Misal: LCD Proyektor, Modul praktikum...',
                      controller: controller.mediaController,
                      prefixIcon: Icons.devices_other_rounded,
                    ),
                  ),
                ],
              )
            else ...[
              CustomTextField(
                label: 'Metode Pembelajaran (Opsional)',
                hint: 'Misal: Praktikum, Diskusi...',
                controller: controller.metodeController,
                prefixIcon: Icons.lightbulb_outline_rounded,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Media / Alat Pembelajaran (Opsional)',
                hint: 'Misal: LCD Proyektor, Modul praktikum...',
                controller: controller.mediaController,
                prefixIcon: Icons.devices_other_rounded,
              ),
            ],

            const SizedBox(height: 20),

            // Section 4: Kendala & Solusi / Tindak Lanjut
            _buildSectionTitle(
              icon: Icons.troubleshoot_rounded,
              title: 'Kendala & Solusi',
            ),
            const SizedBox(height: 10),
            if (isDesktop)
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Kendala Pembelajaran (Opsional)',
                      hint: 'Kendala yang dihadapi selama KBM...',
                      controller: controller.kendalaController,
                      prefixIcon: Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Tindak Lanjut / Solusi (Opsional)',
                      hint: 'Solusi pemecahan masalah...',
                      controller: controller.tindakLanjutController,
                      prefixIcon: Icons.task_alt_rounded,
                    ),
                  ),
                ],
              )
            else ...[
              CustomTextField(
                label: 'Kendala Pembelajaran (Opsional)',
                hint: 'Kendala yang dihadapi selama KBM...',
                controller: controller.kendalaController,
                prefixIcon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Tindak Lanjut / Solusi (Opsional)',
                hint: 'Solusi pemecahan masalah...',
                controller: controller.tindakLanjutController,
                prefixIcon: Icons.task_alt_rounded,
              ),
            ],

            const SizedBox(height: 20),

            // Section 5: Catatan Tambahan Guru
            _buildSectionTitle(
              icon: Icons.note_alt_rounded,
              title: 'Catatan Tambahan',
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Catatan Guru (Opsional)',
              hint: 'Catatan perilaku siswa atau pengingat sesi berikutnya...',
              controller: controller.catatanController,
              prefixIcon: Icons.edit_note_rounded,
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            // Section 6: Upload Foto Dokumentasi Kegiatan
            _buildPhotoUploadSection(context, controller, isDesktop),

            const SizedBox(height: 24),

            // Next Step Button to Tab 2
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Lanjut ke Presensi Siswa'),
                onPressed: () => _tabController.animateTo(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: PRESENSI SISWA DENGAN PIL KELAS REAL-TIME
  // -------------------------------------------------------------
  Widget _buildAttendanceTab(BuildContext context, JournalController controller, bool isDesktop) {
    return Column(
      children: [
        // Top Toolbar: Live Counters & Quick Search & Hadir Semua
        Container(
          padding: EdgeInsets.all(isDesktop ? 16.0 : 12.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              // Live Counters Bar
              Obx(() => _buildLiveCountersBar(controller, isDesktop)),

              const SizedBox(height: 12),

              // Filter Search & Hadir Semua Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _studentSearchController,
                      onChanged: (val) {
                        setState(() {
                          _studentSearchQuery = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau NIS siswa...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                        suffixIcon: _studentSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _studentSearchController.clear();
                                  setState(() {
                                    _studentSearchQuery = '';
                                  });
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Hadir Semua'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => controller.markAllPresent(),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Student List View
        Expanded(
          child: Obx(() {
            if (controller.isLoadingStudents.value) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 14),
                    Text(
                      'Memuat daftar siswa kelas ${widget.session.namaKelas}...',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            if (controller.currentAttendance.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.people_outline_rounded, size: 54, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'Tidak ada siswa terdaftar di kelas ini',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textMain),
                      ),
                    ],
                  ),
                ),
              );
            }

            final filteredList = _studentSearchQuery.isEmpty
                ? controller.currentAttendance.toList()
                : controller.currentAttendance.where((a) =>
                    a.namaSiswa.toLowerCase().contains(_studentSearchQuery.toLowerCase()) ||
                    a.nis.contains(_studentSearchQuery)).toList();

            if (filteredList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'Tidak ditemukan siswa dengan kata kunci "$_studentSearchQuery"',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final student = filteredList[index];
                final originalIndex = controller.currentAttendance.indexWhere(
                  (a) => a.siswaId == student.siswaId,
                );

                return _buildStudentCard(context, controller, student, originalIndex, index);
              },
            );
          }),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // REKAP LIVE COUNTERS DENGAN TAMPILAN MENARIK
  // -------------------------------------------------------------
  Widget _buildLiveCountersBar(JournalController controller, bool isDesktop) {
    final counters = [
      {'label': 'Total Siswa', 'count': controller.totalSiswa, 'color': AppColors.primary, 'bg': AppColors.primarySubtle},
      {'label': 'Hadir (H)', 'count': controller.countHadir, 'color': AppColors.success, 'bg': AppColors.successSubtle},
      {'label': 'Izin (I)', 'count': controller.countIzin, 'color': const Color(0xFF0284C7), 'bg': const Color(0xFFF0F9FF)},
      {'label': 'Sakit (S)', 'count': controller.countSakit, 'color': const Color(0xFFD97706), 'bg': const Color(0xFFFFFBEB)},
      {'label': 'Alpa (A)', 'count': controller.countAlpa, 'color': AppColors.error, 'bg': AppColors.errorSubtle},
    ];

    return Row(
      children: counters.map((c) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c['bg'] as Color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (c['color'] as Color).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c['label'] as String,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${c['count']}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // -------------------------------------------------------------
  // CARD SATU SISWA DENGAN SELECTOR STATUS H/I/S/A
  // -------------------------------------------------------------
  Widget _buildStudentCard(
    BuildContext context,
    JournalController controller,
    AttendanceModel student,
    int originalIndex,
    int displayIndex,
  ) {
    final isPresent = student.status == 'Hadir';
    final hasNote = student.keterangan != null && student.keterangan!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isPresent ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPresent ? AppColors.border : AppColors.primary.withValues(alpha: 0.35),
          width: isPresent ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Index Badge / Avatar
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPresent ? AppColors.primarySubtle : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${displayIndex + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isPresent ? AppColors.primary : AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nama Siswa & NIS & Keterangan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.namaSiswa,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'NIS: ${student.nis}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                    if (hasNote) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Text(
                          'Ket: ${student.keterangan}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
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

          // Note Icon Button (Opsional untuk mencatat alasan Izin/Sakit/Alpa)
          IconButton(
            icon: Icon(
              hasNote ? Icons.chat_bubble_rounded : Icons.add_comment_outlined,
              size: 18,
              color: hasNote ? AppColors.primary : AppColors.textMuted,
            ),
            tooltip: hasNote ? 'Ubah Catatan Siswa' : 'Tambah Catatan Siswa',
            onPressed: () => _showKeteranganDialog(context, controller, originalIndex, student),
          ),
          const SizedBox(width: 6),

          // 4 Segmented Status Buttons (Hadir, Izin, Sakit, Alpa)
          _buildStatusPill(controller, originalIndex, student, 'Hadir', 'H', AppColors.success),
          const SizedBox(width: 4),
          _buildStatusPill(controller, originalIndex, student, 'Izin', 'I', const Color(0xFF0284C7)),
          const SizedBox(width: 4),
          _buildStatusPill(controller, originalIndex, student, 'Sakit', 'S', const Color(0xFFD97706)),
          const SizedBox(width: 4),
          _buildStatusPill(controller, originalIndex, student, 'Alpa', 'A', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildStatusPill(
    JournalController controller,
    int originalIndex,
    AttendanceModel student,
    String statusKey,
    String shortLabel,
    Color activeColor,
  ) {
    final isSelected = student.status == statusKey;

    return InkWell(
      onTap: () {
        controller.updateAttendanceStatus(originalIndex, statusKey);
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        width: 34,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          shortLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STICKY FOOTER DIALOG
  // -------------------------------------------------------------
  Widget _buildDialogFooter(BuildContext context, JournalController controller, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Live status summary pill
          Expanded(
            child: Obx(
              () => Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${controller.countHadir}/${controller.totalSiswa} Hadir • ${controller.countIzin} Izin • ${controller.countSakit} Sakit • ${controller.countAlpa} Alpa',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Action Buttons
          Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: () => _handleCancel(controller),
                child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Obx(
                () => CustomButton(
                  text: widget.session.isSudahDiisi ? 'Perbarui Jurnal & Presensi' : 'Simpan Jurnal & Presensi',
                  icon: Icons.save_rounded,
                  isLoading: controller.isSaving.value,
                  height: 44,
                  onPressed: () => _handleSave(controller),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // HELPER SECTION TITLE
  // -------------------------------------------------------------
  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isRequired = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
        ],
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // HELPER: UPLOAD FOTO KEGIATAN PEMBELAJARAN
  // -------------------------------------------------------------
  Widget _buildPhotoUploadSection(BuildContext context, JournalController controller, bool isDesktop) {
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    return Obx(() {
      final hasLocalPhoto = controller.selectedPhotoBytes.value != null;
      final hasServerPhoto = controller.existingPhotoUrl.value != null && controller.existingPhotoUrl.value!.isNotEmpty;
      final hasPhoto = hasLocalPhoto || hasServerPhoto;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.photo_camera_back_rounded,
            title: 'Foto Kegiatan',
            subtitle: '(Opsional)',
          ),
          const SizedBox(height: 10),
          if (hasPhoto)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  InkWell(
                    onTap: () {
                      _showImagePreviewDialog(
                        context,
                        bytes: controller.selectedPhotoBytes.value,
                        url: controller.existingPhotoUrl.value,
                        title: 'Foto Kegiatan: ${widget.session.namaMapel}',
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: 190,
                      child: hasLocalPhoto
                          ? Image.memory(
                              controller.selectedPhotoBytes.value!,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              AppImageHelper.resolveImageUrl(controller.existingPhotoUrl.value) ??
                                  controller.existingPhotoUrl.value!,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Center(
                                child: Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey.shade400),
                              ),
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                              },
                            ),
                    ),
                  ),

                  // Floating Actions (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 17),
                            tooltip: 'Ganti Foto',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(5),
                            onPressed: () => controller.showPhotoSourceSelection(context),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFCA5A5), size: 17),
                            tooltip: 'Hapus',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(5),
                            onPressed: () => controller.removePhoto(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Zoom Indicator (Bottom Right)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 15),
                    ),
                  ),

                  // File Name (Bottom Left)
                  if (controller.selectedPhotoName.value != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 45,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          controller.selectedPhotoName.value!,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(
                      isMobile ? Icons.camera_alt_rounded : Icons.videocam_rounded,
                      size: 15,
                    ),
                    label: Text(isMobile ? 'Kamera HP' : 'Webcam'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => controller.pickPhotoFromCamera(context),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_rounded, size: 15),
                    label: const Text('Galeri / File'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMain,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => controller.pickPhotoFromFile(),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  void _showImagePreviewDialog(
    BuildContext context, {
    Uint8List? bytes,
    String? url,
    String? title,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.image_rounded, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title ?? 'Foto Dokumentasi Kegiatan',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                    child: bytes != null
                        ? Image.memory(bytes, fit: BoxFit.contain)
                        : Image.network(
                            AppImageHelper.resolveImageUrl(url) ?? url!,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Center(
                              child: Text('Gagal memuat foto', style: TextStyle(color: Colors.white70)),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
