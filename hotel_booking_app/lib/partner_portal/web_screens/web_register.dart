import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'web_login.dart';
import 'package:hotel_booking_app/services/api_service.dart';

class WebRegisterPage extends StatefulWidget {
  const WebRegisterPage({Key? key}) : super(key: key);

  @override
  State<WebRegisterPage> createState() => _WebRegisterPageState();
}

class _WebRegisterPageState extends State<WebRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController businessController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController gstController = TextEditingController();

  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;

  Map<String, String>? registrationData;

  /// STEP 1 → SEND OTP
  Future<void> sendOtp() async {
    final email = emailController.text.trim();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/send-email-otp');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['status'] == 'success') {
        showOtpDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to send OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("OTP Error: $e")));
    }
  }

  /// STEP 2 → VERIFY OTP
  Future<void> verifyOtp() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/verify-email-otp');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "otp": otp,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['status'] == 'success') {
        Navigator.pop(context);
        await registerUser();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Wrong OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("OTP Verification Error: $e")));
    }
  }

  /// STEP 3 → FINAL REGISTRATION
  Future<void> registerUser() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/registerlogin');

      final body = registrationData!.entries
          .map((e) =>
      '${e.key}=${Uri.encodeComponent(e.value)}')
          .join("&");

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WebLoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Registration failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Registration Error: $e")));
    }
  }

  /// REGISTER BUTTON
  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    final name = nameController.text.trim();
    final business = businessController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final city = cityController.text.trim();
    final state = stateController.text.trim();
    final country = countryController.text.trim();
    final pincode = pincodeController.text.trim();
    final gst = gstController.text.trim();

    registrationData = {
      "partner_name": name,
      "business_name": business,
      "email": email,
      "password": password,
      "contact_number": phone,
      "address": address,
      "city": city,
      "state": state,
      "country": country,
      "pincode": pincode,
      "gst_number": gst
    };

    await sendOtp();
  }

  /// OTP DIALOG UI
  void showOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Email Verification"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter the OTP sent to your email"),
              const SizedBox(height: 10),
              TextField(
                controller: otpController,
                decoration: const InputDecoration(
                  labelText: "OTP",
                  border: OutlineInputBorder(),
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: sendOtp,
              child: const Text("Resend OTP"),
            ),
            ElevatedButton(
              onPressed: verifyOtp,
              child: const Text("Verify & Register"),
            )
          ],
        );
      },
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    IconData? icon,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon:
        icon != null ? Icon(icon, color: Colors.white70) : const SizedBox(),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        errorStyle: const TextStyle(color: Colors.redAccent),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white70),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white38),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      style: const TextStyle(color: Colors.white),
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
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(40),
              margin: const EdgeInsets.symmetric(horizontal: 60),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Text(
                    "Partner Registration",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  buildTextField(
                    controller: nameController,
                    label: "Full Name",
                    icon: Icons.person,
                    validator: (v) => v!.isEmpty ? "Full Name required" : null,
                  ),

                  const SizedBox(height: 15),

                  buildTextField(
                    controller: businessController,
                    label: "Business Name",
                    icon: Icons.business,
                    validator: (v) =>
                    v!.isEmpty ? "Business Name required" : null,
                  ),

                  const SizedBox(height: 15),

                  buildTextField(
                    controller: emailController,
                    label: "Email",
                    icon: Icons.email,
                    validator: (v) => v!.isEmpty ? "Email required" : null,
                  ),

                  const SizedBox(height: 15),

                  buildTextField(
                    controller: passwordController,
                    label: "Password",
                    icon: Icons.lock,
                    obscure: true,
                    validator: (v) =>
                    v!.isEmpty ? "Password required" : null,
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: register,
                    child: const Text("Register"),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WebLoginPage()),
                      );
                    },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}