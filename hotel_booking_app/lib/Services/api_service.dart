import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ================== API CONFIG ==================
class ApiConfig {
  static const String _localWeb = 'http://localhost:8080';
  static const String _localAndroid = 'http://10.0.2.2:8080';
  static const String _production =
      'https://test-host-server-tamg.onrender.com';

  static String get baseUrl {
    if (kReleaseMode) return _production;
    if (kIsWeb) return _localWeb;
    return _localAndroid;
  }
}

/// ================== API SERVICE ==================
class ApiService {

  // ============================================================
  // ====================== LOGIN SECTION ========================
  // ============================================================

  /// 🔥 RAW LOGIN (USED BY WEB LOGIN PAGE)
  /// Returns full decoded JSON including status
  static Future<Map<String, dynamic>?> loginUserRaw({
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

      debugPrint('Login RAW Code: ${response.statusCode}');
      debugPrint('Login RAW Body: ${response.body}');

      if (response.statusCode != 200) return null;

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Login RAW Error: $e');
      return null;
    }
  }

  /// SAFE LOGIN (OPTIONAL USE)
  static Future<Map<String, String>?> loginUser({
    required String email,
    required String password,
  }) async {

    final raw = await loginUserRaw(email: email, password: password);

    if (raw == null) return null;
    if (raw['status'] != 'success') return null;

    // ✅ IMPORTANT FIX: Extract nested data object
    final Map<String, dynamic> userData = raw['data'];

    return Map<String, String>.from(
      userData.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
  }


  // ============================================================
  // ====================== REGISTER =============================
  // ============================================================

  static Future<bool> registerUser({
    required String email,
    required String firstName,
    required String lastName,
    required String gender,
    required String mobile,
    required String address,
    required String password,
    required String consent,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/register');

    final body = jsonEncode({
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'mobile': mobile,
      'address': address,
      'password': password,
      'consent': consent,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      debugPrint('Register Code: ${response.statusCode}');
      debugPrint('Register Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Register Error: $e');
      return false;
    }
  }

  // ============================================================
  // ====================== PROFILE SECTION ======================
  // ============================================================

  static Future<Map<String, dynamic>?> getProfile({
    required String email,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/webgetprofile');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
        'loggedInEmail=${Uri.encodeComponent(email.trim().toLowerCase())}',
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      if (data['status'] != 'success') return null;

      return data['data'];
    } catch (e) {
      debugPrint('Profile Error: $e');
      return null;
    }
  }

  static Future<bool> updateProfile({
    required Map<String, String> fields,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/webupdateprofile');

    final bodyString = fields.entries
        .map((e) =>
    "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}")
        .join("&");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: bodyString,
      );

      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      debugPrint('Update Profile Error: $e');
      return false;
    }
  }

  static Future<bool> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/webchangepassword');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
        'loggedInEmail=${Uri.encodeComponent(email.trim().toLowerCase())}'
            '&currentPassword=${Uri.encodeComponent(currentPassword)}'
            '&newPassword=${Uri.encodeComponent(newPassword)}',
      );

      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      debugPrint('Change Password Error: $e');
      return false;
    }
  }

  static Future<bool> deleteAccount({
    required String email,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/webdeleteprofile');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
        'loggedInEmail=${Uri.encodeComponent(email.trim().toLowerCase())}',
      );

      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      debugPrint('Delete Account Error: $e');
      return false;
    }
  }
}
