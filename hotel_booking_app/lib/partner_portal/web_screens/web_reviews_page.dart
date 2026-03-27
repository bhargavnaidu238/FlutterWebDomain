import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hotel_booking_app/services/api_service.dart';
import 'web_dashboard_page.dart';

class WebReviewsPage extends StatefulWidget {
  final String email;
  final Map<String, String> partnerDetails;

  const WebReviewsPage({required this.email, required this.partnerDetails, Key? key}) : super(key: key);

  @override
  State<WebReviewsPage> createState() => _WebReviewsPageState();
}

class _WebReviewsPageState extends State<WebReviewsPage> {
  List<dynamic> reviews = [];
  bool isLoading = true;
  double averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/webgetreviews');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'email=${Uri.encodeComponent(widget.email.trim().toLowerCase())}',
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['status'] == 'success') {
          setState(() {
            reviews = decoded['data'];
            if (reviews.isNotEmpty) {
              double sum = 0;
              for (var r in reviews) {
                sum += (r['rating'] ?? 0);
              }
              averageRating = sum / reviews.length;
            }
            isLoading = false;
          });
        } else {
          showSnack(decoded['message'] ?? 'No reviews found');
          setState(() => isLoading = false);
        }
      } else {
        showSnack("Failed to load: ${res.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      showSnack("Error fetching reviews: $e");
      setState(() => isLoading = false);
    }
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget buildReviewCard(Map<String, dynamic> review) {
    // Correctly handles the property type badge
    bool isHotel = review['property_type'] == 'Hotel';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shadowColor: Colors.greenAccent.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    review['property_name'] ?? "Unknown Property",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHotel ? Colors.green.shade100 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isHotel ? "HOTEL" : "PG",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isHotel ? Colors.green.shade800 : Colors.orange.shade900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < (review['rating'] ?? 0) ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Text(
                review['comment'] ?? "No comment provided.",
                style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "User ID: ${review['user_id']}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  review['created_at']?.split('T')[0] ?? "",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSidebarContent() {
    return Column(
      children: [
        const SizedBox(height: 40),
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.green.shade700,
          child: const Icon(Icons.rate_review, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        Text("Overall Rating", style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold)),
        Text(
          averageRating.toStringAsFixed(1),
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green.shade900),
        ),
        const Divider(indent: 20, endIndent: 20, height: 40),
        ListTile(
          leading: Icon(Icons.dashboard, color: Colors.green.shade900),
          title: const Text("Dashboard"),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => WebDashboardPage(partnerDetails: widget.partnerDetails)),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.refresh, color: Colors.green.shade900),
          title: const Text("Refresh Reviews"),
          onTap: () {
            setState(() => isLoading = true);
            fetchReviews();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Property Reviews"),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => WebDashboardPage(partnerDetails: widget.partnerDetails)),
            );
          },
        ),
      ),
      // Drawer added for mobile users to see the overall rating
      drawer: isMobile ? Drawer(child: buildSidebarContent()) : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Row(
        children: [
          if (!isMobile)
            Container(
              width: 250,
              color: Colors.green.shade50,
              child: buildSidebarContent(),
            ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: reviews.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.comment_bank_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text("No reviews found for your properties.",
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(25),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  return buildReviewCard(reviews[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}