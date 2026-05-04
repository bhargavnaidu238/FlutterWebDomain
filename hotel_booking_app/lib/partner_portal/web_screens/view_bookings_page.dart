import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:hotel_booking_app/services/api_service.dart';

class BookingPage extends StatefulWidget {
  final String partnerId;
  const BookingPage({required this.partnerId, Key? key}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> filteredBookings = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  String statusFilter = 'All';

  final ScrollController horizontalController = ScrollController();
  final ScrollController verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ========================== Fetch User Bookings =========================
  Future<void> fetchBookings() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/webgetPartnerBookings?partnerId=${widget.partnerId}'),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          bookings = List<Map<String, dynamic>>.from(data);
          filteredBookings = bookings;
          applyFilters();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ========================== Confirmation Dialog =========================
  Future<void> _confirmAndStatusUpdate(String bookingId, String newStatus) async {
    String displayStatus = newStatus.replaceAll('_', ' ');

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Booking Status!!!"),
          content: Text("Are you sure you want to change this booking status to $displayStatus?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await updateBookingStatus(bookingId, newStatus);
    }
  }

  // ========================== Update Logic =========================
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/webupdateBookingStatus'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          "bookingId": bookingId,
          "status": newStatus,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          await fetchBookings();
        } else {
          _showError(result['message']);
        }
      }
    } catch (e) {
      _showError("Failed to update booking.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void applyFilters() {
    String searchText = searchController.text.toLowerCase().trim();
    setState(() {
      filteredBookings = bookings.where((booking) {
        final statusValue = (booking['booking_status'] ?? '').toString().trim().toLowerCase();
        final statusMatches = statusFilter == 'All' || statusValue == statusFilter.toLowerCase();
        final searchMatches = booking.values.any((val) {
          if (val == null) return false;
          return val.toString().toLowerCase().contains(searchText);
        });
        return statusMatches && searchMatches;
      }).toList();
    });
  }

  Widget buildDataTable() {
    if (filteredBookings.isEmpty) {
      return const Center(child: Text("No bookings found"));
    }

    final columns = filteredBookings.first.keys.map((key) {
      return DataColumn(label: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)));
    }).toList()..add(const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))));

    final rows = filteredBookings.map((booking) {
      final status = (booking['booking_status']?.toString() ?? '').toLowerCase();
      final bookingId = booking['booking_id']?.toString() ?? '';

      DateTime? checkInDate = _parseDate(booking['check_in_date']);
      DateTime? checkOutDate = _parseDate(booking['check_out_date']);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return DataRow(
        color: MaterialStateProperty.resolveWith<Color?>(
              (_) => status == 'cancelled' ? Colors.grey.withOpacity(0.2) : Colors.white,
        ),
        cells: booking.keys.map((key) {
          return DataCell(Text(booking[key]?.toString() ?? '', style: const TextStyle(fontSize: 14)));
        }).toList()
          ..add(
            DataCell(
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _confirmAndStatusUpdate(bookingId, value),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'CONFIRMED',
                    enabled: status == 'pending',
                    child: const Text('Confirm'),
                  ),
                  PopupMenuItem(
                    value: 'CANCELLED',
                    enabled: status == 'pending' || status == 'confirmed',
                    child: const Text('Cancel'),
                  ),
                  PopupMenuItem(
                    value: 'CHECKED_IN',
                    enabled: (status == 'pending' && checkInDate != null && checkInDate.isAtSameMomentAs(today)) ||
                        (status == 'confirmed'),
                    child: const Text('Check-in'),
                  ),
                  PopupMenuItem(
                    value: 'CHECKED_OUT',
                    enabled: (status == 'confirmed' || status == 'checked_in') &&
                        checkOutDate != null && !checkOutDate.isAfter(today),
                    child: const Text('Check-out'),
                  ),
                  PopupMenuItem(
                    value: 'COMPLETED',
                    enabled: status == 'confirmed' || status == 'checked_in' || status == 'checked_out',
                    child: const Text('Completed'),
                  ),
                ],
              ),
            ),
          ),
      );
    }).toList();

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}, overscroll: false),
      child: Scrollbar(
        controller: horizontalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: horizontalController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.green.shade200.withOpacity(0.4)),
              columns: columns,
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }

  DateTime? _parseDate(dynamic dateVal) {
    if (dateVal == null || dateVal.toString().isEmpty) return null;
    try {
      String dateStr = dateVal.toString().trim().split(" ").first;
      return DateTime.tryParse(dateStr);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Bookings'), backgroundColor: Colors.green.shade700),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lime.shade100.withOpacity(0.3), Colors.lime.shade300.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => applyFilters(),
                      decoration: InputDecoration(
                        hintText: 'Search bookings…',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: statusFilter,
                    items: ['All', 'Pending', 'Confirmed', 'Cancelled', 'Completed', 'Checked_In', 'Checked_Out']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) {
                      setState(() {
                        statusFilter = value!;
                        applyFilters();
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : buildDataTable()),
          ],
        ),
      ),
    );
  }
}