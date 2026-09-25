import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/alert_helper.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController(text: 'surya@gurita.sch.id');
  final passwordController = TextEditingController(text: 'password');

  final isPasswordVisible = false.obs;
  final isLoading = false.obs;
  final formKey = GlobalKey<FormState>();

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final result = await _authService.login(
        emailController.text,
        passwordController.text,
      );

      if (result['success'] == true) {
        AlertHelper.showSuccess(
          'Selamat datang di GURITA',
          title: 'Login Berhasil',
        );
        Get.offAllNamed('/main');
      } else {
        AlertHelper.showError(result['message'] ?? 'Login gagal');
      }
    } catch (e) {
      AlertHelper.showError('Terjadi kesalahan koneksi server');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
