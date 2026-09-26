// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/responsive/responsive_layout.dart';
import '../../../core/widgets/dashboard_metric_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../controllers/report_controller.dart';

class ReportView extends StatelessWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: LoadingIndicator(message: 'Memuat rekapitulasi kehadiran...'),
        );
      }

      final isDesktop = ResponsiveLayout.isDesktop(context);

      return Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: controller.loadReport,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: ResponsiveContainer(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title & Action Bar
                  _buildHeaderBar(context, controller, isDesktop),
                  const SizedBox(height: 16),

                  // Filter Row Card
                  _buildFilterCard(context, controller, isDesktop),
                  const SizedBox(height: 20),

                  // Metric Statistics Grid
                  _buildMetricsGrid(context, controller, isDesktop),
                  const SizedBox(height: 24),

                  // Student Attendance Table Card
                  _buildStudentsTableCard(context, controller, isDesktop),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeaderBar(BuildContext context, ReportController controller, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final titleCol = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rekapitulasi Kehadiran',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${controller.namaKelas.value} • ${controller.namaMapel.value} • ${controller.selectedMonthName} ${controller.selectedYear.value}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showPrintPreviewDialog(context, controller),
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Cetak'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMain,
                backgroundColor: AppColors.card,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: controller.exportCsv,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Ekspor CSV'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleCol,
              const SizedBox(height: 14),
              actionButtons,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleCol),
            const SizedBox(width: 14),
            actionButtons,
          ],
        );
      },
    );
  }

  Widget _buildBulanDropdown(ReportController controller) {
    return _buildDropdownWrapper(
      label: 'Bulan',
      child: DropdownButtonFormField<int>(
        value: controller.selectedMonth.value,
        isExpanded: true,
        decoration: _inputDecoration(),
        items: controller.months.map((m) {
          return DropdownMenuItem<int>(
            value: m['val'] as int,
            child: Text(m['name'] as String, style: const TextStyle(fontSize: 13)),
          );
        }).toList(),
        onChanged: controller.filterByMonth,
      ),
    );
  }

  Widget _buildTahunDropdown(ReportController controller) {
    return _buildDropdownWrapper(
      label: 'Tahun',
      child: DropdownButtonFormField<int>(
        value: controller.selectedYear.value,
        isExpanded: true,
        decoration: _inputDecoration(),
        items: controller.years.map((y) {
          return DropdownMenuItem<int>(
            value: y,
            child: Text('$y', style: const TextStyle(fontSize: 13)),
          );
        }).toList(),
        onChanged: controller.filterByYear,
      ),
    );
  }

  Widget _buildKelasDropdown(ReportController controller) {
    return _buildDropdownWrapper(
      label: 'Kelas',
      child: DropdownButtonFormField<int?>(
        value: controller.selectedClass.value,
        isExpanded: true,
        decoration: _inputDecoration(),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Semua Kelas', style: TextStyle(fontSize: 13)),
          ),
          ...controller.classList.map((c) {
            return DropdownMenuItem<int?>(
              value: c.id,
              child: Text(c.namaKelas, style: const TextStyle(fontSize: 13)),
            );
          }),
        ],
        onChanged: controller.filterByClass,
      ),
    );
  }

  Widget _buildMapelDropdown(ReportController controller) {
    return _buildDropdownWrapper(
      label: 'Mata Pelajaran',
      child: DropdownButtonFormField<int?>(
        value: controller.selectedSubject.value,
        isExpanded: true,
        decoration: _inputDecoration(),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Semua Mapel', style: TextStyle(fontSize: 13)),
          ),
          ...controller.subjectList.map((s) {
            return DropdownMenuItem<int?>(
              value: s.id,
              child: Text(s.namaMapel, style: const TextStyle(fontSize: 13)),
            );
          }),
        ],
        onChanged: controller.filterBySubject,
      ),
    );
  }

  Widget _buildGuruDropdown(ReportController controller) {
    return _buildDropdownWrapper(
      label: 'Guru Pengampu',
      child: DropdownButtonFormField<int?>(
        value: controller.selectedGuru.value,
        isExpanded: true,
        decoration: _inputDecoration(),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Semua Guru', style: TextStyle(fontSize: 13)),
          ),
          ...controller.guruList.map((g) {
            return DropdownMenuItem<int?>(
              value: g.id,
              child: Text(g.nama, style: const TextStyle(fontSize: 13)),
            );
          }),
        ],
        onChanged: controller.filterByGuru,
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, ReportController controller, bool isDesktop) {
    return Card(
      elevation: 0,
      color: AppColors.card,
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
              children: [
                const Icon(Icons.tune_rounded, size: 18, color: AppColors.textMain),
                const SizedBox(width: 8),
                const Text(
                  'Filter Laporan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textMuted),
                  tooltip: 'Segarkan Data',
                  onPressed: controller.loadReport,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 960;
                final isMedium = constraints.maxWidth >= 560 && !isWide;

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(flex: 2, child: _buildBulanDropdown(controller)),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _buildTahunDropdown(controller)),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: _buildKelasDropdown(controller)),
                      const SizedBox(width: 12),
                      Expanded(flex: 4, child: _buildMapelDropdown(controller)),
                      if (controller.isAdmin.value) ...[
                        const SizedBox(width: 12),
                        Expanded(flex: 4, child: _buildGuruDropdown(controller)),
                      ],
                    ],
                  );
                } else if (isMedium) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildBulanDropdown(controller)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTahunDropdown(controller)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildKelasDropdown(controller)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildMapelDropdown(controller)),
                          if (controller.isAdmin.value) ...[
                            const SizedBox(width: 12),
                            Expanded(child: _buildGuruDropdown(controller)),
                          ],
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildBulanDropdown(controller)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTahunDropdown(controller)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildKelasDropdown(controller),
                      const SizedBox(height: 10),
                      _buildMapelDropdown(controller),
                      if (controller.isAdmin.value) ...[
                        const SizedBox(height: 10),
                        _buildGuruDropdown(controller),
                      ],
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownWrapper({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, ReportController controller, bool isDesktop) {
    final metrics = [
      DashboardMetricCard(
        title: 'Total Siswa',
        value: '${controller.totalSiswa.value}',
        subtitle: 'Siswa terdaftar',
        icon: Icons.groups_outlined,
        accentColor: AppColors.primary,
        backgroundColor: AppColors.primarySubtle,
      ),
      DashboardMetricCard(
        title: 'Sesi Pertemuan',
        value: '${controller.totalPertemuan.value}',
        subtitle: 'Jurnal terlaksana',
        icon: Icons.event_available_outlined,
        accentColor: const Color(0xFF8B5CF6),
        backgroundColor: const Color(0xFFF5F3FF),
      ),
      DashboardMetricCard(
        title: 'Tingkat Kehadiran',
        value: '${controller.persentaseHadir.value}%',
        subtitle: 'Rata-rata presensi',
        icon: Icons.pie_chart_outline,
        accentColor: AppColors.success,
        backgroundColor: AppColors.successSubtle,
      ),
      DashboardMetricCard(
        title: 'Total Hadir',
        value: '${controller.totalHadir.value}',
        subtitle: 'Presensi hadir',
        icon: Icons.check_circle_outline,
        accentColor: AppColors.success,
        backgroundColor: AppColors.successSubtle,
      ),
      DashboardMetricCard(
        title: 'Izin & Sakit',
        value: '${controller.totalIzin.value + controller.totalSakit.value}',
        subtitle: 'Izin: ${controller.totalIzin.value} • Sakit: ${controller.totalSakit.value}',
        icon: Icons.info_outline,
        accentColor: AppColors.warning,
        backgroundColor: AppColors.warningSubtle,
      ),
      DashboardMetricCard(
        title: 'Alpa / Tanpa Ket.',
        value: '${controller.totalAlpa.value}',
        subtitle: 'Tanpa konfirmasi',
        icon: Icons.cancel_outlined,
        accentColor: AppColors.error,
        backgroundColor: AppColors.errorSubtle,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;

        if (width >= 1100) {
          crossAxisCount = 6;
          childAspectRatio = 1.1;
        } else if (width >= 800) {
          crossAxisCount = 3;
          childAspectRatio = 1.4;
        } else if (width >= 500) {
          crossAxisCount = 2;
          childAspectRatio = 1.4;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 1.15;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          children: metrics,
        );
      },
    );
  }

  Widget _buildStudentsTableCard(BuildContext context, ReportController controller, bool isDesktop) {
    final list = controller.filteredStudents;

    return Card(
      elevation: 0,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls: Search, Sort, Total Count
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      onChanged: (val) => controller.searchQuery.value = val,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari nama siswa atau NIS...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSubtle),
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                        suffixIcon: controller.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => controller.searchQuery.value = '',
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (isDesktop) ...[
                  SizedBox(
                    height: 40,
                    width: 170,
                    child: DropdownButtonFormField<String>(
                      value: controller.sortBy.value,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: controller.sortOptions.map((opt) {
                        return DropdownMenuItem(
                          value: opt,
                          child: Text(opt, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.sortBy.value = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${list.length} Siswa',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (list.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 40, color: AppColors.textSubtle),
                    SizedBox(height: 8),
                    Text(
                      'Tidak ada data siswa ditemukan',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            else if (isDesktop)
              _buildDesktopTable(context, controller, list)
            else
              _buildMobileList(context, controller, list),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    ReportController controller,
    List<Map<String, dynamic>> list,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 920),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.background),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
            fontSize: 12,
          ),
          dataRowMinHeight: 48,
          columns: const [
            DataColumn(label: Text('NO')),
            DataColumn(label: Text('NIS')),
            DataColumn(label: Text('NAMA SISWA')),
            DataColumn(label: Text('HADIR')),
            DataColumn(label: Text('IZIN')),
            DataColumn(label: Text('SAKIT')),
            DataColumn(label: Text('ALPA')),
            DataColumn(label: Text('PERSENTASE')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('DETAIL')),
          ],
          rows: list.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final persen = (item['persen'] ?? 0.0) as double;
            final evaluasi = item['evaluasi'] ?? 'Baik';

            return DataRow(
              cells: [
                DataCell(Text('${idx + 1}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                DataCell(Text('${item['nis']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                DataCell(
                  Text(
                    '${item['nama']}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain),
                  ),
                ),
                DataCell(Text('${item['hadir']}', style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold))),
                DataCell(Text('${item['izin']}', style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.bold))),
                DataCell(Text('${item['sakit']}', style: const TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.bold))),
                DataCell(Text('${item['alpa']}', style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: persen >= 90
                          ? AppColors.successSubtle
                          : (persen >= 75 ? AppColors.warningSubtle : AppColors.errorSubtle),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$persen%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: persen >= 90
                            ? AppColors.success
                            : (persen >= 75 ? AppColors.warning : AppColors.error),
                      ),
                    ),
                  ),
                ),
                DataCell(_buildStatusBadge(evaluasi)),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                    tooltip: 'Riwayat Sesi',
                    onPressed: () => _showStudentDetailDialog(context, controller, item),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    ReportController controller,
    List<Map<String, dynamic>> list,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = list[index];
        final persen = (item['persen'] ?? 0.0) as double;
        final evaluasi = item['evaluasi'] ?? 'Baik';

        return InkWell(
          onTap: () => _showStudentDetailDialog(context, controller, item),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['nama']}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIS: ${item['nis']}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildMiniCounter('H', item['hadir'] ?? 0, AppColors.success),
                          _buildMiniCounter('I', item['izin'] ?? 0, AppColors.warning),
                          _buildMiniCounter('S', item['sakit'] ?? 0, AppColors.info),
                          _buildMiniCounter('A', item['alpa'] ?? 0, AppColors.error),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: persen >= 90
                            ? AppColors.successSubtle
                            : (persen >= 75 ? AppColors.warningSubtle : AppColors.errorSubtle),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$persen%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: persen >= 90
                              ? AppColors.success
                              : (persen >= 75 ? AppColors.warning : AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(evaluasi),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniCounter(String label, int val, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
        ),
        Text(
          '$val',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String evaluasi) {
    Color bg;
    Color fg;

    switch (evaluasi) {
      case 'Sangat Baik':
        bg = AppColors.successSubtle;
        fg = AppColors.success;
        break;
      case 'Baik':
        bg = AppColors.primarySubtle;
        fg = AppColors.primary;
        break;
      case 'Cukup':
        bg = AppColors.warningSubtle;
        fg = AppColors.warning;
        break;
      case 'Perlu Perhatian':
      default:
        bg = AppColors.errorSubtle;
        fg = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        evaluasi,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  void _showStudentDetailDialog(
    BuildContext context,
    ReportController controller,
    Map<String, dynamic> student,
  ) {
    final history = List<Map<String, dynamic>>.from(student['history'] ?? []);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${student['nama']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMain),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIS: ${student['nis']} • ${controller.namaKelas.value}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(student['evaluasi'] ?? 'Baik'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              const Text(
                'Riwayat Kehadiran Per Sesi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 8),
              if (history.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: const Text(
                    'Belum ada rincian riwayat sesi pertemuan.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final h = history[idx];
                      final status = h['status'] ?? '-';
                      final tanggal = h['tanggal'] ?? '-';
                      final materi = h['materi'] ?? 'Materi Pembelajaran';
                      final ket = h['keterangan'];

                      Color statusColor = AppColors.textMuted;
                      if (status == 'Hadir') statusColor = AppColors.success;
                      if (status == 'Izin') statusColor = AppColors.warning;
                      if (status == 'Sakit') statusColor = AppColors.info;
                      if (status == 'Alpa') statusColor = AppColors.error;

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$tanggal • $materi',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMain),
                                  ),
                                  if (ket != null && ket.toString().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Catatan: $ket',
                                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$status',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrintPreviewDialog(BuildContext context, ReportController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 650),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Action Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pratinjau Lembar Rekap',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMain),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Printable Content Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Kop Surat Resmi
                        const Text(
                          'PEMERINTAH PROVINSI BALI',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                        ),
                        const Text(
                          'DINAS PENDIDIKAN KEPEMUDAAN DAN OLAHRAGA',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const Text(
                          'SMK NEGERI 1 ABANG',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                        const Text(
                          'Jalan Raya Culik - Amed, Abang, Karangasem, Bali 80852',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        const Divider(thickness: 2, color: Colors.black87),
                        const SizedBox(height: 12),

                        // Title
                        const Text(
                          'LAPORAN REKAPITULASI PRESENSI KEHADIRAN SISWA',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Periode: ${controller.selectedMonthName} ${controller.selectedYear.value}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 14),

                        // Metadata Grid
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetaItem('Kelas', controller.namaKelas.value),
                              _buildMetaItem('Mata Pelajaran', controller.namaMapel.value),
                              _buildMetaItem('Guru Pengampu', controller.namaGuru.value),
                              _buildMetaItem('Total Pertemuan', '${controller.totalPertemuan.value} Sesi'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Table of students
                        Table(
                          border: TableBorder.all(color: Colors.black26, width: 0.8),
                          columnWidths: const {
                            0: FixedColumnWidth(36),
                            1: FixedColumnWidth(70),
                            2: FlexColumnWidth(3),
                            3: FixedColumnWidth(40),
                            4: FixedColumnWidth(40),
                            5: FixedColumnWidth(40),
                            6: FixedColumnWidth(40),
                            7: FixedColumnWidth(55),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(color: Color(0xFFEEEEEE)),
                              children: [
                                _tableHeader('NO'),
                                _tableHeader('NIS'),
                                _tableHeader('NAMA SISWA'),
                                _tableHeader('H'),
                                _tableHeader('I'),
                                _tableHeader('S'),
                                _tableHeader('A'),
                                _tableHeader('%'),
                              ],
                            ),
                            ...controller.filteredStudents.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final s = entry.value;
                              return TableRow(
                                children: [
                                  _tableCell('${idx + 1}', align: TextAlign.center),
                                  _tableCell('${s['nis']}', align: TextAlign.center),
                                  _tableCell('${s['nama']}'),
                                  _tableCell('${s['hadir']}', align: TextAlign.center),
                                  _tableCell('${s['izin']}', align: TextAlign.center),
                                  _tableCell('${s['sakit']}', align: TextAlign.center),
                                  _tableCell('${s['alpa']}', align: TextAlign.center),
                                  _tableCell('${s['persen']}%', align: TextAlign.center, bold: true),
                                ],
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Signature block
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Mengetahui,', style: TextStyle(fontSize: 11)),
                                const Text('Kepala SMKN 1 Abang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 48),
                                const Text('I Wayan Sugiartha, S.Pd., M.Pd.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const Text('NIP. 19740510 200003 1 004', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('Abang, ${DateTime.now().day} ${controller.selectedMonthName} ${controller.selectedYear.value}', style: const TextStyle(fontSize: 11)),
                                const Text('Guru Mata Pelajaran', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 48),
                                Text(controller.namaGuru.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const Text('NIP. Guru Pengampu', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Dialog Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      controller.copyCsvToClipboard();
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Salin Data CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMain,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      controller.printReport();
                    },
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('Cetak Sekarang (Print / PDF)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _tableCell(String text, {TextAlign align = TextAlign.left, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
    );
  }
}
