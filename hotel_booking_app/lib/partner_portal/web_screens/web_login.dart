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

      // ===================== SUCCESS LOGIN =====================
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
    final TextEditingController emailController = TextEditingController();
    final TextEditingController otpController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    int currentStep = 1; // 1: Email, 2: OTP, 3: New Password
    bool showPassword = false;
    bool isApiLoading = false;

    // Timer for Resend OTP
    int secondsRemaining = 60;
    bool canResend = false;
    Timer? timer;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {

            // Function to start the 1-minute countdown
            void startTimer() {
              setDialogState(() {
                secondsRemaining = 60;
                canResend = false;
              });
              timer?.cancel();
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (secondsRemaining == 0) {
                  setDialogState(() { t.cancel(); canResend = true; });
                } else {
                  setDialogState(() { secondsRemaining--; });
                }
              });
            }

            // Step 1: Send OTP
            Future<void> handleSendOtp() async {
              if (emailController.text.isEmpty) return;
              setDialogState(() => isApiLoading = true);
              try {
                final res = await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/send-email-otp'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'email': emailController.text.trim().toLowerCase(),
                    'type': 'send_otp'
                  }),
                );
                final data = jsonDecode(res.body);
                if (data['status'] == 'success') {
                  startTimer();
                  setDialogState(() => currentStep = 2);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
                }
              } catch (e) {
                print("Error: $e");
              } finally {
                setDialogState(() => isApiLoading = false);
              }
            }

            // Step 2: Verify OTP
            Future<void> handleVerifyOtp() async {
              if (otpController.text.isEmpty) return;
              setDialogState(() => isApiLoading = true);
              try {
                final res = await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/verify-email-otp'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'email': emailController.text.trim().toLowerCase(),
                    'otp': otpController.text.trim(),
                    'type': 'verify_otp'
                  }),
                );
                final data = jsonDecode(res.body);
                if (data['status'] == 'success') {
                  setDialogState(() => currentStep = 3);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
                }
              } finally {
                setDialogState(() => isApiLoading = false);
              }
            }

            // Step 3: Final Reset
            Future<void> handleResetPassword() async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
                return;
              }
              setDialogState(() => isApiLoading = true);
              try {
                final res = await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/forgotpassword'),
                  headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                  body: 'email=${Uri.encodeComponent(emailController.text.trim())}&newPassword=${Uri.encodeComponent(newPasswordController.text.trim())}',
                );
                final data = jsonDecode(res.body);
                if (data['status'] == 'success') {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed successfully!")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
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
                style: const TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentStep == 1) ...[
                      const Text("Enter your registered email to receive an OTP.", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 20),
                      _dialogTextField(emailController, "Registered Email", Icons.email),
                    ] else if (currentStep == 2) ...[
                      Text("OTP sent to ${emailController.text}", style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      _dialogTextField(otpController, "Enter 6-Digit OTP", Icons.lock_clock),
                      TextButton(
                        onPressed: canResend ? handleSendOtp : null,
                        child: Text(canResend ? "Resend OTP" : "Resend in ${secondsRemaining}s",
                            style: TextStyle(color: canResend ? Colors.white : Colors.white38)),
                      ),
                    ] else if (currentStep == 3) ...[
                      _dialogTextField(newPasswordController, "New Password", Icons.lock, obscure: !showPassword),
                      const SizedBox(height: 15),
                      _dialogTextField(confirmPasswordController, "Confirm Password", Icons.check_circle, obscure: !showPassword),
                    ],
                  ],
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent[700], foregroundColor: Colors.black),
                    child: Text(currentStep == 1 ? "Next" : currentStep == 2 ? "Verify" : "Reset Password"),
                  ),
              ],
            );
          },
        );
      },
    );
  }

// Helper Widget for Dialog TextFields
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
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
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

              // EMAIL FIELD
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

              // PASSWORD FIELD
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

              // LOGIN BUTTON
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
    );
  }
}