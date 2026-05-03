import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Add_PGs_page.dart';
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
    if (!mounted) return;
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

            // Updated indices based on Latitude (10) and Longitude (11)
            // Previous columns 10-14 shift to 12-16
            pgs.add({
              "pg_id": cols.length > 0 ? cols[0] : '',
              "partner_id": cols.length > 1 ? cols[1] : '',
              "pg_name": cols.length > 2 ? cols[2] : '',
              "pg_type": cols.length > 3 ? cols[3] : '',
              "room_type": cols.length > 4 ? cols[4] : '',
              "address": cols.length > 5 ? cols[5] : '',
              "city": cols.length > 6 ? cols[6] : '',
              "state": cols.length > 7 ? cols[7] : '',
              "country": cols.length > 8 ? cols[8] : '',
              "pincode": cols.length > 9 ? cols[9] : '',
              "latitude": cols.length > 10 ? cols[10] : '',
              "longitude": cols.length > 11 ? cols[11] : '',
              "total_single_sharing_rooms": cols.length > 12 ? cols[12] : '0',
              "total_double_sharing_rooms": cols.length > 13 ? cols[13] : '0',
              "total_three_sharing_rooms": cols.length > 14 ? cols[14] : '0',
              "total_four_sharing_rooms": cols.length > 15 ? cols[15] : '0',
              "total_five_sharing_rooms": cols.length > 16 ? cols[16] : '0',
              "available_rooms": cols.length > 17 ? cols[17] : '0',
              "room_price": cols.length > 18 ? cols[18] : '0',
              "amenities": cols.length > 19 ? cols[19] : '',
              "policies": cols.length > 20 ? cols[20] : '',
              "avg_rating": cols.length > 21 ? cols[21] : '0.0',
              "total_reviews": cols.length > 22 ? cols[22] : '0',
              "pg_contact": cols.length > 23 ? cols[23] : '',
              "about_this_pg": cols.length > 24 ? cols[24] : '',
              "pg_images": cols.length > 25 ? cols[25] : '',
              "status": cols.length > 26 ? cols[26] : '',
              "total_Rooms": _calculateTotalFromCols(cols),
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching pgs: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _calculateTotalFromCols(List<String> cols) {
    try {
      // Adjusted indices for room counts (12, 13, 14, 15, 16)
      if (cols.length < 17) return "0";
      int total = int.parse(cols[12]) +
          int.parse(cols[13]) +
          int.parse(cols[14]) +
          int.parse(cols[15]) +
          int.parse(cols[16]);
      return total.toString();
    } catch (_) {
      return "0";
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
      selectAll = selectedPGs.length == pgs.length && pgs.isNotEmpty;
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
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PGs deleted successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting: $e")),
      );
    }
  }

  Widget buildPGRow(Map<String, String> pg) {
    String fullAddress = "${pg['address']}, ${pg['city']}, ${pg['state']} - ${pg['pincode']}";
    bool isSelected = selectedPGs.contains(pg['pg_id']);

    return Card(
      color: Colors.white.withOpacity(0.15),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => togglePGSelection(pg['pg_id']!, !isSelected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (v) => togglePGSelection(pg['pg_id']!, v),
                activeColor: Colors.green.shade900,
                side: const BorderSide(color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pg['pg_name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    _infoRow(Icons.category, "Type: ${pg['pg_type']}"),
                    _infoRow(Icons.location_on, fullAddress),
                    _infoRow(Icons.hotel, "Total Rooms: ${pg['total_Rooms']} | ₹${pg['room_price']}"),
                    _infoRow(Icons.check_circle, "Status: ${pg['status']}"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade300, size: 18),
                        const SizedBox(width: 4),
                        Text("${pg['avg_rating']} (${pg['total_reviews']} reviews)", style: const TextStyle(color: Colors.white)),
                        const SizedBox(width: 15),
                        const Icon(Icons.phone, color: Colors.white70, size: 18),
                        const SizedBox(width: 4),
                        Text(pg['pg_contact'] ?? "N/A", style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF64DD17)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 24),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                        Text("View PGs", style: TextStyle(fontSize: isSmallScreen ? 20 : 26, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionButton(
                          onPressed: selectedPGs.length == 1 ? _handleEdit : null,
                          icon: Icons.edit,
                          label: "Edit",
                        ),
                        const SizedBox(width: 8),
                        _actionButton(
                          onPressed: selectedPGs.isNotEmpty ? confirmDelete : null,
                          icon: Icons.delete,
                          label: "Delete",
                          color: Colors.redAccent.withOpacity(0.8),
                        ),
                        const SizedBox(width: 8),
                        _actionButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPGSPage(partnerId: widget.partnerId))).then((_) => fetchPgs()),
                          icon: Icons.add,
                          label: "Add",
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: selectAll,
                      onChanged: toggleSelectAll,
                      activeColor: Colors.green.shade900,
                      side: const BorderSide(color: Colors.white),
                    ),
                    const Text("Select All", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    if (selectedPGs.isNotEmpty)
                      Text("${selectedPGs.length} Selected", style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : pgs.isEmpty
                      ? const Center(child: Text("No PG's found.", style: TextStyle(color: Colors.white, fontSize: 18)))
                      : ListView.builder(
                    itemCount: pgs.length,
                    itemBuilder: (context, i) => buildPGRow(pgs[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleEdit() {
    final pg = pgs.firstWhere((h) => h['pg_id'] == selectedPGs[0]);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPGSPage(partnerId: widget.partnerId, pgData: pg),
      ),
    ).then((value) {
      fetchPgs();
      selectedPGs.clear();
      selectAll = false;
    });
  }

  Widget _actionButton({required VoidCallback? onPressed, required IconData icon, required String label, Color? color}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.white10,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}