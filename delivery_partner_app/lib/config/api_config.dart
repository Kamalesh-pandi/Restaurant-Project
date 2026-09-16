import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _prefKeyBaseUrl = 'custom_base_url';

  // Default fallbacks based on environment
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.33.108.4:8080/api/v1'; // Host machine LAN IP address
    }
    return 'http://localhost:8080/api/v1';
  }

  static String _currentBaseUrl = '';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKeyBaseUrl);
    if (saved != null && saved.trim().isNotEmpty) {
      // If running on Android physical device and the saved URL was loopback (127.0.0.1 or localhost),
      // while defaultBaseUrl is configured to a LAN IP, prioritize defaultBaseUrl so stale preferences
      // don't break LAN connectivity.
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          (saved.contains('127.0.0.1') || saved.contains('localhost')) &&
          !defaultBaseUrl.contains('127.0.0.1') &&
          !defaultBaseUrl.contains('localhost')) {
        _currentBaseUrl = defaultBaseUrl;
        await prefs.setString(_prefKeyBaseUrl, _currentBaseUrl);
      } else {
        _currentBaseUrl = saved.trim();
      }
    } else {
      _currentBaseUrl = defaultBaseUrl;
    }
  }

  static String get baseUrl {
    if (_currentBaseUrl.isEmpty) {
      return defaultBaseUrl;
    }
    return _currentBaseUrl;
  }

  static Future<void> setBaseUrl(String newUrl) async {
    _currentBaseUrl = newUrl.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyBaseUrl, _currentBaseUrl);
  }

  static Future<void> resetToDefault() async {
    _currentBaseUrl = defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyBaseUrl);
  }

  /// Tests connectivity to the given URL (or current baseUrl).
  /// Returns a map with 'success', 'message', 'latencyMs', and 'statusCode'.
  static Future<Map<String, dynamic>> testConnection([String? testUrl]) async {
    final target = (testUrl != null && testUrl.trim().isNotEmpty)
        ? testUrl.trim()
        : baseUrl;
    final stopwatch = Stopwatch()..start();
    try {
      final cleanTarget = target.endsWith('/')
          ? target.substring(0, target.length - 1)
          : target;
      final uri = Uri.parse('$cleanTarget/delivery-partner/login-pin');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': '0000000000', 'pinCode': '0000'}),
          )
          .timeout(const Duration(seconds: 4));
      stopwatch.stop();

      // Any HTTP response from the backend (even 400 or 401) means the server was reached!
      return {
        'success': true,
        'statusCode': response.statusCode,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'message': 'Connected successfully (${stopwatch.elapsedMilliseconds}ms)',
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Cannot reach server at $target',
      };
    }
  }
}
