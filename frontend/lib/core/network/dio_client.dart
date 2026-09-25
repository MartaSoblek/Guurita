import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/app_storage.dart';
import '../../app/constants/app_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  final AppStorage _storage = AppStorage();

  DioClient._internal() {
    String baseUrl = AppConstants.apiDevBaseUrl;

    // In Android mobile emulator, 10.0.2.2 is used to point to host machine
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      baseUrl = AppConstants.apiAndroidEmulatorBaseUrl;
    }

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.read<String>(AppConstants.tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          if (kDebugMode) {
            print('[DIO ERROR] ${error.type} => ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
  }
}
