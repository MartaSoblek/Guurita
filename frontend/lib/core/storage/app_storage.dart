import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static final AppStorage _instance = AppStorage._internal();
  factory AppStorage() => _instance;
  AppStorage._internal();

  static SharedPreferences? _prefs;
  static final Map<String, dynamic> _memoryCache = {};

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Memory fallback for test or environments without native channel
    }
  }

  T? read<T>(String key) {
    if (_memoryCache.containsKey(key)) {
      final cached = _memoryCache[key];
      if (cached is T) return cached;
    }

    if (_prefs == null) return null;

    if (T == String) {
      final val = _prefs!.getString(key);
      if (val != null) _memoryCache[key] = val;
      return val as T?;
    } else if (T == bool) {
      final val = _prefs!.getBool(key);
      if (val != null) _memoryCache[key] = val;
      return val as T?;
    } else if (T == int) {
      final val = _prefs!.getInt(key);
      if (val != null) _memoryCache[key] = val;
      return val as T?;
    } else if (T == double) {
      final val = _prefs!.getDouble(key);
      if (val != null) _memoryCache[key] = val;
      return val as T?;
    } else {
      // Map or Complex Object stored as JSON string
      final raw = _prefs!.getString(key);
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is T) {
            _memoryCache[key] = decoded;
            return decoded;
          }
          if (T.toString().contains('Map') && decoded is Map) {
            final map = Map<String, dynamic>.from(decoded);
            _memoryCache[key] = map;
            return map as T;
          }
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  Future<void> write(String key, dynamic value) async {
    _memoryCache[key] = value;

    if (_prefs == null) return;

    if (value is String) {
      await _prefs!.setString(key, value);
    } else if (value is bool) {
      await _prefs!.setBool(key, value);
    } else if (value is int) {
      await _prefs!.setInt(key, value);
    } else if (value is double) {
      await _prefs!.setDouble(key, value);
    } else if (value is Map || value is List) {
      final jsonStr = jsonEncode(value);
      await _prefs!.setString(key, jsonStr);
    }
  }

  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    if (_prefs != null) {
      await _prefs!.remove(key);
    }
  }

  bool hasData(String key) {
    if (_memoryCache.containsKey(key)) return true;
    return _prefs?.containsKey(key) ?? false;
  }

  Future<void> erase() async {
    _memoryCache.clear();
    if (_prefs != null) {
      await _prefs!.clear();
    }
  }
}
