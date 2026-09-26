import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/responsive/responsive_layout.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/models/user_model.dart';
import '../controllers/teacher_controller.dart';

class TeacherView extends StatelessWidget {
  const TeacherView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TeacherController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: LoadingIndicator(message: 'Memuat data guru...')),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: controller.isAdmin.value && MediaQuery.of(context).size.width < 600
            ? FloatingActionButton.extended(
                onPressed: () => _showTeacherFormDialog(context, controller),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Guru'),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: controller.loadTeachers,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: ResponsiveContainer(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Bar Responsif
                  _buildHeader(context, controller),
                  const SizedBox(height: 18),

                  // 2. Stat Cards Ringkasan
                  _buildStatsGrid(context, controller),
                  const SizedBox(height: 18),

                  // 3. Search and Role Filter Bar
                  _buildSearchAndFilterCard(context, controller),
                  const SizedBox(height: 20),

                  // 4. Content List / Table
                  if (controller.filteredTeachers.isEmpty)
                    const EmptyStateWidget(
                      title: 'Tidak Ada Data Guru',
                      message: 'Tidak ditemukan guru yang sesuai kriteria pencarian. Klik "+ Tambah Guru" untuk mendaftarkan akun baru.',
                    )
                  else
                    _buildTeacherList(context, controller),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context, TeacherController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final headerText = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text(
                  'Data Guru & Tenaga Pendidik',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                if (controller.isAdmin.value)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Text(
                      'Kelola Admin',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Kelola akun dinas, NIP, hak akses, dan penugasan mata pelajaran guru SMK Negeri 1 Abang',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        );

        final addButton = controller.isAdmin.value
            ? ElevatedButton.icon(
                onPressed: () => _showTeacherFormDialog(context, controller),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Tambah Guru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            : const SizedBox.shrink();

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerText,
              if (controller.isAdmin.value) ...[
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: addButton),
              ],
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: headerText),
            if (controller.isAdmin.value) ...[
              const SizedBox(width: 16),
              addButton,
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid(BuildContext context, TeacherController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        final statCards = [
          _buildStatCard(
            title: 'Total Pendidik',
            value: '${controller.totalPendidik}',
            subtitle: 'Terdaftar di GURITA',
            icon: Icons.groups_outlined,
            color: AppColors.primary,
            bg: AppColors.primarySubtle,
          ),
          _buildStatCard(
            title: 'Guru Pengajar',
            value: '${controller.totalGuru}',
            subtitle: 'Guru aktif KBM',
            icon: Icons.badge_outlined,
            color: AppColors.success,
            bg: AppColors.successSubtle,
          ),
          _buildStatCard(
            title: 'Administrator',
            value: '${controller.totalAdmin}',
            subtitle: 'Pengelola sistem',
            icon: Icons.admin_panel_settings_outlined,
            color: const Color(0xFF8B5CF6),
            bg: const Color(0xFFF5F3FF),
          ),
          _buildStatCard(
            title: 'Jadwal Aktif',
            value: '${controller.totalJadwalAktif}',
            subtitle: 'Total sesi mengajar',
            icon: Icons.calendar_month_outlined,
            color: AppColors.warning,
            bg: AppColors.warningSubtle,
          ),
        ];

        if (isMobile) {
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
            children: statCards,
          );
        }

        return Row(
          children: statCards.map((c) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: c,
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSubtle),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterCard(BuildContext context, TeacherController controller) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            final searchField = TextField(
              onChanged: (val) => controller.searchQuery.value = val,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan nama, NIP, email, atau mata pelajaran...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSubtle),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            );

            final filterChips = Obx(() => Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ['Semua', 'Guru', 'Admin'].map((role) {
                final isSelected = controller.selectedRoleFilter.value == role;
                return ChoiceChip(
                  label: Text(role),
                  selected: isSelected,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textMain,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  onSelected: (val) {
                    if (val) controller.selectedRoleFilter.value = role;
                  },
                );
              }).toList(),
            ));

            final countBadge = Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${controller.filteredTeachers.length} Pendidik',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ));

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  searchField,
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      filterChips,
                      countBadge,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 14),
                filterChips,
                const SizedBox(width: 10),
                countBadge,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTeacherList(BuildContext context, TeacherController controller) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      // Desktop Table View
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
              constraints: const BoxConstraints(minWidth: 800),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.background),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                  fontSize: 13,
                ),
                dataRowMinHeight: 64,
                dataRowMaxHeight: 70,
                columns: [
                  const DataColumn(label: Text('GURU & NIP')),
                  const DataColumn(label: Text('PERAN')),
                  const DataColumn(label: Text('MATA PELAJARAN')),
                  const DataColumn(label: Text('EMAIL DINAS')),
                  const DataColumn(label: Text('JADWAL')),
                  if (controller.isAdmin.value)
                    const DataColumn(label: Text('AKSI')),
                ],
                rows: controller.filteredTeachers.map((teacher) {
                  final isAdminRole = teacher.role == 'admin';

                  return DataRow(
                    cells: [
                      // Nama & NIP
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isAdminRole ? Colors.purple.shade100 : AppColors.primarySubtle,
                              child: Text(
                                teacher.nama.isNotEmpty ? teacher.nama[0].toUpperCase() : 'G',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isAdminRole ? Colors.purple.shade800 : AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  teacher.nama,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'NIP: ${teacher.nip}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Peran
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAdminRole ? Colors.purple.shade50 : AppColors.successSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAdminRole ? Colors.purple.shade200 : AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isAdminRole ? 'Administrator' : 'Guru Pengajar',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isAdminRole ? Colors.purple.shade700 : AppColors.success,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),

                      // Mata Pelajaran
                      DataCell(
                        Text(
                          teacher.mataPelajaran ?? '-',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),

                      // Email
                      DataCell(
                        Text(
                          teacher.email,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ),

                      // Jadwal
                      DataCell(
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: teacher.totalJadwal > 0 ? AppColors.primary : AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              teacher.totalJadwal > 0 ? '${teacher.totalJadwal} Jadwal' : '-',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: teacher.totalJadwal > 0 ? AppColors.textMain : AppColors.textMuted,
                                fontWeight: teacher.totalJadwal > 0 ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Aksi
                      if (controller.isAdmin.value)
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Tombol Login Sebagai Guru Ini
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primarySubtle,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: IconButton(
                                  onPressed: () => controller.loginAsTeacher(teacher),
                                  icon: const Icon(Icons.login_rounded, size: 17, color: AppColors.primary),
                                  tooltip: 'Login Sebagai ${teacher.nama}',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => _showTeacherDetailDialog(context, controller, teacher),
                                icon: const Icon(Icons.info_outline, size: 18, color: AppColors.info),
                                tooltip: 'Rincian Guru',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => _showTeacherFormDialog(context, controller, teacher: teacher),
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                tooltip: 'Edit Data Guru',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => controller.confirmDelete(teacher),
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                tooltip: 'Hapus Guru',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
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
      // Mobile / Tablet Card View
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.filteredTeachers.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final teacher = controller.filteredTeachers[index];
          final isAdminRole = teacher.role == 'admin';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isAdminRole ? Colors.purple.shade100 : AppColors.primarySubtle,
                    child: Text(
                      teacher.nama.isNotEmpty ? teacher.nama[0].toUpperCase() : 'G',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isAdminRole ? Colors.purple.shade800 : AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              teacher.nama,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMain,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAdminRole ? Colors.purple.shade50 : AppColors.successSubtle,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isAdminRole ? Colors.purple.shade200 : AppColors.success.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                isAdminRole ? 'Admin' : 'Guru',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isAdminRole ? Colors.purple.shade700 : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'NIP: ${teacher.nip}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          teacher.email,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (teacher.mataPelajaran != null && teacher.mataPelajaran!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  teacher.mataPelajaran!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ),
                            if (teacher.totalJadwal > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySubtle,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${teacher.totalJadwal} Jadwal',
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                              ),
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
                          onPressed: () => controller.loginAsTeacher(teacher),
                          icon: const Icon(Icons.login_rounded, size: 20, color: AppColors.primary),
                          tooltip: 'Login Sebagai ${teacher.nama}',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onSelected: (val) {
                            if (val == 'login_as') {
                              controller.loginAsTeacher(teacher);
                            } else if (val == 'detail') {
                              _showTeacherDetailDialog(context, controller, teacher);
                            } else if (val == 'edit') {
                              _showTeacherFormDialog(context, controller, teacher: teacher);
                            } else if (val == 'delete') {
                              controller.confirmDelete(teacher);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'login_as',
                              child: Row(
                                children: [
                                  Icon(Icons.login_rounded, size: 18, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Login Sebagai Akun Ini'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'detail',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 18, color: AppColors.info),
                                  SizedBox(width: 8),
                                  Text('Rincian Guru'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Edit Guru'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Hapus Guru', style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
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

  void _showTeacherFormDialog(BuildContext context, TeacherController controller, {UserModel? teacher}) {
    if (teacher == null) {
      controller.openCreateDialog();
    } else {
      controller.openEditDialog(teacher);
    }

    final isEdit = teacher != null;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primarySubtle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isEdit ? Icons.edit_note : Icons.person_add_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEdit ? 'Edit Data Guru' : 'Tambah Guru Baru',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Form Fields
                // 1. Nama Lengkap & Gelar
                const Text(
                  'Nama Lengkap & Gelar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.namaController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Contoh: I Made Surya, S.Kom',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. NIP Guru
                const Text(
                  'Nomor Induk Pegawai (NIP)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.nipController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 198507122010011008',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Email Kedinasan
                const Text(
                  'Email Kedinasan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Contoh: surya@smkn1abang.sch.id',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Password
                Row(
                  children: [
                    const Text(
                      'Kata Sandi / Password',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain),
                    ),
                    if (isEdit) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '(Kosongkan jika tidak diubah)',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Obx(() => TextField(
                  controller: controller.passwordController,
                  obscureText: !controller.isPasswordVisible.value,
                  decoration: InputDecoration(
                    hintText: isEdit ? 'Biarkan kosong untuk mempertahankan' : 'Minimal 6 karakter',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => controller.isPasswordVisible.toggle(),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )),
                const SizedBox(height: 14),

                // 5. Mata Pelajaran Diampu
                const Text(
                  'Mata Pelajaran Diampu',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.mapelController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: IoT & Dasar Komputer',
                    prefixIcon: const Icon(Icons.menu_book_outlined, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (controller.availableSubjects.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: controller.availableSubjects.take(5).map((s) {
                      return InkWell(
                        onTap: () {
                          controller.mapelController.text = s.namaMapel;
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '+ ${s.namaMapel}',
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // 6. Hak Akses / Peran
                const Text(
                  'Peran & Hak Akses',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain),
                ),
                const SizedBox(height: 8),
                Obx(() => Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => controller.selectedRole.value = 'guru',
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: controller.selectedRole.value == 'guru' ? AppColors.primarySubtle : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: controller.selectedRole.value == 'guru' ? AppColors.primary : AppColors.border,
                              width: controller.selectedRole.value == 'guru' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 18,
                                color: controller.selectedRole.value == 'guru' ? AppColors.primary : AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Guru Pengajar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: controller.selectedRole.value == 'guru' ? AppColors.primary : AppColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => controller.selectedRole.value = 'admin',
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: controller.selectedRole.value == 'admin' ? Colors.purple.shade50 : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: controller.selectedRole.value == 'admin' ? Colors.purple.shade400 : AppColors.border,
                              width: controller.selectedRole.value == 'admin' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 18,
                                color: controller.selectedRole.value == 'admin' ? Colors.purple.shade700 : AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Administrator',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: controller.selectedRole.value == 'admin' ? Colors.purple.shade700 : AppColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
                const SizedBox(height: 24),

                // Modal Actions
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    Obx(() => ElevatedButton.icon(
                      onPressed: controller.isSaving.value ? null : controller.saveTeacher,
                      icon: controller.isSaving.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(controller.isSaving.value
                          ? 'Menyimpan...'
                          : (isEdit ? 'Simpan Perubahan' : 'Tambah Guru')),
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

  void _showTeacherDetailDialog(BuildContext context, TeacherController controller, UserModel teacher) {
    final isAdminRole = teacher.role == 'admin';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rincian Profil Pendidik',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textMain),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: isAdminRole ? Colors.purple.shade100 : AppColors.primarySubtle,
                        child: Text(
                          teacher.nama.isNotEmpty ? teacher.nama[0].toUpperCase() : 'G',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: isAdminRole ? Colors.purple.shade800 : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        teacher.nama,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMain),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAdminRole ? Colors.purple.shade50 : AppColors.successSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isAdminRole ? Colors.purple.shade200 : AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          isAdminRole ? 'Administrator Sekolah' : 'Guru Pengajar Aktif',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isAdminRole ? Colors.purple.shade700 : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                _detailRow('NIP Pegawai', teacher.nip),
                _detailRow('Email Dinas', teacher.email),
                _detailRow('Mata Pelajaran', teacher.mataPelajaran ?? '-'),
                _detailRow('Total Jadwal', teacher.totalJadwal > 0 ? '${teacher.totalJadwal} Jadwal Mengajar' : 'Belum Dijadwalkan'),
                _detailRow('Instansi', 'SMK Negeri 1 Abang'),
                const SizedBox(height: 16),
                if (controller.isAdmin.value) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        controller.loginAsTeacher(teacher);
                      },
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: Text('Login Sebagai ${teacher.nama}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Tutup Rincian'),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Tutup Rincian'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain),
            ),
          ),
        ],
      ),
    );
  }
}
