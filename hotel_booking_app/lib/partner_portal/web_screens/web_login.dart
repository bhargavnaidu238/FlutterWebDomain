import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'web_register.dart';
import 'package:hotel_booking_app/services/api_service.dart';
import 'dart:async';

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
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/weblogin');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
        'email=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['status'] == 'success') {
        partnerDetails = Map<String, String>.from(data)
          ..removeWhere((key, value) =>
          key == 'status' || key == 'message');

        ApiService.saveAuthData(
          token: data['token'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          email: email,
          userId: partnerDetails['userId'] ?? '',
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
              (route) => false,
          arguments: partnerDetails,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Login failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ===================== FORGOT PASSWORD =====================
  Future<void> forgotPassword() async {
    final TextEditingController forgotEmailController = TextEditingController();
    final TextEditingController otpController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    int currentStep = 1; // 1: Email, 2: OTP, 3: New Password
    bool showPasswordForgot = false;
    bool isApiLoading = false;

    int secondsRemaining = 60;
    bool canResend = false;
    Timer? timer;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {

            void startTimer() {
              setDialogState(() {
                secondsRemaining = 60;
                canResend = false;
              });
              timer?.cancel();
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (secondsRemaining == 0) {
                  setDialogState(() {
                    t.cancel();
                    canResend = true;
                  });
                } else {
                  setDialogState(() {
                    secondsRemaining--;
                  });
                }
              });
            }

            Future<void> handleSendOtp() async {
              if (forgotEmailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter your email")));
                return;
              }

              setDialogState(() => isApiLoading = true);
              try {
                final res = await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/send-email-otp'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'user_email': forgotEmailController.text.trim().toLowerCase(), // FIXED KEY
                    'type': 'forgotpassword' // FIXED TYPE
                  }),
                );

                final data = jsonDecode(res.body);

                if (res.statusCode == 200 && data['status'] == 'success') {
                  startTimer();
                  setDialogState(() => currentStep = 2);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(data['message'] ?? "Error sending OTP")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Connection Error: $e")));
              } finally {
                setDialogState(() => isApiLoading = false);
              }
            }

            Future<void> handleVerifyOtp() async {
              if (otpController.text.isEmpty) return;
              setDialogState(() => isApiLoading = true);
              try {
                final res = await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/verify-email-otp'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'user_email': forgotEmailController.text.trim().toLowerCase(), // FIXED KEY
                    'otp': otpController.text.trim(),
                    'type': 'forgotpassword' // FIXED TYPE
                  }),
                );
                final data = jsonDecode(res.body);
                if (res.statusCode == 200 && data['status'] == 'success') {
                  setDialogState(() => currentStep = 3);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data['message'] ?? "Invalid OTP")));
                }
              } finally {
                setDialogState(() => isApiLoading = false);
              }
            }

            Future<void> handleResetPassword() async {
              final pwd = newPasswordController.text.trim();
              final confirmPwd = confirmPasswordController.text.trim();

              if (pwd.isEmpty || pwd != confirmPwd) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Passwords do not match!")));
                return;
              }

              setDialogState(() => isApiLoading = true);
              try {
                final res = await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/forgotpassword'),
                  headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                  body: 'user_email=${Uri.encodeComponent(forgotEmailController.text.trim().toLowerCase())}&newPassword=${Uri.encodeComponent(pwd)}', // FIXED KEY
                );

                final data = jsonDecode(res.body);
                if (res.statusCode == 200 && data['status'] == 'success') {
                  timer?.cancel();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password updated successfully!")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data['message'] ?? "Reset failed")));
                }
              } finally {
                setDialogState(() => isApiLoading = false);
              }
            }

            return AlertDialog(
              backgroundColor: Colors.green[900]?.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                currentStep == 1 ? "Forgot Password" : currentStep == 2 ? "Verify OTP" : "Set New Password",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currentStep == 1) ...[
                        const Text("Enter your registered email. We will send a 6-digit code to verify your identity.",
                            style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        _dialogTextField(forgotEmailController, "Registered Email", Icons.email),
                      ] else if (currentStep == 2) ...[
                        Text("We've sent a code to ${forgotEmailController.text}",
                            style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        _dialogTextField(otpController, "6-Digit OTP", Icons.security),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: canResend ? handleSendOtp : null,
                          child: Text(canResend ? "Resend OTP" : "Resend in ${secondsRemaining}s",
                              style: TextStyle(color: canResend ? Colors.white : Colors.white38, fontWeight: FontWeight.bold)),
                        ),
                      ] else if (currentStep == 3) ...[
                        _dialogTextField(newPasswordController, "New Password", Icons.lock_outline, obscure: !showPasswordForgot),
                        const SizedBox(height: 15),
                        _dialogTextField(confirmPasswordController, "Confirm Password", Icons.lock_reset, obscure: !showPasswordForgot),
                        Row(
                          children: [
                            Checkbox(
                              value: showPasswordForgot,
                              onChanged: (val) => setDialogState(() => showPasswordForgot = val!),
                              side: const BorderSide(color: Colors.white70),
                            ),
                            const Text("Show Password", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () { timer?.cancel(); Navigator.pop(context); },
                  child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                ),
                if (isApiLoading)
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: CircularProgressIndicator(color: Colors.white))
                else
                  ElevatedButton(
                    onPressed: currentStep == 1 ? handleSendOtp : currentStep == 2 ? handleVerifyOtp : handleResetPassword,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent[700],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    child: Text(currentStep == 1 ? "Next" : currentStep == 2 ? "Verify" : "Reset Password"),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
      ),
    );
  }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 8),
                ),
              ],
              backgroundBlendMode: BlendMode.overlay,
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
                      Shadow(
                          color: Colors.black45,
                          blurRadius: 8)
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle:
                    const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.email,
                        color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style:
                  const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 15),

                StatefulBuilder(
                  builder: (context, setStateSB) {
                    return TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle:
                        const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock,
                            color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                              showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70),
                          onPressed: () {
                            setStateSB(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style:
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
                const SizedBox(height: 25),

                isLoading
                    ? const CircularProgressIndicator(
                    color: Colors.white)
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
                        fontWeight:
                        FontWeight.bold),
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
                          style: TextStyle(
                              color: Colors.white70)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const WebRegisterPage()),
                        );
                      },
                      child: const Text("Register",
                          style: TextStyle(
                              color: Colors.white70)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}