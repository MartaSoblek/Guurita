import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/dummy_data_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/alert_helper.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController(text: 'surya@gurita.sch.id');
  final passwordController = TextEditingController(text: 'password');

  final isPasswordVisible = false.obs;
  final isLoading = false.obs;
  final formKey = GlobalKey<FormState>();

  // Auto-login state when redirected from Teacher list
  final isAutoLoggingIn = false.obs;
  final autoLoginTargetName = ''.obs;
  bool _autoLoginTriggered = false;

  @override
  void onInit() {
    super.onInit();
    _checkAndExecuteAutoLogin();
  }

  @override
  void onReady() {
    super.onReady();
    if (!_autoLoginTriggered) {
      _checkAndExecuteAutoLogin();
    }
  }

  void _checkAndExecuteAutoLogin() {
    if (_autoLoginTriggered) return;

    final args = Get.arguments;
    final params = Get.parameters;

    bool shouldAutoLogin = false;
    String? targetEmail;
    String? targetName;
    UserModel? targetTeacher;
    String? impersonateToken;

    if (args is Map && args['auto_login'] == true) {
      shouldAutoLogin = true;
      targetEmail = args['email'] as String?;
      targetName = args['teacher_name'] as String?;
      impersonateToken = args['impersonate_token'] as String?;
      if (args['teacher'] != null && args['teacher'] is Map<String, dynamic>) {
        targetTeacher = UserModel.fromJson(args['teacher'] as Map<String, dynamic>);
        targetName ??= targetTeacher.nama;
      }
    } else if (params['auto'] == 'true' && params['email'] != null && params['email']!.isNotEmpty) {
      shouldAutoLogin = true;
      targetEmail = params['email'];
      final matches = DummyDataProvider.dummyUsers.where(
        (u) => u.email.toLowerCase() == targetEmail!.toLowerCase(),
      ).toList();
      if (matches.isNotEmpty) {
        targetTeacher = matches.first;
        targetName = targetTeacher.nama;
      }
    }

    if (shouldAutoLogin && targetEmail != null && targetEmail.isNotEmpty) {
      _autoLoginTriggered = true;
      emailController.text = targetEmail;
      passwordController.text = 'password';
      isAutoLoggingIn.value = true;
      autoLoginTargetName.value = targetName ?? targetEmail;

      // Small visual pause so the user sees the transition to login screen & the feedback banner
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performAutoLogin(
          email: targetEmail!,
          teacher: targetTeacher,
          impersonateToken: impersonateToken,
          targetName: targetName ?? targetEmail,
        );
      });
    }
  }

  Future<void> _performAutoLogin({
    required String email,
    UserModel? teacher,
    String? impersonateToken,
    required String targetName,
  }) async {
    isLoading.value = true;
    try {
      // Artificial delay for smooth UX transition
      await Future.delayed(const Duration(milliseconds: 650));

      final result = await _authService.login(
        email,
        passwordController.text,
        fallbackUser: teacher,
        impersonateToken: impersonateToken,
      );

      if (result['success'] == true) {
        AlertHelper.showSuccess(
          'Berhasil masuk sebagai $targetName',
          title: 'Login Otomatis Berhasil',
        );
        Get.offAllNamed('/main');
      } else {
        isAutoLoggingIn.value = false;
        AlertHelper.showError(result['message'] ?? 'Login otomatis gagal');
      }
    } catch (e) {
      isAutoLoggingIn.value = false;
      AlertHelper.showError('Terjadi kesalahan saat login otomatis: $e');
    } finally {
      isLoading.value = false;
    }
  }

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
