import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/responsive/responsive_layout.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: ResponsiveContainer(
          padding: EdgeInsets.zero,
          child: Obx(() {
            final user = controller.user.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              user != null && user.nama.isNotEmpty ? user.nama[0] : 'G',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    user?.nama ?? 'I Made Surya, S.Kom',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.successSubtle,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Guru Aktif',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'NIP: ${user?.nip ?? "-"}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.mataPelajaran ?? 'IoT & Dasar Komputer',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Information Details
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Akun & Instansi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _infoRow('Nama Lengkap', user?.nama ?? '-'),
                        const Divider(height: 24),
                        _infoRow('Nomor Induk Pegawai (NIP)', user?.nip ?? '-'),
                        const Divider(height: 24),
                        _infoRow('Email Kedinasan', user?.email ?? '-'),
                        const Divider(height: 24),
                        _infoRow('Mata Pelajaran', user?.mataPelajaran ?? '-'),
                        const Divider(height: 24),
                        _infoRow('Peran Akun', 'Guru Pengajar'),
                        const Divider(height: 24),
                        _infoRow('Aplikasi Digital', '${AppConstants.appName} (${AppConstants.appSubtitle})'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Settings & Actions
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengaturan & Keamanan Akun',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Edit Profile Button
                        _menuTile(
                          icon: Icons.edit_outlined,
                          title: 'Ubah Data Profil',
                          subtitle: 'Perbarui nama dan email Anda',
                          color: AppColors.primary,
                          onTap: () => _showEditProfileDialog(context, controller),
                        ),
                        const Divider(height: 16),

                        // Change Password Button
                        _menuTile(
                          icon: Icons.lock_outline,
                          title: 'Ubah Kata Sandi',
                          subtitle: 'Ganti password akun untuk keamanan',
                          color: AppColors.warning,
                          onTap: () => _showChangePasswordDialog(context, controller),
                        ),
                        const Divider(height: 16),

                        // Logout Button
                        _menuTile(
                          icon: Icons.logout,
                          title: 'Keluar dari GURITA',
                          subtitle: 'Akhiri sesi login guru pada perangkat ini',
                          color: AppColors.error,
                          onTap: controller.logout,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, ProfileController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah Data Profil Guru', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Nama Lengkap & Gelar',
                controller: controller.nameController,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Email Kedinasan',
                controller: controller.emailController,
                prefixIcon: Icons.email_outlined,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.saveProfile();
              Get.back();
            },
            child: const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, ProfileController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Password Saat Ini',
                controller: controller.oldPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Password Baru',
                controller: controller.newPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock_reset,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Konfirmasi Password Baru',
                controller: controller.confirmPasswordController,
                obscureText: true,
                prefixIcon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: controller.changePassword,
            child: const Text('Ubah Password'),
          ),
        ],
      ),
    );
  }
}
