import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/responsive/responsive_layout.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_model.dart';
import '../controllers/class_controller.dart';

class ClassView extends StatelessWidget {
  const ClassView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClassController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(body: LoadingIndicator(message: 'Memuat data kelas...'));
      }

      // If a class is clicked/selected, render the Student Detail View for that class
      if (controller.selectedClass.value != null) {
        return _buildClassDetailStudentView(context, controller, controller.selectedClass.value!);
      }

      // Default: render list of classes
      return _buildClassListView(context, controller);
    });
  }

  // =========================================================================
  // VIEW 1: DAFTAR KELAS (CLASS LIST)
  // =========================================================================

  Widget _buildClassListView(BuildContext context, ClassController controller) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: (ResponsiveLayout.isMobile(context) && controller.isAdmin.value)
          ? FloatingActionButton.extended(
              onPressed: () => _showClassFormDialog(context, controller),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kelas'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: controller.loadClasses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: ResponsiveContainer(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    final titleWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Data Kelas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMain,
                              ),
                            ),
                            if (controller.isAdmin.value) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  'Kelola Admin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Klik kelas untuk melihat dan mengelola data siswa di dalamnya',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    );

                    final addBtn = controller.isAdmin.value
                        ? ElevatedButton.icon(
                            onPressed: () => _showClassFormDialog(context, controller),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Tambah Kelas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          )
                        : const SizedBox.shrink();

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleWidget,
                          if (controller.isAdmin.value) ...[
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, child: addBtn),
                          ],
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: titleWidget),
                        if (controller.isAdmin.value) ...[
                          const SizedBox(width: 12),
                          addBtn,
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Summary Stat Cards
                _buildStatCards(context, controller),
                const SizedBox(height: 20),

                // Search & Filter Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 500;
                      final searchField = TextField(
                        onChanged: (val) => controller.searchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: 'Cari nama kelas atau tingkat...',
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      );

                      final dropdown = Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.selectedTingkatFilter.value,
                                isExpanded: isNarrow,
                                items: ['Semua', 'X', 'XI', 'XII'].map((t) {
                                  return DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                      t == 'Semua' ? 'Semua Tingkat' : 'Tingkat $t',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.selectedTingkatFilter.value = val;
                                  }
                                },
                              ),
                            ),
                          ));

                      if (isNarrow) {
                        return Column(
                          children: [
                            searchField,
                            const SizedBox(height: 10),
                            SizedBox(width: double.infinity, child: dropdown),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: searchField),
                          const SizedBox(width: 12),
                          dropdown,
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Content: Table or Cards
                if (controller.filteredClasses.isEmpty)
                  EmptyStateWidget(
                    icon: Icons.meeting_room_outlined,
                    title: 'Tidak Ada Data Kelas',
                    message: controller.searchQuery.value.isNotEmpty
                        ? 'Tidak ditemukan kelas yang cocok dengan kata kunci pencarian.'
                        : 'Belum ada kelas terdaftar dalam sistem.',
                    actionText: controller.isAdmin.value ? 'Tambah Kelas Sekarang' : null,
                    onAction: controller.isAdmin.value
                        ? () => _showClassFormDialog(context, controller)
                        : null,
                  )
                else if (ResponsiveLayout.isMobile(context))
                  _buildMobileClassList(context, controller)
                else
                  _buildDesktopTable(context, controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, ClassController controller) {
    final total = controller.classes.length;
    final totalX = controller.classes.where((c) => c.tingkat == 'X').length;
    final totalXI = controller.classes.where((c) => c.tingkat == 'XI').length;
    final totalXII = controller.classes.where((c) => c.tingkat == 'XII').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final cardWidth = isSmall ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              title: 'Total Kelas',
              count: total.toString(),
              icon: Icons.meeting_room,
              color: AppColors.primary,
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Tingkat X',
              count: totalX.toString(),
              icon: Icons.looks_one,
              color: Colors.blue.shade700,
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Tingkat XI',
              count: totalXI.toString(),
              icon: Icons.looks_two,
              color: Colors.orange.shade700,
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Tingkat XII',
              count: totalXII.toString(),
              icon: Icons.looks_3,
              color: Colors.purple.shade700,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: const TextStyle(fontSize: 18, color: AppColors.textMain, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, ClassController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2.5),
            4: FlexColumnWidth(2),
            5: FixedColumnWidth(160),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('Nama Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('Tingkat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('Total Siswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('Jadwal Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('Aksi & Detail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                ),
              ],
            ),
            // Rows
            ...controller.filteredClasses.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final cls = entry.value;

              return TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text('$idx', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ),
                  InkWell(
                    onTap: () => controller.selectClass(cls),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        cls.namaKelas,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain, // Clean standard text, no hyperlink underline
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildTingkatBadge(cls.tingkat),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: InkWell(
                      onTap: () => controller.selectClass(cls),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_alt, size: 15, color: Colors.blue.shade700),
                            const SizedBox(width: 6),
                            Text(
                              '${cls.totalSiswa} Siswa (Kelola)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue.shade800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          '${cls.totalJadwal} Jadwal',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.groups, size: 19, color: AppColors.primary),
                          tooltip: 'Lihat Siswa Kelas ${cls.namaKelas}',
                          onPressed: () => controller.selectClass(cls),
                        ),
                        if (controller.isAdmin.value) ...[
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                            tooltip: 'Edit Kelas',
                            onPressed: () => _showClassFormDialog(context, controller, cls: cls),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            tooltip: 'Hapus Kelas',
                            onPressed: () => controller.confirmDelete(cls),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileClassList(BuildContext context, ClassController controller) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.filteredClasses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cls = controller.filteredClasses[index];

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => controller.selectClass(cls),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              cls.namaKelas,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMain, // Clean standard text, no hyperlink
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildTingkatBadge(cls.tingkat),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people, size: 14, color: Colors.blue.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cls.totalSiswa} Siswa',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue.shade800),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today, size: 13, color: Colors.purple.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cls.totalJadwal} Jadwal',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purple.shade800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 22),
                      if (controller.isAdmin.value) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 19, color: AppColors.textMuted),
                          tooltip: 'Edit Kelas',
                          onPressed: () => _showClassFormDialog(context, controller, cls: cls),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 19, color: Colors.red),
                          tooltip: 'Hapus Kelas',
                          onPressed: () => controller.confirmDelete(cls),
                        ),
                      ],
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

  Widget _buildTingkatBadge(String tingkat) {
    Color bg;
    Color fg;
    switch (tingkat.toUpperCase()) {
      case 'X':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
      case 'XI':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
      case 'XII':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade800;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withAlpha(75)),
      ),
      child: Text(
        'Kelas $tingkat',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  void _showClassFormDialog(BuildContext context, ClassController controller, {ClassModel? cls}) {
    if (cls != null) {
      controller.openEditDialog(cls);
    } else {
      controller.openCreateDialog();
    }

    final isEdit = cls != null;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.meeting_room, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Data Kelas' : 'Tambah Kelas Baru',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textMain),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 20),

              // Nama Kelas field
              const Text(
                'Nama Kelas',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller.namaKelasController,
                decoration: InputDecoration(
                  hintText: 'Misal: X TKJ, XI RPL 1, XII TKJ 2',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Tingkat dropdown
              const Text(
                'Tingkat Jenjang',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 6),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedTingkat.value,
                        isExpanded: true,
                        items: controller.tingkatOptions.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text('Tingkat $t (Kelas $t)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.selectedTingkat.value = val;
                          }
                        },
                      ),
                    ),
                  )),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  Obx(() => ElevatedButton(
                        onPressed: controller.isSaving.value ? null : controller.saveClass,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: controller.isSaving.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Kelas'),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // VIEW 2: DETAIL KELAS & CRUD SISWA (STUDENT LIST & CRUD)
  // =========================================================================

  Widget _buildClassDetailStudentView(
    BuildContext context,
    ClassController controller,
    ClassModel cls,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: (ResponsiveLayout.isMobile(context) && controller.isAdmin.value)
          ? FloatingActionButton.extended(
              onPressed: () => _showStudentFormDialog(context, controller, cls),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah Siswa'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: controller.loadStudentsForSelectedClass,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: ResponsiveContainer(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Bar (Back button & Breadcrumb)
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: controller.backToClassList,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Daftar Kelas'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text('/', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                    const SizedBox(width: 14),
                    Text(
                      'Siswa ${cls.namaKelas}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Class Header & Action Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 750;

                      final titleSection = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Daftar Siswa Kelas ${cls.namaKelas}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textMain,
                                ),
                              ),
                              _buildTingkatBadge(cls.tingkat),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Obx(() => Text(
                                'Total ${controller.students.length} siswa terdaftar di rombongan belajar ini',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              )),
                        ],
                      );

                      final actionButtons = controller.isAdmin.value
                          ? Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => controller.downloadTemplateFile(format: 'xlsx'),
                                  icon: const Icon(Icons.file_download_outlined, size: 18, color: AppColors.primary),
                                  label: const Text('Unduh Template', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.primary),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _showImportExcelDialog(context, controller, cls),
                                  icon: const Icon(Icons.upload_file, size: 18, color: Colors.green),
                                  label: const Text('Import Excel', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.green.shade400),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showStudentFormDialog(context, controller, cls),
                                  icon: const Icon(Icons.person_add, size: 18),
                                  label: const Text('Tambah Siswa'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink();

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleSection,
                            if (controller.isAdmin.value) ...[
                              const SizedBox(height: 14),
                              actionButtons,
                            ],
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: titleSection),
                          if (controller.isAdmin.value) ...[
                            const SizedBox(width: 16),
                            actionButtons,
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Student Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: (val) => controller.studentSearchQuery.value = val,
                    decoration: InputDecoration(
                      hintText: 'Cari siswa berdasarkan nama, NIS, atau NISN...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                const SizedBox(height: 16),

                // Students Content
                Obx(() {
                  if (controller.isLoadingStudents.value) {
                    return const LoadingIndicator(message: 'Memuat data siswa kelas...');
                  }

                  if (controller.filteredStudents.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.groups_outlined,
                      title: 'Tidak Ada Siswa Ditemukan',
                      message: controller.studentSearchQuery.value.isNotEmpty
                          ? 'Tidak ada siswa yang cocok dengan kata kunci pencarian.'
                          : 'Belum ada siswa terdaftar pada kelas ${cls.namaKelas}.',
                      actionText: controller.isAdmin.value ? 'Tambah Siswa Pertama' : null,
                      onAction: controller.isAdmin.value
                          ? () => _showStudentFormDialog(context, controller, cls)
                          : null,
                    );
                  }

                  if (ResponsiveLayout.isMobile(context)) {
                    return _buildMobileStudentList(context, controller, cls);
                  } else {
                    return _buildDesktopStudentTable(context, controller, cls);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopStudentTable(
    BuildContext context,
    ClassController controller,
    ClassModel cls,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(4),
            4: FixedColumnWidth(120),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('NIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('NISN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('Nama Lengkap Siswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                ),
              ],
            ),
            // Rows
            ...controller.filteredStudents.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final student = entry.value;

              return TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text('$idx', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      student.nis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      student.nisn,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      student.nama,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        if (controller.isAdmin.value) ...[
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                            tooltip: 'Edit Siswa',
                            onPressed: () => _showStudentFormDialog(context, controller, cls, student: student),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            tooltip: 'Hapus Siswa',
                            onPressed: () => controller.confirmDeleteStudent(student),
                          ),
                        ] else
                          const Text('-', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileStudentList(
    BuildContext context,
    ClassController controller,
    ClassModel cls,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.filteredStudents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final student = controller.filteredStudents[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  student.nama.isNotEmpty ? student.nama[0].toUpperCase() : 'S',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.nama,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('NIS: ${student.nis}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(width: 10),
                        Text('NISN: ${student.nisn}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              if (controller.isAdmin.value)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                      tooltip: 'Edit Siswa',
                      onPressed: () => _showStudentFormDialog(context, controller, cls, student: student),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      tooltip: 'Hapus Siswa',
                      onPressed: () => controller.confirmDeleteStudent(student),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _showStudentFormDialog(
    BuildContext context,
    ClassController controller,
    ClassModel cls, {
    StudentModel? student,
  }) {
    if (student != null) {
      controller.openEditStudentDialog(student);
    } else {
      controller.openCreateStudentDialog();
    }

    final isEdit = student != null;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Data Siswa' : 'Tambah Siswa Baru',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textMain),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Class badge banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.meeting_room, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Rombel: Kelas ${cls.namaKelas} (Tingkat ${cls.tingkat})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 16),

              // NIS
              const Text(
                'Nomor Induk Siswa (NIS)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller.nisController,
                decoration: InputDecoration(
                  hintText: 'Misal: 241031',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // NISN
              const Text(
                'NISN',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller.nisnController,
                decoration: InputDecoration(
                  hintText: 'Misal: 0088001031',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Nama Lengkap
              const Text(
                'Nama Lengkap Siswa',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller.namaSiswaController,
                decoration: InputDecoration(
                  hintText: 'Misal: I Made Pratama Jaya',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  Obx(() => ElevatedButton(
                        onPressed: controller.isSavingStudent.value ? null : controller.saveStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: controller.isSavingStudent.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Siswa'),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // VIEW 3: MODAL IMPORT DATA SISWA EXCEL
  // =========================================================================

  void _showImportExcelDialog(
    BuildContext context,
    ClassController controller,
    ClassModel cls,
  ) {
    controller.openImportDialog();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 650),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.table_chart, color: Colors.green.shade700, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Import Siswa dari Excel / CSV',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textMain),
                            ),
                            Text(
                              'Target: Kelas ${cls.namaKelas} (Tingkat ${cls.tingkat})',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),

                // Step 1: Template Excel info & Download
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.table_view_rounded, size: 20, color: Colors.green.shade800),
                              const SizedBox(width: 8),
                              Text(
                                'Template Format Excel Siswa',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                          Obx(() => ElevatedButton.icon(
                                onPressed: controller.isDownloadingTemplate.value
                                    ? null
                                    : () => controller.downloadTemplateFile(format: 'xlsx'),
                                icon: controller.isDownloadingTemplate.value
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.download, size: 15),
                                label: const Text('Download Template (.xlsx)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unduh template resmi berformat spreadsheet Excel di atas untuk dibuka di Microsoft Excel, lalu isi data siswa.',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => controller.downloadTemplateFile(format: 'csv'),
                            icon: const Icon(Icons.file_download_outlined, size: 14),
                            label: const Text('Download .CSV'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade900,
                              side: BorderSide(color: Colors.green.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: controller.copyTemplateToClipboard,
                            icon: const Icon(Icons.copy, size: 14),
                            label: const Text('Salin Format Teks'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade900,
                              side: BorderSide(color: Colors.green.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Text(
                          'Format 3 Kolom:\nKolom A: nis  |  Kolom B: nisn  |  Kolom C: nama\nContoh: 241031, 0088001031, I Made Pratama Jaya',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Step 2: Upload file or Paste
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih File atau Tempel Data:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.pickAndParseFile,
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text('Pilih Berkas (.xlsx / .csv / .txt)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Multi-line paste area
                TextField(
                  controller: controller.pasteController,
                  maxLines: 4,
                  onChanged: (val) => controller.parseCsvOrText(val),
                  decoration: InputDecoration(
                    hintText: 'Tempel data baris dari Excel atau CSV di sini...\nContoh:\n241031,0088001031,I Made Pratama Jaya\n241032,0088001032,Ni Putu Sintya Dewi',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),

                // Error message banner if any
                Obx(() {
                  if (controller.importError.value.isNotEmpty) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.importError.value,
                              style: const TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Step 3: Live Preview Table
                Obx(() {
                  final list = controller.parsedImportStudents;
                  if (list.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pratinjau Data (${list.length} Siswa Terdeteksi)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Format Valid',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 160),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final row = list[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Text('${idx + 1}.', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  const SizedBox(width: 10),
                                  Text(row['nis'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 12),
                                  Text(row['nisn'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      row['nama'] ?? '',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMain),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 24),

                // Dialog Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    Obx(() {
                      final hasRows = controller.parsedImportStudents.isNotEmpty;
                      return ElevatedButton.icon(
                        onPressed: (!hasRows || controller.isImporting.value) ? null : controller.executeImport,
                        icon: controller.isImporting.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          controller.isImporting.value
                              ? 'Mengimpor...'
                              : 'Import ${controller.parsedImportStudents.length} Siswa',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
