import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants/app_colors.dart';

class AlertHelper {
  static void showSuccess(String message, {String title = 'Berhasil'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }

  static void showError(String message, {String title = 'Terjadi Kesalahan'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  static void showWarning(String message, {String title = 'Peringatan'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.warning,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
    );
  }

  static Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Ya, Lanjutkan',
    String cancelText = 'Batal',
    bool isDanger = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText, style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
