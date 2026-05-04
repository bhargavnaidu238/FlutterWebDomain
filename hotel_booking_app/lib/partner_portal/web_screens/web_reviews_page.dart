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
  List<dynamic> allReviews = [];
  List<dynamic> displayedReviews = [];
  bool isLoading = true;
  double averageRating = 0.0;

  // Filter States
  String filterProperty = "All";
  String sortOrder = "Recent";

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
            allReviews = decoded['data'];
            applyFilters();
            if (allReviews.isNotEmpty) {
              double sum = 0;
              for (var r in allReviews) {
                sum += (r['rating'] ?? 0);
              }
              averageRating = sum / allReviews.length;
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

  void applyFilters() {
    setState(() {
      displayedReviews = allReviews.where((r) {
        if (filterProperty == "All") return true;
        return r['property_type'] == filterProperty;
      }).toList();

      if (sortOrder == "Recent") {
        displayedReviews.sort((a, b) => b['created_at'].compareTo(a['created_at']));
      } else if (sortOrder == "High to Low") {
        displayedReviews.sort((a, b) => b['rating'].compareTo(a['rating']));
      } else if (sortOrder == "Low to High") {
        displayedReviews.sort((a, b) => a['rating'].compareTo(b['rating']));
      }
    });
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget buildReviewCard(Map<String, dynamic> review) {
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
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      review['user_name'] ?? "Anonymous User",
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
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

  // Filter Bar Widget
  Widget buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.green.shade50,
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        children: [
          DropdownButton<String>(
            value: filterProperty,
            underline: Container(),
            icon: Icon(Icons.filter_list, color: Colors.green.shade700),
            items: ["All", "Hotel", "PG"].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text("Type: $value"));
            }).toList(),
            onChanged: (val) {
              filterProperty = val!;
              applyFilters();
            },
          ),
          DropdownButton<String>(
            value: sortOrder,
            underline: Container(),
            icon: Icon(Icons.sort, color: Colors.green.shade700),
            items: ["Recent", "High to Low", "Low to High"].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text("Sort: $value"));
            }).toList(),
            onChanged: (val) {
              sortOrder = val!;
              applyFilters();
            },
          ),
        ],
      ),
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
            child: Column(
              children: [
                buildFilterBar(),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: displayedReviews.isEmpty
                        ? const Center(
                      child: Text("No reviews match your filter.",
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(25),
                      itemCount: displayedReviews.length,
                      itemBuilder: (context, index) {
                        return buildReviewCard(displayedReviews[index]);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}