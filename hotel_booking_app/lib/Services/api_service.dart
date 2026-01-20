import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ================== API CONFIG ==================
class ApiConfig {
  static const String _localWeb = 'http://localhost:8080';
  static const String _localAndroid = 'http://10.0.2.2:8080';
  static const String _production = 'https://api.yourdomain.com';

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
        body:
        'email=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
      );

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] != 'success') return null;

      data.remove('status');
      data.remove('message');

      return Map<String, String>.from(
        data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );
    } catch (e) {
      return null;
    }
  }
}
