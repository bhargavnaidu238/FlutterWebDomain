import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;

import 'package:hotel_booking_app/services/api_service.dart';

class WebLoginPage extends StatefulWidget {
  const WebLoginPage({Key? key}) : super(key: key);

  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;

  Map<String, String> partnerDetails = {};

  // ===================== LOGIN FUNCTION =====================
  Future<void> login() async {
    debugPrint("🟡 LOGIN BUTTON CLICKED");

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      debugPrint("🔴 VALIDATION FAILED: EMPTY FIELDS");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email)) {
      debugPrint("🔴 VALIDATION FAILED: INVALID EMAIL");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email")),
      );
      return;
    }

    if (password.length < 6) {
      debugPrint("🔴 VALIDATION FAILED: PASSWORD TOO SHORT");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    setState(() => isLoading = true);
    debugPrint("🟢 CALLING LOGIN API");

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/weblogin');
      debugPrint("🌐 API URL => $url");

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
        'email=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
      );

      debugPrint("📥 API STATUS CODE => ${res.statusCode}");
      debugPrint("📥 API RESPONSE => ${res.body}");

      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['status'] == 'success') {
        debugPrint("✅ LOGIN SUCCESS");

        partnerDetails = Map<String, String>.from(data)
          ..removeWhere(
                (key, value) => key == 'status' || key == 'message',
          );

        debugPrint("📦 PARTNER DETAILS => $partnerDetails");

        // ✅ ONLY REQUIRED FIX (WEB SESSION PERSISTENCE)
        html.window.sessionStorage['partnerDetails'] =
            jsonEncode(partnerDetails);

        debugPrint("💾 partnerDetails saved to sessionStorage");
        debugPrint("🚀 NAVIGATING TO /dashboard");

        Navigator.of(context).pushReplacementNamed(
          '/dashboard',
          arguments: partnerDetails,
        );

        debugPrint("✅ NAVIGATION CALL EXECUTED");
      } else {
        debugPrint("❌ LOGIN FAILED: ${data['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Login failed")),
        );
      }
    } catch (e, stack) {
      debugPrint("🔥 EXCEPTION DURING LOGIN");
      debugPrint(e.toString());
      debugPrint(stack.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        debugPrint("🔵 LOADING STATE RESET");
      }
    }
  }

  // ===================== FORGOT PASSWORD =====================
  Future<void> forgotPassword() async {
    final TextEditingController emailResetController =
    TextEditingController();
    final TextEditingController newPasswordController =
    TextEditingController();
    bool showNewPassword = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.green[900]?.withOpacity(0.9),
          title: const Text(
            "Reset Password",
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: emailResetController,
                  decoration: InputDecoration(
                    labelText: "Registered Email",
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 15),
                StatefulBuilder(
                  builder: (context, setStateSB) {
                    return TextField(
                      controller: newPasswordController,
                      obscureText: !showNewPassword,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setStateSB(() {
                              showNewPassword = !showNewPassword;
                            });
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailResetController.text.trim();
                final newPwd = newPasswordController.text.trim();

                if (email.isEmpty || newPwd.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please fill both fields")),
                  );
                  return;
                }

                try {
                  final url =
                  Uri.parse('${ApiConfig.baseUrl}/forgotpassword');

                  final res = await http.post(
                    url,
                    headers: {
                      'Content-Type': 'application/x-www-form-urlencoded'
                    },
                    body:
                    'email=${Uri.encodeComponent(email)}&newPassword=${Uri.encodeComponent(newPwd)}',
                  );

                  final data = json.decode(res.body);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(data['message'] ?? "Error")),
                  );

                  if (data['status'] == "success") {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              child: const Text("Reset Password"),
            ),
          ],
        );
      },
    );
  }

  // ===================== BUILD UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFFB2FF59)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border:
            Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    "assets/LandingPageImages/Logo.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Login",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black45, blurRadius: 8)
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon:
                  const Icon(Icons.email, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 15),
              StatefulBuilder(
                builder: (context, setStateSB) {
                  return TextField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon:
                      const Icon(Icons.lock, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setStateSB(() {
                            showPassword = !showPassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 25),
              isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  minimumSize:
                  const Size(double.infinity, 48),
                  backgroundColor:
                  const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: forgotPassword,
                    child: const Text(
                      "Forgot Password?",
                      style:
                      TextStyle(color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (!context.mounted) return;
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      "Register",
                      style:
                      TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
