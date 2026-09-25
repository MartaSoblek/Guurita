import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/alert_helper.dart';

class ProfileController extends GetxController {
  final AuthService _authService = AuthService();

  final user = Rxn<UserModel>();
  final isLoading = false.obs;

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  void loadProfile() {
    user.value = _authService.currentUser;
    if (user.value != null) {
      nameController.text = user.value!.nama;
      emailController.text = user.value!.email;
    }
  }

  Future<void> saveProfile() async {
    if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
      AlertHelper.showWarning('Nama dan email wajib diisi');
      return;
    }

    isLoading.value = true;
    try {
      final res = await _authService.updateProfile(
        nama: nameController.text.trim(),
        email: emailController.text.trim(),
      );

      if (res['success'] == true) {
        user.value = res['user'];
        AlertHelper.showSuccess('Profil guru berhasil diperbarui');
      } else {
        AlertHelper.showError(res['message'] ?? 'Gagal memperbarui profil');
      }
    } catch (_) {
      AlertHelper.showError('Terjadi kesalahan saat menyimpan profil');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changePassword() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      AlertHelper.showWarning('Konfirmasi password tidak cocok');
      return;
    }
    if (newPasswordController.text.length < 6) {
      AlertHelper.showWarning('Password minimal 6 karakter');
      return;
    }

    isLoading.value = true;
    try {
      final res = await _authService.updateProfile(
        nama: user.value?.nama ?? '',
        email: user.value?.email ?? '',
        currentPassword: oldPasswordController.text,
        newPassword: newPasswordController.text,
      );

      if (res['success'] == true) {
        oldPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        AlertHelper.showSuccess('Password berhasil diubah');
        Get.back(); // close modal
      } else {
        AlertHelper.showError(res['message'] ?? 'Gagal mengubah password');
      }
    } catch (_) {
      AlertHelper.showError('Gagal memperbarui password');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    final confirmed = await AlertHelper.showConfirmDialog(
      title: 'Konfirmasi Keluar',
      message: 'Apakah Anda yakin ingin keluar dari sistem GURITA?',
      confirmText: 'Keluar',
      isDanger: true,
    );

    if (confirmed) {
      await _authService.logout();
      Get.offAllNamed('/login');
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
