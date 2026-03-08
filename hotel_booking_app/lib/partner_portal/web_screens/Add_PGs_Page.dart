import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart'; // Ensure this is in pubspec.yaml
import 'View_PGs_Page.dart';
import 'package:hotel_booking_app/services/api_service.dart';

class AddPGSPage extends StatefulWidget {
  final String partnerId;
  final Map<String, dynamic>? pgData;

  const AddPGSPage({required this.partnerId, Key? key, this.pgData}) : super(key: key);

  @override
  State<AddPGSPage> createState() => _AddPGSPageState();
}

class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const GradientButton({
    required this.child,
    required this.onPressed,
    this.width,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF64DD17), Color(0xFF2E7D32)],
          ),
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onPressed,
            child: Padding(
              padding: padding,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPGSPageState extends State<AddPGSPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool isSaving = false;
  bool showSuccess = false;
  bool _isUploading = false; // Tracks background image uploads

  String? selectedPGType;
  final List<String> pgTypes = ['Gents', 'Ladies', 'Co-Live'];

  final List<String> fields = [
    "pg_name", "address", "city", "state", "country", "pincode",
    "total_single_sharing_rooms", "total_double_sharing_rooms", "total_three_sharing_rooms",
    "total_four_sharing_rooms", "total_five_sharing_rooms", "description", "pg_contact", "about_this_pg"
  ];

  final List<String> roomTypeOptions = ['Single Sharing', 'Double Sharing', 'Three Sharing', 'Four Sharing', 'Five Sharing'];
  final Map<String, bool> roomTypeSelected = {
    'Single Sharing': false, 'Double Sharing': false, 'Three Sharing': false, 'Four Sharing': false, 'Five Sharing': false,
  };
  final Map<String, TextEditingController> roomPriceControllers = {};
  final TextEditingController availableRoomsController = TextEditingController();

  final List<String> amenityOptions = [
    'AC', 'TV', 'Fridge', 'Washing Machine', 'Free WIFI', 'Power Backup', 'Attached Bathroom', 'Elevator', 'Geyser', 'Parking'
  ];

  final Map<String, bool> policies = {
    'Couple Friendly': false, 'Alcohol Allowed': false, 'Guest Should Display Govt ID\'s': false, 'Non-Refundable': false, 'Refundable': false
  };

  final TextEditingController aboutController = TextEditingController();
  final TextEditingController ratingController = TextEditingController(text: '0.0');

  final List<String> categories = [
    "Facade", "Lobby/Entrance", "Single Sharing", "Double Sharing", "Three Sharing", "Four Sharing", "Five Sharing"
  ];

  // ✅ IMPORTANT: Store Public URLs instead of bytes to prevent memory crash
  final Map<String, List<String>> uploadedUrls = {};

  final Map<String, int> categoryLimits = {
    "Facade": 10, "Lobby/Entrance": 10, "Single Sharing": 10, "Double Sharing": 10, "Three Sharing": 10, "Four Sharing": 10, "Five Sharing": 10,
  };
  final int maxFileSizeBytes = 3 * 1024 * 1024; // 3MB limit for web stability
  bool showImageSections = false;

  final TextEditingController locationController = TextEditingController();
  double? latitude;
  double? longitude;

  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOut);

    for (var field in fields) controllers[field] = TextEditingController();
    controllers['amenities'] = TextEditingController();
    for (var rt in roomTypeOptions) roomPriceControllers[rt] = TextEditingController();
    for (var c in categories) uploadedUrls[c] = [];

    if (widget.pgData != null) _populateExistingData();
  }

  void _populateExistingData() {
    final data = widget.pgData!;
    for (var f in fields) controllers[f]?.text = data[f]?.toString() ?? '';
    selectedPGType = data['pg_type'];
    final roomTypes = (data['room_type'] ?? '').split(',');
    final roomPrices = (data['room_price'] ?? '').split(',');
    for (int i = 0; i < roomTypes.length; i++) {
      final rt = roomTypes[i].trim();
      if (roomTypeOptions.contains(rt)) {
        roomTypeSelected[rt] = true;
        if (i < roomPrices.length) roomPriceControllers[rt]?.text = roomPrices[i].trim();
      }
    }
    controllers['amenities']?.text = data['amenities'] ?? '';
    for (var k in policies.keys) policies[k] = (data['policies'] ?? '').split(',').contains(k);
    aboutController.text = data['about_this_pg'] ?? '';
    ratingController.text = (data['rating'] ?? '0.0').toString();
    if ((data['hotel_location'] ?? '').contains(',')) {
      final parts = data['hotel_location']!.split(',');
      latitude = double.tryParse(parts[0]);
      longitude = double.tryParse(parts[1]);
      if (latitude != null && longitude != null) {
        locationController.text = "Lat: ${latitude!.toStringAsFixed(5)}, Lng: ${longitude!.toStringAsFixed(5)}";
      }
    }
    String existingImages = data['hotel_images'] ?? '';
    if (existingImages.isNotEmpty) {
      uploadedUrls["Facade"] = existingImages.split(',').where((s) => s.isNotEmpty).toList();
    }
    setState(() {});
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ✅ FIX: Immediate upload to cloud to prevent Java OOM
  Future<void> _pickAndUploadImages(String category) async {
    final already = uploadedUrls[category]!.length;
    final limit = categoryLimits[category] ?? 10;
    final remaining = limit - already;

    if (remaining <= 0) { _showSnack("Limit reached for $category"); return; }

    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
      if (res == null) return;

      setState(() => _isUploading = true);
      final supabase = Supabase.instance.client;

      for (var pf in res.files.take(remaining)) {
        if (pf.bytes == null) continue;
        if (pf.size > maxFileSizeBytes) { _showSnack("${pf.name} skipped (>3MB)"); continue; }

        String fileName = "${widget.partnerId}/PG_${DateTime.now().millisecondsSinceEpoch}_${pf.name}";
        await supabase.storage.from('hotels').uploadBinary(fileName, pf.bytes!);
        final publicUrl = supabase.storage.from('hotels').getPublicUrl(fileName);

        setState(() { uploadedUrls[category]!.add(publicUrl); });
      }
      _showSnack("Uploaded successfully to $category");
    } catch (e) {
      _showSnack("Upload error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    for (var c in controllers.values) c.dispose();
    for (var c in roomPriceControllers.values) c.dispose();
    availableRoomsController.dispose();
    aboutController.dispose();
    ratingController.dispose();
    locationController.dispose();
    _expandCtrl.dispose();
    super.dispose();
  }

  Widget buildTextField(String field) {
    bool isNumber = ["total_single_sharing_rooms", "total_double_sharing_rooms", "total_three_sharing_rooms",
      "total_four_sharing_rooms", "total_five_sharing_rooms", "pincode"].contains(field);
    bool isPhone = field == "pg_contact";

    return TextFormField(
      controller: controllers[field],
      keyboardType: isNumber || isPhone ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber || isPhone ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        labelText: field.replaceAll("_", " "),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade900, width: 2), borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget buildRoomTypeSection(double width) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Room Types", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: roomTypeOptions.map((rt) => FilterChip(
          label: Text(rt), selected: roomTypeSelected[rt] == true,
          onSelected: (sel) => setState(() { roomTypeSelected[rt] = sel; if (!sel) roomPriceControllers[rt]?.clear(); }),
          selectedColor: Colors.greenAccent.shade700, backgroundColor: Colors.grey.shade100,
        )).toList()),
        const SizedBox(height: 12),
        Column(children: roomTypeOptions.where((rt) => roomTypeSelected[rt] == true).map((rt) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextFormField(
            controller: roomPriceControllers[rt], keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: "$rt Price (INR)", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            validator: (v) => (roomTypeSelected[rt] == true && (v == null || v.isEmpty)) ? "Required" : null,
          ),
        )).toList())
      ]),
    );
  }

  Widget buildAmenitiesInput(double width) {
    final amenitiesText = controllers['amenities']?.text ?? '';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Amenities", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: amenityOptions.map((a) {
        final current = amenitiesText.split(',').map((s) => s.trim()).toList();
        return ChoiceChip(
          label: Text(a), selected: current.contains(a),
          onSelected: (sel) => setState(() {
            final list = current.where((s) => s.isNotEmpty).toList();
            sel ? list.add(a) : list.remove(a);
            controllers['amenities']?.text = list.join(',');
          }),
          selectedColor: Colors.greenAccent.shade700,
        );
      }).toList()),
    ]);
  }

  Widget buildPoliciesSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Policies", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ...policies.keys.map((k) => CheckboxListTile(
          value: policies[k], onChanged: (v) => setState(() => policies[k] = v ?? false),
          title: Text(k), dense: true, activeColor: Colors.greenAccent.shade700,
        )).toList(),
      ]),
    );
  }

  Widget buildDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedPGType,
      items: pgTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
      onChanged: (val) => setState(() => selectedPGType = val),
      decoration: InputDecoration(labelText: "PG Type", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }

  Future<void> pickLocation() async {
    final result = await Navigator.push<Map<String, double>>(context, MaterialPageRoute(builder: (_) => MapPickerPage(initialLat: latitude, initialLng: longitude)));
    if (result != null) setState(() { latitude = result['lat']; longitude = result['lng']; locationController.text = "Lat: ${latitude!.toStringAsFixed(5)}, Lng: ${longitude!.toStringAsFixed(5)}"; });
  }

  Widget buildPreviewCard() {
    return Container(
      width: 320, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(controllers["pg_name"]?.text.isEmpty ?? true ? "PG Name" : controllers["pg_name"]!.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text((controllers["city"]?.text.isEmpty ?? true) ? "City, State" : "${controllers["city"]?.text}, ${controllers["state"]?.text}"),
        Text(selectedPGType == null ? "" : "Type: $selectedPGType"),
        Text("Images: ${uploadedUrls.values.expand((x) => x).length}"),
      ]),
    );
  }

  Widget _buildCategoryCard(String category) {
    final list = uploadedUrls[category]!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text(category, style: const TextStyle(fontSize: 16))),
            Text("${list.length} / 10"),
            const SizedBox(width: 8),
            GradientButton(width: 100, height: 36, onPressed: _isUploading ? null : () => _pickAndUploadImages(category), child: const Text("Upload", style: TextStyle(color: Colors.white))),
          ]),
          if (list.isNotEmpty) SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(list[i], width: 100, height: 80, fit: BoxFit.cover)),
                  Positioned(right: 0, child: GestureDetector(onTap: () => setState(() => list.removeAt(i)), child: const Icon(Icons.cancel, color: Colors.red))),
                ]),
              ),
            ),
          )
        ]),
      ),
    );
  }

  Widget buildImageSections() {
    return SizeTransition(
      sizeFactor: _expandAnim,
      child: Column(children: [
        ...categories.map((c) => _buildCategoryCard(c)).toList(),
        GradientButton(onPressed: () { setState(() { showImageSections = false; _expandCtrl.reverse(); }); }, child: const Text("Done", style: TextStyle(color: Colors.white))),
      ]),
    );
  }

  Future<void> savePG() async {
    if (!_formKey.currentState!.validate() || _isUploading) return;
    setState(() => isSaving = true);
    try {
      String allImages = uploadedUrls.values.expand((x) => x).join(',');
      final Map<String, dynamic> body = {
        'pg_id': widget.pgData?['pg_id'] ?? '',
        'partner_id': widget.partnerId,
        'pg_name': controllers["pg_name"]?.text.trim() ?? '',
        'pg_type': selectedPGType ?? '',
        'room_type': roomTypeOptions.where((rt) => roomTypeSelected[rt] == true).join(','),
        'room_price': roomTypeOptions.where((rt) => roomTypeSelected[rt] == true).map((rt) => roomPriceControllers[rt]?.text.trim() ?? '').join(','),
        'address': controllers["address"]?.text.trim() ?? '',
        'city': controllers["city"]?.text.trim() ?? '',
        'state': controllers["state"]?.text.trim() ?? '',
        'country': controllers["country"]?.text.trim() ?? '',
        'pincode': controllers["pincode"]?.text.trim() ?? '',
        'total_single_sharing_rooms': controllers["total_single_sharing_rooms"]?.text.trim() ?? '',
        'total_double_sharing_rooms': controllers["total_double_sharing_rooms"]?.text.trim() ?? '',
        'total_three_sharing_rooms': controllers["total_three_sharing_rooms"]?.text.trim() ?? '',
        'total_four_sharing_rooms': controllers["total_four_sharing_rooms"]?.text.trim() ?? '',
        'total_five_sharing_rooms': controllers["total_five_sharing_rooms"]?.text.trim() ?? '',
        'available_rooms': availableRoomsController.text.trim().isEmpty ? controllers["total_single_sharing_rooms"]?.text.trim() : availableRoomsController.text.trim(),
        'amenities': controllers['amenities']?.text.trim() ?? '',
        'description': controllers["description"]?.text.trim() ?? '',
        'policies': policies.entries.where((e) => e.value).map((e) => e.key).join(','),
        'rating': ratingController.text.trim(),
        'pg_contact': controllers["pg_contact"]?.text.trim() ?? '',
        'about_this_pg': aboutController.text.trim(),
        'hotel_location': "$latitude,$longitude",
        'status': "Active",
        'hotel_images': allImages,
      };

      final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/webaddpgs'), headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: body.map((k, v) => MapEntry(k, v.toString())));
      if (res.statusCode == 200) {
        setState(() => showSuccess = true);
        _showSnack("Saved successfully");
        await Future.delayed(const Duration(milliseconds: 700));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ViewPGsPage(partnerId: widget.partnerId)));
      }
    } catch (e) { _showSnack("Error: $e"); }
    finally { setState(() => isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.greenAccent.shade700, title: const Text("Add Paying Guests"), actions: [if (showSuccess) const Icon(Icons.check_circle, color: Colors.white, size: 28)]),
      backgroundColor: Colors.greenAccent.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30)]),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Add PGs", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 2, child: Column(children: [
                    ...fields.map((f) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: buildTextField(f))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: TextFormField(controller: locationController, readOnly: true, onTap: pickLocation, decoration: InputDecoration(labelText: "Location", suffixIcon: const Icon(Icons.map), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                    const SizedBox(height: 12),
                    buildDropdown(), buildRoomTypeSection(700), buildAmenitiesInput(700), buildPoliciesSection(),
                    const SizedBox(height: 12),
                    GradientButton(width: double.infinity, onPressed: () { setState(() => showImageSections = true); _expandCtrl.forward(); }, child: const Text("Upload / Manage Images", style: TextStyle(color: Colors.white))),
                    if (showImageSections) buildImageSections(),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: TextFormField(controller: ratingController, decoration: const InputDecoration(labelText: "Rating (0-5)", border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      GradientButton(width: 150, onPressed: isSaving ? null : savePG, child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save PG", style: TextStyle(color: Colors.white))),
                    ]),
                  ])),
                  const SizedBox(width: 20),
                  Expanded(child: buildPreviewCard()),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ FIX: Removed 'late' to solve LateInitializationError
