import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/responsive/responsive_layout.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../controllers/attendance_controller.dart';
import '../../main_navigation/controllers/navigation_controller.dart';
import '../../journal/controllers/journal_controller.dart';

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AttendanceController());

    return Obx(() {
      if (controller.isLoading.value && controller.attendances.isEmpty) {
        return const Scaffold(body: LoadingIndicator(message: 'Memuat data siswa kelas...'));
      }

      final schedule = controller.selectedSchedule.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ResponsiveContainer(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Schedule Selector Card
                _buildScheduleSelectorCard(context, controller),
                const SizedBox(height: 16),

                // Live Summary Counters Card
                _buildSummaryCounterCard(controller),
                const SizedBox(height: 20),

                // Attendance List/Table
                if (controller.attendances.isEmpty)
                  const EmptyStateWidget(
                    title: 'Tidak Ada Siswa',
                    message: 'Silakan pilih jadwal untuk memuat daftar siswa kelas.',
                  )
                else
                  _buildAttendanceList(context, controller),

                const SizedBox(height: 24),

                // Bottom Action Buttons
                _buildBottomActions(context, controller, schedule),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildScheduleSelectorCard(BuildContext context, AttendanceController controller) {
    final schedule = controller.selectedSchedule.value;

    return Card(
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text(
                  'Presensi Kehadiran Siswa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormatter.getTodayFormatted(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Dropdown Selector for Schedule
            DropdownButtonFormField<int>(
              initialValue: schedule?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pilih Jadwal Mengajar',
                prefixIcon: Icon(Icons.calendar_month, color: AppColors.primary),
              ),
              items: controller.schedules.map((s) {
                return DropdownMenuItem<int>(
                  value: s.id,
                  child: Text(
                    '${s.hari} (${s.jamMulai}-${s.jamSelesai}) - ${s.namaKelas} - ${s.namaMapel}${s.namaGuru != null ? " [${s.namaGuru}]" : ""}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  final matched = controller.schedules.firstWhere((s) => s.id == val);
                  controller.selectSchedule(matched);
                }
              },
            ),

            if (schedule != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (schedule.namaGuru != null)
                    _infoChip(Icons.person_outline, 'Guru: ${schedule.namaGuru}'),
                  _infoChip(Icons.meeting_room_outlined, 'Kelas: ${schedule.namaKelas}'),
                  _infoChip(Icons.book_outlined, 'Mapel: ${schedule.namaMapel}'),
                  _infoChip(Icons.access_time, 'Jam: ${schedule.jamMulai} - ${schedule.jamSelesai}'),
                  _infoChip(Icons.people_outline, 'Total: ${controller.attendances.length} Siswa'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCounterCard(AttendanceController controller) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text(
                  'Rekap Status Kehadiran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: controller.markAllPresent,
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Hadir Semua'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _counterBadge(
                    'Hadir',
                    '${controller.countHadir}',
                    AppColors.success,
                    AppColors.successSubtle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _counterBadge(
                    'Izin',
                    '${controller.countIzin}',
                    AppColors.warning,
                    AppColors.warningSubtle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _counterBadge(
                    'Sakit',
                    '${controller.countSakit}',
                    AppColors.info,
                    AppColors.infoSubtle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _counterBadge(
                    'Alpa',
                    '${controller.countAlpa}',
                    AppColors.error,
                    AppColors.errorSubtle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterBadge(String label, String count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(BuildContext context, AttendanceController controller) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      // Table Layout for Web / Desktop
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 900),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.background),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                  fontSize: 13,
                ),
                dataRowMinHeight: 56,
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('NO')),
                  DataColumn(label: Text('NIS')),
                  DataColumn(label: Text('NAMA SISWA')),
                  DataColumn(label: Text('STATUS KEHADIRAN')),
                  DataColumn(label: Text('KETERANGAN')),
                ],
                rows: controller.attendances.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final att = entry.value;

                  return DataRow(
                    cells: [
                      DataCell(Text('${idx + 1}', style: const TextStyle(color: AppColors.textMuted))),
                      DataCell(Text(att.nis, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(
                        Text(
                          att.namaSiswa,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMain),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: ['Hadir', 'Izin', 'Sakit', 'Alpa'].map((st) {
                            final isSel = att.status == st;
                            Color c = AppColors.primary;
                            if (st == 'Hadir') c = AppColors.success;
                            if (st == 'Izin') c = AppColors.warning;
                            if (st == 'Sakit') c = AppColors.info;
                            if (st == 'Alpa') c = AppColors.error;

                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text(st),
                                selected: isSel,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSel ? Colors.white : c,
                                ),
                                selectedColor: c,
                                backgroundColor: c.withValues(alpha: 0.1),
                                side: BorderSide(color: isSel ? c : c.withValues(alpha: 0.3)),
                                showCheckmark: false,
                                onSelected: (_) => controller.updateStudentStatus(idx, st),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: TextFormField(
                            initialValue: att.keterangan,
                            decoration: const InputDecoration(
                              hintText: 'Keterangan...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 12),
                            onChanged: (val) => controller.updateStudentKeterangan(idx, val),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    } else {
      // Mobile List
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.attendances.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final att = controller.attendances[index];

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              att.namaSiswa,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'NIS: ${att.nis}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Segmented Status Chips
                  Row(
                    children: ['Hadir', 'Izin', 'Sakit', 'Alpa'].map((st) {
                      final isSel = att.status == st;
                      Color c = AppColors.primary;
                      if (st == 'Hadir') c = AppColors.success;
                      if (st == 'Izin') c = AppColors.warning;
                      if (st == 'Sakit') c = AppColors.info;
                      if (st == 'Alpa') c = AppColors.error;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: InkWell(
                            onTap: () => controller.updateStudentStatus(index, st),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSel ? c : c.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel ? c : c.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                st,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSel ? Colors.white : c,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildBottomActions(BuildContext context, AttendanceController controller, dynamic schedule) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;
        final saveBtn = CustomButton(
          text: 'Simpan Kehadiran',
          icon: Icons.save,
          isLoading: controller.isSaving.value,
          onPressed: controller.saveAttendance,
        );
        final journalBtn = CustomButton(
          text: 'Lanjut Isi Jurnal',
          type: ButtonType.secondary,
          icon: Icons.arrow_forward,
          onPressed: () {
            if (schedule != null) {
              final jourCtrl = Get.put(JournalController());
              jourCtrl.populateFromSchedule(schedule);
              jourCtrl.setAttendanceFromCurrent(controller.attendances);
            }
            final navCtrl = Get.find<NavigationController>();
            navCtrl.changeIndex(3); // Switch to Journal
          },
        );

        if (isNarrow) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: saveBtn),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: journalBtn),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: saveBtn),
            const SizedBox(width: 12),
            Expanded(child: journalBtn),
          ],
        );
      },
    );
  }
}
