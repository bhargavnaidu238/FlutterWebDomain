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

  bool isLoading = false;

  // Step 1: Trigger OTP via Email
  Future<void> sendOtpAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/send-email-otp');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'email=${Uri.encodeComponent(emailController.text.trim())}',
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['status'] == 'success') {
        final userData = {
          'partner_name': nameController.text.trim(),
          'business_name': businessController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'contact_number': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'country': countryController.text.trim(),
          'pincode': pincodeController.text.trim(),
          'gst_number': gstController.text.trim(),
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(userData: userData),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to send OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
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
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : const SizedBox(),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        errorStyle: const TextStyle(color: Colors.redAccent),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white70), borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white38), borderRadius: BorderRadius.circular(12)),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF00C853), Color(0xFFB2FF59)]),
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
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  const Text("Partner Registration", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 30),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth > 900 ? 380.0 : double.infinity;
                      return Wrap(
                        spacing: 25,
                        runSpacing: 20,
                        children: [
                          SizedBox(width: width, child: buildTextField(controller: nameController, label: "Full Name", icon: Icons.person, validator: (v) => v!.isEmpty ? "Required" : null)),
                          SizedBox(width: width, child: buildTextField(controller: businessController, label: "Business Name", icon: Icons.business, validator: (v) => v!.isEmpty ? "Required" : null)),
                          SizedBox(width: width, child: buildTextField(controller: emailController, label: "Email", icon: Icons.email, validator: (v) => v!.isEmpty ? "Required" : null)),
                          SizedBox(width: width, child: buildTextField(controller: passwordController, label: "Password", icon: Icons.lock, obscure: true, validator: (v) => v!.isEmpty ? "Required" : null)),
                          SizedBox(width: width, child: buildTextField(controller: phoneController, label: "Phone Number", icon: Icons.phone, validator: (v) => v!.length != 10 ? "10 digits" : null)),
                          SizedBox(width: width, child: buildTextField(controller: addressController, label: "Address", icon: Icons.home, validator: (v) => v!.isEmpty ? "Required" : null)),
                          SizedBox(width: width, child: buildTextField(controller: cityController, label: "City", icon: Icons.location_city, validator: (v) => v!.isEmpty ? "Required" : null)),
                          SizedBox(width: width, child: buildTextField(controller: stateController, label: "State", icon: Icons.map, validator: (v) => v!.isEmpty ? "Required" : null)),
                          SizedBox(width: width, child: buildTextField(controller: countryController, label: "Country", icon: Icons.flag, validator: (v) => v!.isEmpty ? "Required" : null)),
                          SizedBox(width: width, child: buildTextField(controller: pincodeController, label: "Pincode", icon: Icons.pin_drop, validator: (v) => v!.length != 6 ? "6 digits" : null)),
                          SizedBox(width: width, child: buildTextField(controller: gstController, label: "GST Number", icon: Icons.receipt_long, validator: (v) => v!.isEmpty ? "Required" : null)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                    onPressed: sendOtpAndProceed,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(260, 50),
                      backgroundColor: const Color(0xFF00C853),
                    ),
                    child: const Text("Next", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WebLoginPage())),
                    child: const Text("Already have an account? Login", style: TextStyle(color: Colors.white70)),
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

// --- OTP VERIFICATION PAGE ---
class OTPVerificationPage extends StatefulWidget {
  final Map<String, String> userData;
  const OTPVerificationPage({Key? key, required this.userData}) : super(key: key);

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  Future<void> verifyAndRegister() async {
    if (otpController.text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      // Step 2: Verify OTP
      final verifyUrl = Uri.parse('${ApiConfig.baseUrl}/verify-email-otp');
      final verifyRes = await http.post(
        verifyUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'email=${Uri.encodeComponent(widget.userData['email']!)}&otp=${Uri.encodeComponent(otpController.text.trim())}',
      );

      final verifyData = json.decode(verifyRes.body);

      if (verifyRes.statusCode == 200 && verifyData['status'] == 'success') {
        // Step 3: OTP Verified, now perform actual Registration
        final regUrl = Uri.parse('${ApiConfig.baseUrl}/registerlogin');
        final body = widget.userData.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

        final regRes = await http.post(
          regUrl,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body,
        );

        final regData = json.decode(regRes.body);

        if (regRes.statusCode == 200 && regData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Successful! Welcome Email Sent.")));
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WebLoginPage()), (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(regData['message'] ?? "Registration failed after verification")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(verifyData['message'] ?? "Invalid OTP")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00C853), Color(0xFFB2FF59)])),
        alignment: Alignment.center,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("OTP Verification", style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: otpController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 22),
                decoration: InputDecoration(
                  hintText: "Enter OTP",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white38)),
                ),
              ),
              const SizedBox(height: 30),
              isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton(
                onPressed: verifyAndRegister,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), minimumSize: const Size(double.infinity, 50)),
                child: const Text("Register", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}