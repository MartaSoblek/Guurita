import 'package:flutter/foundation.dart';
import '../../app/constants/app_constants.dart';

class AppImageHelper {
  /// Resolves image URL so that it works seamlessly on Web, Desktop, and Android emulator.
  static String? resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return null;
    }

    final trimmed = rawUrl.trim();

    // Base64 data URL
    if (trimmed.startsWith('data:image')) {
      return trimmed;
    }

    String url = trimmed;

    // Relative path handling
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      String base = AppConstants.apiDevBaseUrl;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        base = AppConstants.apiAndroidEmulatorBaseUrl;
      }
      // Remove trailing /api if present to get domain root
      final domain = base.replaceAll(RegExp(r'/api/?$'), '');
      final cleanPath = url.startsWith('/') ? url : '/$url';
      url = '$domain$cleanPath';
    }

    // Android emulator port forwarding
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      url = url
          .replaceAll('http://localhost:8000', 'http://10.0.2.2:8000')
          .replaceAll('http://127.0.0.1:8000', 'http://10.0.2.2:8000');
    }

    return url;
  }
}
