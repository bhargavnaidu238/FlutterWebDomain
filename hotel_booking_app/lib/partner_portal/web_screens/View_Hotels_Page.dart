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

            // Re-aligned to match the DB schema order provided (22 columns)
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
              "hotel_location": cols.length > 10 ? cols[10] : '',
              "total_rooms": cols.length > 11 ? cols[11] : '0',
              "available_rooms": cols.length > 12 ? cols[12] : '0',
              "room_price": cols.length > 13 ? cols[13] : '0',
              "amenities": cols.length > 14 ? cols[14] : '',
              "policies": cols.length > 15 ? cols[15] : '',
              "rating": cols.length > 16 ? cols[16] : '0.0',
              "hotel_contact": cols.length > 17 ? cols[17] : '',
              "about_this_property": cols.length > 18 ? cols[18] : '',
              "hotel_images": cols.length > 19 ? cols[19] : '',
              "customization": cols.length > 20 ? cols[20] : 'No',
              "status": cols.length > 21 ? cols[21] : '',
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching hotels: $e")),
      );
    } finally {
      setState(() => isLoading = false);
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
      selectAll = selectedHotels.length == hotels.length;
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
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
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
    String fullAddress =
        "${hotel['address']}, ${hotel['city']}, ${hotel['state']}, ${hotel['country']} - ${hotel['pincode']}";
    bool isSelected = selectedHotels.contains(hotel['hotel_id']);

    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (v) => toggleHotelSelection(hotel['hotel_id']!, v),
              activeColor: Colors.green.shade900,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hotel['hotel_name'] ?? 'Unnamed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(fullAddress, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text("Rooms: ${hotel['total_rooms'] ?? '0'} | Price: ₹${hotel['room_price'] ?? '0'}", style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text("Hotel Type: ${hotel['hotel_type'] ?? ''}", style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text("Amenities: ${hotel['amenities'] ?? ''}", style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text("About This Hotel: ${hotel['about_this_property'] ?? ''}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text("Status: ${hotel['status'] ?? ''}", style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade300, size: 18),
                      const SizedBox(width: 4),
                      Text(hotel['rating'] ?? "0.0", style: const TextStyle(color: Colors.white70)),
                      const SizedBox(width: 15),
                      Icon(Icons.phone, color: Colors.white70, size: 18),
                      const SizedBox(width: 4),
                      Text(hotel['hotel_contact'] ?? "N/A", style: const TextStyle(color: Colors.white70)),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                const SizedBox(width: 8),
                const Text("View Hotels", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: selectedHotels.length == 1
                      ? () {
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
                      : null,
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text("Edit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white24,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: selectedHotels.isNotEmpty ? confirmDelete : null,
                  icon: const Icon(Icons.delete_forever, size: 20),
                  label: const Text("Delete"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.8),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddHotelsPage(partnerId: widget.partnerId))),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Add Hotel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(value: selectAll, onChanged: toggleSelectAll, activeColor: Colors.green.shade900),
                const Text("Select All", style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
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
    );
  }
}