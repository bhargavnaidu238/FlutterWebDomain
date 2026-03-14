import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_PGs_page.dart';
import 'package:hotel_booking_app/services/api_service.dart';

class ViewPGsPage extends StatefulWidget {
  final String partnerId;
  const ViewPGsPage({required this.partnerId, Key? key}) : super(key: key);

  @override
  State<ViewPGsPage> createState() => _ViewPGsPageState();
}

class _ViewPGsPageState extends State<ViewPGsPage> {
  List<Map<String, String>> pgs = [];
  List<String> selectedPGs = [];
  bool isLoading = true;
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    fetchPgs();
  }

  Future<void> fetchPgs() async {
    setState(() => isLoading = true);
    pgs.clear();

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/webviewpgs'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: "partner_id=${Uri.encodeComponent(widget.partnerId)}",
      );

      String body = res.body.trim();
      if (body.contains("status=success&data=")) {
        String dataPart = body.split("data=").length > 1 ? body.split("data=")[1] : '';
        if (dataPart.isNotEmpty) {
          List<String> rows = dataPart.trim().split("\n");
          for (var row in rows) {
            List<String> cols = row.split("|").map((e) => e.trim()).toList();

            // Strictly index-based mapping matching the Java View Handler
            if (cols.length >= 20) {
              pgs.add({
                "pg_id": cols[0],
                "partner_id": cols[1],
                "pg_name": cols[2],
                "pg_type": cols[3],
                "room_type": cols[4],
                "address": cols[5],
                "city": cols[6],
                "state": cols[7],
                "country": cols[8],
                "pincode": cols[9],
                "total_single_sharing_rooms": cols[10],
                "total_double_sharing_rooms": cols[11],
                "total_three_sharing_rooms": cols[12],
                "total_four_sharing_rooms": cols[13],
                "total_five_sharing_rooms": cols[14],
                "hotel_location": cols[15],
                "available_rooms": cols[16],
                "room_price": cols[17],
                "amenities": cols[18],
                "policies": cols[19],
                "rating": cols[20],
                "pg_contact": cols[21],
                "about_this_pg": cols[22],
                "pg_images": cols[23],
                "status": cols[24],
              });
            }
          }
        }
      }
    } catch (e) {
      _showSnack("Error fetching pgs: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;
      selectedPGs = selectAll ? pgs.map((h) => h['pg_id']!).toList() : [];
    });
  }

  void togglePGSelection(String pgId, bool? value) {
    setState(() {
      if (value == true) selectedPGs.add(pgId);
      else selectedPGs.remove(pgId);
      selectAll = selectedPGs.length == pgs.length;
    });
  }

  Future<void> confirmDelete() async {
    if (selectedPGs.isEmpty) return;
    bool confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete ${selectedPGs.length} PG(s)?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      final idsStr = selectedPGs.join(",");
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/webviewpgs'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: "pg_ids=${Uri.encodeComponent(idsStr)}",
      );
      fetchPgs();
      selectedPGs.clear();
      selectAll = false;
      _showSnack("PGs deleted successfully.");
    } catch (e) {
      _showSnack("Error deleting: $e");
    }
  }

  Widget buildPGRow(Map<String, String> pg) {
    String fullAddress = "${pg['address']}, ${pg['city']}, ${pg['state']}, ${pg['country']} - ${pg['pincode']}";
    bool isSelected = selectedPGs.contains(pg['pg_id']);

    return Card(
      color: Colors.white.withOpacity(0.15),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (v) => togglePGSelection(pg['pg_id']!, v),
              activeColor: Colors.white,
              checkColor: Colors.green.shade900,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pg['pg_name'] ?? 'Unnamed PG', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 5),
                  Text("Type: ${pg['pg_type']} | Contact: ${pg['pg_contact']}", style: const TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 5),
                  Text(fullAddress, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Divider(color: Colors.white24),
                  Text("Rooms: ${pg['room_type']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  Text("Price: ₹${pg['room_price']}", style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 5),
                  Text("About: ${pg['about_this_pg']}", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(5)),
                        child: Text(pg['status'] ?? 'Active', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(pg['rating'] ?? "0.0", style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF64DD17)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                const Text("Manage PGs", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                if (selectedPGs.length == 1)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      final pg = pgs.firstWhere((h) => h['pg_id'] == selectedPGs[0]);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddPGSPage(partnerId: widget.partnerId, pgData: pg))).then((_) => fetchPgs());
                    },
                  ),
                if (selectedPGs.isNotEmpty)
                  IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: confirmDelete),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(value: selectAll, onChanged: toggleSelectAll, activeColor: Colors.white, checkColor: Colors.green),
                const Text("Select All", style: TextStyle(color: Colors.white)),
              ],
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : pgs.isEmpty
                  ? const Center(child: Text("No PGs registered yet.", style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                itemCount: pgs.length,
                itemBuilder: (context, i) => buildPGRow(pgs[i]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.green),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPGSPage(partnerId: widget.partnerId))).then((_) => fetchPgs()),
      ),
    );
  }
}