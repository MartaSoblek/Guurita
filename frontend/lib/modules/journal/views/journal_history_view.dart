import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/responsive/responsive_layout.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../main_navigation/controllers/navigation_controller.dart';
import '../controllers/journal_controller.dart';
import 'journal_detail_view.dart';

class JournalHistoryView extends StatelessWidget {
  const JournalHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JournalController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(body: LoadingIndicator(message: 'Memuat riwayat jurnal...'));
      }

      return RefreshIndicator(
        onRefresh: controller.loadJournalHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: ResponsiveContainer(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search & Filter Toolbar
                _buildFilterToolbar(context, controller),
                const SizedBox(height: 20),

                // Journals List / Table
                if (controller.historyJournals.isEmpty)
                  EmptyStateWidget(
                    title: 'Tidak Ada Jurnal Ditemukan',
                    message: 'Tidak ada data jurnal mengajar yang sesuai dengan filter pencarian.',
                    actionText: 'Reset Filter',
                    onAction: controller.clearFilters,
                  )
                else
                  _buildJournalList(context, controller),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFilterToolbar(BuildContext context, JournalController controller) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

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
            if (isDesktop)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari materi, guru, kelas, atau mapel...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: controller.searchJournals,
                    ),
                  ),
                  if (controller.isAdmin.value) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: Obx(
                        () => DropdownButtonFormField<int?>(
                          initialValue: controller.selectedFilterGuru.value,
                          decoration: const InputDecoration(
                            labelText: 'Filter Guru',
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Semua Guru')),
                            ...controller.guruList.map(
                              (g) => DropdownMenuItem(value: g.id, child: Text(g.nama)),
                            ),
                          ],
                          onChanged: (val) {
                            controller.filterByGuru(val);
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: Obx(
                      () => DropdownButtonFormField<int?>(
                        initialValue: controller.selectedFilterClass.value,
                        decoration: const InputDecoration(
                          labelText: 'Filter Kelas',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Semua Kelas')),
                          ...controller.classList.map(
                            (c) => DropdownMenuItem(value: c.id, child: Text(c.namaKelas)),
                          ),
                        ],
                        onChanged: (val) {
                          controller.selectedFilterClass.value = val;
                          controller.loadJournalHistory();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    tooltip: 'Muat Ulang',
                    onPressed: controller.loadJournalHistory,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Isi Jurnal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: () {
                      if (Get.isRegistered<NavigationController>()) {
                        Get.find<NavigationController>().changeIndex(3);
                      }
                    },
                  ),
                ],
              )
            else ...[
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari materi, guru, kelas, atau mapel...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: controller.searchJournals,
              ),
              if (controller.isAdmin.value) ...[
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<int?>(
                    initialValue: controller.selectedFilterGuru.value,
                    decoration: const InputDecoration(
                      labelText: 'Filter Guru',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua Guru')),
                      ...controller.guruList.map(
                        (g) => DropdownMenuItem(value: g.id, child: Text(g.nama)),
                      ),
                    ],
                    onChanged: (val) {
                      controller.filterByGuru(val);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Obx(
                () => DropdownButtonFormField<int?>(
                  initialValue: controller.selectedFilterClass.value,
                  decoration: const InputDecoration(
                    labelText: 'Filter Kelas',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Kelas')),
                    ...controller.classList.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.namaKelas)),
                    ),
                  ],
                  onChanged: (val) {
                    controller.selectedFilterClass.value = val;
                    controller.loadJournalHistory();
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Muat Ulang'),
                      onPressed: controller.loadJournalHistory,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('Isi Jurnal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (Get.isRegistered<NavigationController>()) {
                          Get.find<NavigationController>().changeIndex(3);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJournalList(BuildContext context, JournalController controller) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      // Data Table for Desktop
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
              constraints: const BoxConstraints(minWidth: 960),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.background),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                  fontSize: 13,
                ),
                dataRowMinHeight: 64,
                dataRowMaxHeight: 70,
                columns: const [
                  DataColumn(label: Text('TANGGAL')),
                  DataColumn(label: Text('KELAS & MAPEL')),
                  DataColumn(label: Text('GURU PENGAMPU')),
                  DataColumn(label: Text('MATERI PEMBAHASAN')),
                  DataColumn(label: Text('PRESENSI (H/I/S/A)')),
                  DataColumn(label: Text('AKSI')),
                ],
                rows: controller.historyJournals.map((journal) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          DateFormatter.formatShortDate(journal.tanggal),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              journal.namaKelas ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              journal.namaMapel ?? '-',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          journal.namaGuru ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                journal.materi,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (journal.hasFotoKegiatan) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo_camera_rounded, size: 12, color: Colors.blue.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Ada Foto Kegiatan',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            _miniBadge('H: ${journal.totalHadir}', AppColors.success),
                            const SizedBox(width: 4),
                            _miniBadge('I: ${journal.totalIzin}', AppColors.warning),
                            const SizedBox(width: 4),
                            _miniBadge('S: ${journal.totalSakit}', AppColors.info),
                            const SizedBox(width: 4),
                            _miniBadge('A: ${journal.totalAlpa}', AppColors.error),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.primary),
                              tooltip: 'Lihat Detail',
                              onPressed: () {
                                Get.to(() => JournalDetailView(journal: journal));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                              tooltip: 'Hapus Jurnal',
                              onPressed: () => controller.deleteJournal(journal.id),
                            ),
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
      // Mobile Cards
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.historyJournals.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final journal = controller.historyJournals[index];

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              onTap: () => Get.to(() => JournalDetailView(journal: journal)),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${journal.namaKelas} • ${journal.namaMapel}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (journal.hasFotoKegiatan) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo_camera_rounded, size: 11, color: Colors.blue.shade700),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Foto',
                                      style: TextStyle(
                                        fontSize: 10,
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
                        Text(
                          DateFormatter.formatIndonesianDate(journal.tanggal),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (journal.namaGuru != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Guru: ${journal.namaGuru}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      journal.materi,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      journal.kegiatan,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _miniBadge('H: ${journal.totalHadir}', AppColors.success),
                            const SizedBox(width: 4),
                            _miniBadge('I: ${journal.totalIzin}', AppColors.warning),
                            const SizedBox(width: 4),
                            _miniBadge('S: ${journal.totalSakit}', AppColors.info),
                            const SizedBox(width: 4),
                            _miniBadge('A: ${journal.totalAlpa}', AppColors.error),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          onPressed: () => controller.deleteJournal(journal.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
