import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_hotels_page.dart';
import 'package:hotel_booking_app/services/api_service.dart';

class ViewHotelsPage extends StatefulWidget {
  final String partnerId;
  const ViewHotelsPage({required this.partnerId, Key? key}) : super(key: key);

  @override
  State<ViewHotelsPage> createState() => _ViewHotelsPageState();
}

class _ViewHotelsPageState extends State<ViewHotelsPage> {
  List<Map<String, String>> hotels = [];
  List<String> selectedHotels = [];
  bool isLoading = true;
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    fetchHotels();
  }

  Future<void> fetchHotels() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    hotels.clear();

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/webviewhotels'),
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

            // UPDATED column mapping based on latitude and longitude indices
            hotels.add({
              "hotel_id": cols.length > 0 ? cols[0] : '',
              "partner_id": cols.length > 1 ? cols[1] : '',
              "hotel_name": cols.length > 2 ? cols[2] : '',
              "hotel_type": cols.length > 3 ? cols[3] : '',
              "room_type": cols.length > 4 ? cols[4] : '',
              "address": cols.length > 5 ? cols[5] : '',
              "city": cols.length > 6 ? cols[6] : '',
              "state": cols.length > 7 ? cols[7] : '',
              "country": cols.length > 8 ? cols[8] : '',
              "pincode": cols.length > 9 ? cols[9] : '',
              "latitude": cols.length > 10 ? cols[10] : '',   // New column
              "longitude": cols.length > 11 ? cols[11] : '',  // New column
              "total_rooms": cols.length > 12 ? cols[12] : '0',
              "available_rooms": cols.length > 13 ? cols[13] : '0',
              "room_price": cols.length > 14 ? cols[14] : '0',
              "amenities": cols.length > 15 ? cols[15] : '',
              "policies": cols.length > 16 ? cols[16] : '',
              "hotel_contact": cols.length > 17 ? cols[17] : '',
              "about_this_property": cols.length > 18 ? cols[18] : '',
              "hotel_images": cols.length > 19 ? cols[19] : '',
              "customization": cols.length > 20 ? cols[20] : 'No',
              "status": cols.length > 21 ? cols[21] : '',
              "avg_rating": cols.length > 22 ? cols[22] : '0.0',
              "total_reviews": cols.length > 23 ? cols[23] : '0',
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching hotels: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;
      selectedHotels = selectAll ? hotels.map((h) => h['hotel_id']!).toList() : [];
    });
  }

  void toggleHotelSelection(String hotelId, bool? value) {
    setState(() {
      if (value == true) selectedHotels.add(hotelId);
      else selectedHotels.remove(hotelId);
      selectAll = selectedHotels.length == hotels.length && hotels.isNotEmpty;
    });
  }

  Future<void> confirmDelete() async {
    if (selectedHotels.isEmpty) return;

    bool confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete ${selectedHotels.length} hotel(s)?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      final idsStr = selectedHotels.join(",");
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/webviewhotels'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: "hotel_ids=${Uri.encodeComponent(idsStr)}",
      );

      fetchHotels();
      selectedHotels.clear();
      selectAll = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hotels deleted successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting: $e")),
      );
    }
  }

  Widget buildHotelRow(Map<String, String> hotel) {
    String fullAddress = "${hotel['address']}, ${hotel['city']}, ${hotel['state']} - ${hotel['pincode']}";
    bool isSelected = selectedHotels.contains(hotel['hotel_id']);

    return Card(
      color: Colors.white.withOpacity(0.15),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => toggleHotelSelection(hotel['hotel_id']!, !isSelected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (v) => toggleHotelSelection(hotel['hotel_id']!, v),
                activeColor: Colors.green.shade900,
                side: const BorderSide(color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotel['hotel_name'] ?? 'Unnamed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    _infoRow(Icons.business, "Type: ${hotel['hotel_type']}"),
                    _infoRow(Icons.location_on, fullAddress),
                    _infoRow(Icons.king_bed, "Rooms: ${hotel['total_rooms']} | Price: ₹${hotel['room_price']}"),
                    _infoRow(Icons.check_circle, "Status: ${hotel['status']}"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade300, size: 18),
                        const SizedBox(width: 4),
                        Text("${hotel['avg_rating']} (${hotel['total_reviews']} reviews)", style: const TextStyle(color: Colors.white)),
                        const SizedBox(width: 15),
                        const Icon(Icons.phone, color: Colors.white70, size: 18),
                        const SizedBox(width: 4),
                        Text(hotel['hotel_contact'] ?? "N/A", style: const TextStyle(color: Colors.white)),
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
                        Text("View Hotels", style: TextStyle(fontSize: isSmallScreen ? 20 : 26, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionButton(
                          onPressed: selectedHotels.length == 1 ? _handleEdit : null,
                          icon: Icons.edit,
                          label: "Edit",
                        ),
                        const SizedBox(width: 8),
                        _actionButton(
                          onPressed: selectedHotels.isNotEmpty ? confirmDelete : null,
                          icon: Icons.delete,
                          label: "Delete",
                          color: Colors.redAccent.withOpacity(0.8),
                        ),
                        const SizedBox(width: 8),
                        _actionButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddHotelsPage(partnerId: widget.partnerId))).then((_) => fetchHotels()),
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
                    if (selectedHotels.isNotEmpty)
                      Text("${selectedHotels.length} Selected", style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : hotels.isEmpty
                      ? const Center(child: Text("No hotels found.", style: TextStyle(color: Colors.white, fontSize: 18)))
                      : ListView.builder(
                    itemCount: hotels.length,
                    itemBuilder: (context, i) => buildHotelRow(hotels[i]),
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
    final hotel = hotels.firstWhere((h) => h['hotel_id'] == selectedHotels[0]);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddHotelsPage(partnerId: widget.partnerId, hotelData: hotel),
      ),
    ).then((value) {
      fetchHotels();
      selectedHotels.clear();
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