import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'web_dashboard_page.dart';
import 'package:hotel_booking_app/services/api_service.dart';

enum ProfileMenuOption { viewProfile, editProfile, changePassword, deleteAccount }

class WebProfilePage extends StatefulWidget {
  final String email;
  final Map<String, String> partnerDetails;

  const WebProfilePage({
    required this.email,
    required this.partnerDetails,
    Key? key,
  }) : super(key: key);

  @override
  State<WebProfilePage> createState() => _WebProfilePageState();
}

class _WebProfilePageState extends State<WebProfilePage> {
  Map<String, TextEditingController> controllers = {};
  bool isLoading = true;
  Map<String, String> profileData = {};
  ProfileMenuOption selectedOption = ProfileMenuOption.viewProfile;

  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();

  bool showCurrentPassword = false;
  bool showNewPassword = false;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  // ================= FETCH PROFILE =================

  Future<void> fetchProfile() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/webgetprofile');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
        'email=${Uri.encodeComponent(widget.email.trim().toLowerCase())}',
      );

      final decoded = jsonDecode(res.body);

      if (res.statusCode == 200 && decoded['status'] == 'success') {
        final Map<String, dynamic> data = decoded['data'];

        setState(() {
          profileData =
              data.map((k, v) => MapEntry(k.toLowerCase(), v?.toString() ?? ''));

          controllers.clear();
          for (var key in profileData.keys) {
            controllers[key] =
                TextEditingController(text: profileData[key] ?? '');
          }

          isLoading = false;
        });
      } else {
        showSnack(decoded['message'] ?? 'Error fetching profile');
        setState(() => isLoading = false);
      }
    } catch (e) {
      showSnack("Error fetching profile: $e");
      setState(() => isLoading = false);
    }
  }

  // ================= UPDATE PROFILE =================

  Future<void> saveProfile() async {
    try {
      Map<String, String> updatedData = {};

      for (var key in profileData.keys) {
        if (!['email', 'user_status', 'registration_date', 'partner_id']
            .contains(key)) {
          updatedData[key] = controllers[key]?.text.trim() ?? '';
        }
      }

      updatedData['email'] = widget.email.trim().toLowerCase();

      final url = Uri.parse('${ApiConfig.baseUrl}/webupdateprofile');

      final bodyString = updatedData.entries
          .map((e) =>
      "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}")
          .join("&");

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: bodyString,
      );

      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {
        showSnack("Profile updated successfully");
        fetchProfile();
      } else {
        showSnack(data['message'] ?? "Update failed");
      }
    } catch (e) {
      showSnack("Error updating profile: $e");
    }
  }

  // ================= CHANGE PASSWORD =================

  Future<void> changePassword() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/webchangepassword');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
        "email=${Uri.encodeComponent(widget.email.trim().toLowerCase())}"
            "&currentPassword=${Uri.encodeComponent(currentPasswordController.text.trim())}"
            "&newPassword=${Uri.encodeComponent(newPasswordController.text.trim())}",
      );

      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {
        showSnack("Password updated successfully");
        currentPasswordController.clear();
        newPasswordController.clear();
      } else {
        showSnack(data['message'] ?? "Password update failed");
      }
    } catch (e) {
      showSnack("Error updating password: $e");
    }
  }

  // ================= DELETE ACCOUNT =================

  Future<void> deleteAccount() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/webdeleteprofile');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
        "email=${Uri.encodeComponent(widget.email.trim().toLowerCase())}",
      );

      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {
        showSnack("Account deactivated successfully");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  WebDashboardPage(partnerDetails: widget.partnerDetails)),
        );
      } else {
        showSnack(data['message'] ?? "Delete failed");
      }
    } catch (e) {
      showSnack("Error deleting account: $e");
    }
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ================= UI (UNCHANGED DESIGN) =================

  Widget buildFieldCard(String label, TextEditingController? controller,
      {bool isEditable = true,
        IconData? icon,
        bool obscureText = false,
        VoidCallback? toggleVisibility}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Row(
          children: [
            if (icon != null)
              Icon(icon, color: Colors.green.shade900, size: 28),
            if (icon != null) const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: !isEditable,
                obscureText: obscureText,
                decoration: InputDecoration(
                  labelText: label,
                  border: InputBorder.none,
                  suffixIcon: toggleVisibility != null
                      ? IconButton(
                    icon: Icon(obscureText
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: toggleVisibility,
                  )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRightPanel() {
    switch (selectedOption) {
      case ProfileMenuOption.editProfile:
        return Column(
          children: [
            ...profileData.keys.map((key) => buildFieldCard(
                key.replaceAll("_", " "),
                controllers[key],
                isEditable: ![
                  'email',
                  'user_status',
                  'registration_date',
                  'partner_id'
                ].contains(key))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveProfile,
              child: const Text("Save Changes"),
            ),
          ],
        );

      case ProfileMenuOption.changePassword:
        return Column(
          children: [
            buildFieldCard("Current Password", currentPasswordController,
                obscureText: !showCurrentPassword, toggleVisibility: () {
                  setState(() => showCurrentPassword = !showCurrentPassword);
                }),
            buildFieldCard("New Password", newPasswordController,
                obscureText: !showNewPassword, toggleVisibility: () {
                  setState(() => showNewPassword = !showNewPassword);
                }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: changePassword,
              child: const Text("Update Password"),
            ),
          ],
        );

      case ProfileMenuOption.deleteAccount:
        return Column(
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: deleteAccount,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete Account"),
            ),
          ],
        );

      case ProfileMenuOption.viewProfile:
      default:
        return Column(
          children: profileData.keys
              .map((key) =>
              buildFieldCard(key.replaceAll("_", " "), controllers[key],
                  isEditable: false))
              .toList(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      WebDashboardPage(partnerDetails: widget.partnerDetails)),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
        children: [
          Container(
            width: 250,
            color: Colors.green.shade50,
            child: ListView(
              children: [
                ListTile(
                  title: const Text("View Profile"),
                  onTap: () => setState(() =>
                  selectedOption = ProfileMenuOption.viewProfile),
                ),
                ListTile(
                  title: const Text("Edit Profile"),
                  onTap: () => setState(() =>
                  selectedOption = ProfileMenuOption.editProfile),
                ),
                ListTile(
                  title: const Text("Change Password"),
                  onTap: () => setState(() => selectedOption =
                      ProfileMenuOption.changePassword),
                ),
                ListTile(
                  title: const Text("Delete Account"),
                  onTap: () => setState(() =>
                  selectedOption = ProfileMenuOption.deleteAccount),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: buildRightPanel(),
            ),
          ),
        ],
      ),
    );
  }
}