class MapPickerPage extends StatefulWidget {
  final double? initialLat, initialLng;
  const MapPickerPage({this.initialLat, this.initialLng, Key? key}) : super(key: key);
  @override State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  CameraPosition? _initialPosition; LatLng? pickedLocation;
  final TextEditingController latController = TextEditingController(), lngController = TextEditingController();
  GoogleMapController? _mapController;

  @override void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    double lat = widget.initialLat ?? 20.5937; double lng = widget.initialLng ?? 78.9629;
    setState(() {
      pickedLocation = LatLng(lat, lng);
      _initialPosition = CameraPosition(target: pickedLocation!, zoom: 15);
      latController.text = lat.toStringAsFixed(6); lngController.text = lng.toStringAsFixed(6);
    });
  }

  @override Widget build(BuildContext context) {
    if (_initialPosition == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location"), backgroundColor: Colors.greenAccent.shade700, actions: [TextButton(onPressed: () => Navigator.pop(context, {'lat': pickedLocation!.latitude, 'lng': pickedLocation!.longitude}), child: const Text("Done", style: TextStyle(color: Colors.white)))]),
      body: GoogleMap(
        initialCameraPosition: _initialPosition!,
        onMapCreated: (c) => _mapController = c,
        onTap: (pos) => setState(() { pickedLocation = pos; latController.text = pos.latitude.toString(); lngController.text = pos.longitude.toString(); }),
        markers: {Marker(markerId: const MarkerId("p"), position: pickedLocation!)},
      ),
    );
  }
}