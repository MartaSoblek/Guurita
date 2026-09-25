import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/responsive/responsive_layout.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/models/schedule_model.dart';
import '../controllers/schedule_controller.dart';
import '../../main_navigation/controllers/navigation_controller.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../journal/controllers/journal_controller.dart';
import '../../../data/services/auth_service.dart';

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScheduleController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(body: LoadingIndicator());
      }

      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: ResponsiveLayout.isMobile(context)
            ? FloatingActionButton.extended(
                onPressed: () => _showScheduleFormDialog(context, controller),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Jadwal'),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: controller.loadSchedules,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: ResponsiveContainer(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header & Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Jadwal Mengajar Guru',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMain,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Kelola jam KBM dan jadwal pelajaran per kelas',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showScheduleFormDialog(context, controller),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Jadwal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Admin Teacher Filter
                  if (controller.isAdmin.value) ...[
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        child: Row(
                          children: [
                            const Icon(Icons.person_search_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Guru:',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                initialValue: controller.selectedFilterGuru.value,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  hintText: 'Pilih Guru',
                                ),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('Semua Guru (Seluruh Jadwal)', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Day Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: controller.days.map((day) {
                        final isSelected = controller.selectedDay.value == day;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(day),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textMain,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                            backgroundColor: Colors.white,
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                            onSelected: (_) => controller.filterByDay(day),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Schedules List / Grid
                  if (controller.filteredSchedules.isEmpty)
                    const EmptyStateWidget(
                      title: 'Tidak Ada Jadwal',
                      message: 'Tidak ada jadwal mengajar pada hari yang dipilih. Klik tombol "+ Tambah Jadwal" untuk membuat jadwal baru.',
                    )
                  else
                    _buildScheduleList(context, controller),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildScheduleList(BuildContext context, ScheduleController controller) {
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
              constraints: const BoxConstraints(minWidth: 950),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.background),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                  fontSize: 13,
                ),
                dataRowMinHeight: 64,
                dataRowMaxHeight: 68,
                columns: const [
                  DataColumn(label: Text('HARI')),
                  DataColumn(label: Text('WAKTU KBM')),
                  DataColumn(label: Text('KELAS')),
                  DataColumn(label: Text('MATA PELAJARAN')),
                  DataColumn(label: Text('GURU PENGAMPU')),
                  DataColumn(label: Text('AKSI')),
                ],
                rows: controller.filteredSchedules.map((schedule) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            schedule.hari,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${schedule.jamMulai} - ${schedule.jamSelesai}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Text(
                          schedule.namaKelas ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataCell(Text(schedule.namaMapel ?? '-')),
                      DataCell(Text(schedule.namaGuru ?? '-')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                final attCtrl = Get.put(AttendanceController());
                                attCtrl.selectSchedule(schedule);
                                final navCtrl = Get.find<NavigationController>();
                                navCtrl.changeIndex(2); // Kehadiran
                              },
                              icon: const Icon(Icons.how_to_reg, size: 14),
                              label: const Text('Presensi', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () {
                                final jourCtrl = Get.put(JournalController());
                                jourCtrl.populateFromSchedule(schedule);
                                final navCtrl = Get.find<NavigationController>();
                                navCtrl.changeIndex(3); // Jurnal
                              },
                              icon: const Icon(Icons.edit_note, size: 14),
                              label: const Text('Jurnal', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                            if (controller.canModifySchedule(schedule)) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                onPressed: () => _showScheduleFormDialog(context, controller, schedule: schedule),
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                tooltip: 'Edit Jadwal',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => controller.confirmDelete(schedule),
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                tooltip: 'Hapus Jadwal',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                              ),
                            ],
                          ],
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
      // Mobile Card List
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.filteredSchedules.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final schedule = controller.filteredSchedules[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          schedule.hari,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${schedule.jamMulai} - ${schedule.jamSelesai}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (controller.canModifySchedule(schedule)) ...[
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showScheduleFormDialog(context, controller, schedule: schedule);
                                } else if (val == 'delete') {
                                  controller.confirmDelete(schedule);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                      SizedBox(width: 8),
                                      Text('Edit Jadwal'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                      SizedBox(width: 8),
                                      Text('Hapus Jadwal', style: TextStyle(color: AppColors.error)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    schedule.namaMapel ?? 'Mata Pelajaran',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelas: ${schedule.namaKelas ?? "-"} • Pengampu: ${schedule.namaGuru ?? "-"}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final attCtrl = Get.put(AttendanceController());
                            attCtrl.selectSchedule(schedule);
                            final navCtrl = Get.find<NavigationController>();
                            navCtrl.changeIndex(2); // Kehadiran
                          },
                          icon: const Icon(Icons.how_to_reg, size: 16),
                          label: const Text('Presensi'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final jourCtrl = Get.put(JournalController());
                            jourCtrl.populateFromSchedule(schedule);
                            final navCtrl = Get.find<NavigationController>();
                            navCtrl.changeIndex(3); // Jurnal
                          },
                          icon: const Icon(Icons.edit_note, size: 16),
                          label: const Text('Jurnal'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _showScheduleFormDialog(BuildContext context, ScheduleController controller, {ScheduleModel? schedule}) {
    if (schedule == null) {
      controller.initCreateForm();
    } else {
      final allowed = controller.initEditForm(schedule);
      if (!allowed) return;
    }

    final isEdit = schedule != null;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_calendar_outlined : Icons.add_alarm_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEdit ? 'Edit Jadwal Mengajar' : 'Tambah Jadwal Mengajar',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Form Fields
                // 1. Guru Pengampu
                if (controller.isAdmin.value) ...[
                  const Text('Guru Pengampu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain)),
                  const SizedBox(height: 6),
                  Obx(() => DropdownButtonFormField<int>(
                    initialValue: controller.selectedGuruId.value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: controller.guruList.map((g) => DropdownMenuItem(
                      value: g.id,
                      child: Text('${g.nama} (${g.mataPelajaran ?? "Guru"})'),
                    )).toList(),
                    onChanged: (val) => controller.selectedGuruId.value = val,
                  )),
                  const SizedBox(height: 16),
                ] else ...[
                  const Text('Guru Pengampu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AuthService().currentUser?.nama ?? 'Guru Pengampu',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Akun Anda', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Hari
                const Text('Hari Mengajar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain)),
                const SizedBox(height: 6),
                Obx(() => DropdownButtonFormField<String>(
                  initialValue: controller.selectedHari.value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: controller.scheduleDays.map((h) => DropdownMenuItem(
                    value: h,
                    child: Text(h),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) controller.selectedHari.value = val;
                  },
                )),
                const SizedBox(height: 16),

                // 3. Kelas & Mata Pelajaran
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kelas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain)),
                          const SizedBox(height: 6),
                          Obx(() => DropdownButtonFormField<int>(
                            initialValue: controller.selectedKelasId.value,
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: controller.classList.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.namaKelas),
                            )).toList(),
                            onChanged: (val) => controller.selectedKelasId.value = val,
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain)),
                          const SizedBox(height: 6),
                          Obx(() => DropdownButtonFormField<int>(
                            initialValue: controller.selectedMapelId.value,
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: controller.subjectList.map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.namaMapel, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (val) => controller.selectedMapelId.value = val,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Jam Mulai & Jam Selesai
                const Text('Waktu KBM (Jam Mulai & Selesai)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.jamMulaiController,
                        decoration: InputDecoration(
                          hintText: '07:30',
                          labelText: 'Jam Mulai',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time, size: 20),
                            onPressed: () => controller.pickTime(context, true),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('—', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: controller.jamSelesaiController,
                        decoration: InputDecoration(
                          hintText: '09:00',
                          labelText: 'Jam Selesai',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time, size: 20),
                            onPressed: () => controller.pickTime(context, false),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Quick Presets
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _presetChip(controller, '07:30', '09:00', 'Sesi 1 (07:30-09:00)'),
                    _presetChip(controller, '09:15', '11:45', 'Sesi 2 (09:15-11:45)'),
                    _presetChip(controller, '12:15', '14:30', 'Sesi 3 (12:15-14:30)'),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    const SizedBox(width: 8),
                    Obx(() => ElevatedButton.icon(
                      onPressed: controller.isSaving.value ? null : controller.saveSchedule,
                      icon: controller.isSaving.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(controller.isSaving.value
                          ? 'Menyimpan...'
                          : (isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _presetChip(ScheduleController controller, String start, String end, String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.background,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onPressed: () {
        controller.jamMulaiController.text = start;
        controller.jamSelesaiController.text = end;
      },
    );
  }
}
