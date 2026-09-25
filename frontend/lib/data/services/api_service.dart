import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/dio_client.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: json['errors'],
    );
  }
}

class ApiService {
  final Dio dio = DioClient().dio;

  Future<Response?> safeGet(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await dio.get(path, queryParameters: queryParameters);
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService safeGet Error] $path: $e');
      }
      return null;
    }
  }

  Future<Response?> safePost(String path, {dynamic data}) async {
    try {
      final response = await dio.post(path, data: data);
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService safePost Error] $path: $e');
      }
      return null;
    }
  }

  Future<Response?> safePut(String path, {dynamic data}) async {
    try {
      final response = await dio.put(path, data: data);
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService safePut Error] $path: $e');
      }
      return null;
    }
  }

  Future<Response?> safeDelete(String path) async {
    try {
      final response = await dio.delete(path);
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService safeDelete Error] $path: $e');
      }
      return null;
    }
  }
}
