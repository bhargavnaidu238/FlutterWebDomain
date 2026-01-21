import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ================== API CONFIG ==================
class ApiConfig {
  static const String _localWeb = 'http://localhost:8080';
  static const String _localAndroid = 'http://10.0.2.2:8080';
  static const String _production = 'https://test-host-server-tamg.onrender.com';

  static String get baseUrl {
    if (kReleaseMode) return _production;
    if (kIsWeb) return _localWeb;
    return _localAndroid;
  }
}

/// ================== AUTH APIs ==================
class ApiService {
  /// ================== LOGIN (WEB – FIXED) ==================
  static Future<Map<String, String>?> loginUser({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/weblogin');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'email=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
      );

      // Log status for debugging
      debugPrint('Login Response Code: ${response.statusCode}');

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] != 'success') return null;

      // Remove meta-data keys
      data.remove('status');
      data.remove('message');

      // If the API only returned status/message, provide a fallback key
      // so main.dart doesn't see a null argument.
      if (data.isEmpty) {
        return {'auth_status': 'verified'};
      }

      return Map<String, String>.from(
        data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );
    } catch (e) {
      debugPrint('Login Error: $e');
      return null;
    }
  }
}