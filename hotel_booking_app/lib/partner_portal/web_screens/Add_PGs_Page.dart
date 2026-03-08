import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _isUploading = false;

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

  final List<String> amenityOptions = ['AC', 'TV', 'Fridge', 'Washing Machine', 'Free WIFI', 'Power Backup', 'Attached Bathroom', 'Elevator', 'Geyser', 'Parking'];

  final Map<String, bool> policies = {'Couple Friendly': false, 'Alcohol Allowed': false, 'Guest Should Display Govt ID\'s': false, 'Non-Refundable': false, 'Refundable': false};

  // Restoring controllers specifically requested
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController ratingController = TextEditingController(text: '0.0');

  final List<String> categories = ["Facade", "Lobby/Entrance", "Single Sharing", "Double Sharing", "Three Sharing", "Four Sharing", "Five Sharing"];

  // ✅ IMPORTANT: Store URLs instead of bytes to fix Java Heap crash
  final Map<String, List<String>> uploadedUrls = {};
  final Map<String, int> categoryLimits = {"Facade": 10, "Lobby/Entrance": 10, "Single Sharing": 10, "Double Sharing": 10, "Three Sharing": 10, "Four Sharing": 10, "Five Sharing": 10};
  final int maxFileSizeBytes = 3 * 1024 * 1024; // 3MB limit for web stability
  bool showImageSections = false;

  final TextEditingController locationController = TextEditingController();
  double? latitude, longitude;

  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOut);

    for (var f in fields) controllers[f] = TextEditingController();
    controllers['amenities'] = TextEditingController();
    for (var rt in roomTypeOptions) roomPriceControllers[rt] = TextEditingController();
    for (var c in categories) uploadedUrls[c] = [];

    if (widget.pgData != null) _populateExistingData();
  }

  void _populateExistingData() {
    final data = widget.pgData!;
    for (var f in fields) controllers[f]?.text = data[f]?.toString() ?? '';
    selectedPGType = data['pg_type'];
    final rt = (data['room_type'] ?? '').split(',');
    final rp = (data['room_price'] ?? '').split(',');
    for (int i = 0; i < rt.length; i++) {
      final type = rt[i].trim();
      if (roomTypeOptions.contains(type)) {
        roomTypeSelected[type] = true;
        if (i < rp.length) roomPriceControllers[type]?.text = rp[i].trim();
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
    String existingImgs = data['hotel_images'] ?? '';
    if (existingImgs.isNotEmpty) uploadedUrls["Facade"] = existingImgs.split(',').toList();
    setState(() {});
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ✅ FIX: Immediate upload to cloud to prevent Java OOM
  Future<void> _pickAndUploadImages(String category) async {
    final already = uploadedUrls[category]!.length;
    final limit = categoryLimits[category] ?? 10;
    final remaining = limit - already;
    if (remaining <= 0) { _showSnack("Limit reached"); return; }

    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
      if (res == null) return;
      setState(() => _isUploading = true);

      for (var pf in res.files.take(remaining)) {
        if (pf.bytes == null || pf.size > maxFileSizeBytes) continue;
        String name = "${widget.partnerId}/PG_${DateTime.now().millisecondsSinceEpoch}_${pf.name}";
        await Supabase.instance.client.storage.from('hotels').uploadBinary(name, pf.bytes!);
        final url = Supabase.instance.client.storage.from('hotels').getPublicUrl(name);
        setState(() => uploadedUrls[category]!.add(url));
      }
      _showSnack("Successfully uploaded to $category");
    } catch (e) { _showSnack("Upload error: $e"); }
    finally { setState(() => _isUploading = false); }
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
    bool isNumber = field.contains("total") || field == "pincode" || field == "pg_contact";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controllers[field],
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
        decoration: InputDecoration(labelText: field.replaceAll("_", " "), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade900, width: 2), borderRadius: BorderRadius.circular(12))),
        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget buildRoomTypeSection(double width) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Room Types", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: roomTypeOptions.map((rt) => FilterChip(label: Text(rt), selected: roomTypeSelected[rt] == true, onSelected: (sel) => setState(() { roomTypeSelected[rt] = sel; if (!sel) roomPriceControllers[rt]?.clear(); }), selectedColor: Colors.greenAccent.shade700, backgroundColor: Colors.grey.shade100)).toList()),
        const SizedBox(height: 12),
        Column(children: roomTypeOptions.where((rt) => roomTypeSelected[rt] == true).map((rt) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: TextFormField(controller: roomPriceControllers[rt], keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: "$rt Price (INR)", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => (roomTypeSelected[rt] == true && (v == null || v.isEmpty)) ? "Required" : null))).toList())
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
        return ChoiceChip(label: Text(a), selected: current.contains(a), onSelected: (sel) => setState(() {
          final list = current.where((s) => s.isNotEmpty).toList();
          sel ? list.add(a) : list.remove(a);
          controllers['amenities']?.text = list.join(',');
        }), selectedColor: Colors.greenAccent.shade700);
      }).toList()),
      const SizedBox(height: 8),
      TextFormField(controller: controllers['amenities'], decoration: InputDecoration(labelText: "Other Amenities", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    ]);
  }

  Widget buildPoliciesSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Policies", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ...policies.keys.map((k) => CheckboxListTile(value: policies[k], onChanged: (v) => setState(() => policies[k] = v ?? false), title: Text(k), dense: true, activeColor: Colors.greenAccent.shade700)).toList(),
      ]),
    );
  }

  Widget buildDropdown() {
    return DropdownButtonFormField<String>(value: selectedPGType, items: pgTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => selectedPGType = v), decoration: InputDecoration(labelText: "PG Type", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v == null || v.isEmpty ? "Required" : null);
  }

  Widget buildPreviewCard() {
    return Container(
      width: 320, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(controllers["pg_name"]?.text.isEmpty ?? true ? "PG Name" : controllers["pg_name"]!.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        const SizedBox(height: 8),
        Text((controllers["city"]?.text.isEmpty ?? true) ? "City, State" : "${controllers["city"]?.text}, ${controllers["state"]?.text}"),
        const SizedBox(height: 8),
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
            GradientButton(width: 120, height: 40, onPressed: _isUploading ? null : () => _pickAndUploadImages(category), child: const Text("Pick", style: TextStyle(color: Colors.white))),
          ]),
          if (list.isNotEmpty) SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(list[i], width: 140, height: 90, fit: BoxFit.cover)),
                  Positioned(right: 4, top: 4, child: GestureDetector(onTap: () => setState(() => uploadedUrls[category]!.removeAt(i)), child: Container(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.close, size: 20, color: Colors.white)))),
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
        const Text("Upload images (Automatically stored in cloud)", style: TextStyle(color: Colors.black54)),
        ...categories.map((c) => _buildCategoryCard(c)).toList(),
        GradientButton(onPressed: () { setState(() { showImageSections = false; _expandCtrl.reverse(); }); }, child: const Text("Done", style: TextStyle(color: Colors.white))),
      ]),
    );
  }

  Future<void> saveHotel() async {
    if (!_formKey.currentState!.validate() || _isUploading) return;
    final sel = roomTypeOptions.where((rt) => roomTypeSelected[rt] == true).toList();
    for (var rt in sel) { if (roomPriceControllers[rt]!.text.trim().isEmpty) { _showSnack("Price for $rt required"); return; } }

    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text("Confirm"), content: const Text("Save PG details?"), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirm"))]));
    if (confirm != true) return;

    setState(() => isSaving = true);
    try {
      String allImgs = uploadedUrls.values.expand((x) => x).join(',');
      final Map<String, dynamic> body = {
        'pg_id': widget.pgData?['pg_id'] ?? '', 'partner_id': widget.partnerId, 'pg_name': controllers["pg_name"]!.text, 'pg_type': selectedPGType,
        'room_type': sel.join(','), 'room_price': sel.map((rt) => roomPriceControllers[rt]!.text).join(','),
        'address': controllers["address"]!.text, 'city': controllers["city"]!.text, 'state': controllers["state"]!.text, 'country': controllers["country"]!.text, 'pincode': controllers["pincode"]!.text,
        'total_single_sharing_rooms': controllers["total_single_sharing_rooms"]!.text, 'total_double_sharing_rooms': controllers["total_double_sharing_rooms"]!.text, 'total_three_sharing_rooms': controllers["total_three_sharing_rooms"]!.text, 'total_four_sharing_rooms': controllers["total_four_sharing_rooms"]!.text, 'total_five_sharing_rooms': controllers["total_five_sharing_rooms"]!.text,
        'available_rooms': controllers["total_single_sharing_rooms"]!.text, 'amenities': controllers['amenities']!.text, 'description': controllers["description"]!.text, 'policies': policies.entries.where((e) => e.value).map((e) => e.key).join(','),
        'rating': ratingController.text.trim(), 'pg_contact': controllers["pg_contact"]!.text, 'about_this_pg': aboutController.text.trim(), 'hotel_location': "$latitude,$longitude", 'status': "Active", 'hotel_images': allImgs,
      };
      final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/webaddpgs'), headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: body.map((k, v) => MapEntry(k, v.toString())));
      if (res.statusCode == 200) { setState(() => showSuccess = true); await Future.delayed(const Duration(milliseconds: 700)); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ViewPGsPage(partnerId: widget.partnerId))); }
    } catch (e) { _showSnack("Error: $e"); }
    finally { setState(() => isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.greenAccent.shade700, title: const Text("Add Paying Guests"), actions: [if (showSuccess) const Icon(Icons.check_circle, color: Colors.white, size: 28)]),
      backgroundColor: Colors.greenAccent.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100), padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 12))]),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Add PGs", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 2, child: Column(children: [
                      ...fields.map((f) => buildTextField(f)),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: TextFormField(controller: locationController, readOnly: true, onTap: () async { final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => MapPickerPage(initialLat: latitude, initialLng: longitude))); if (r != null) setState(() { latitude = r['lat']; longitude = r['lng']; locationController.text = "Lat: ${latitude!.toStringAsFixed(5)}, Lng: ${longitude!.toStringAsFixed(5)}"; }); }, decoration: InputDecoration(labelText: "Pick Location", filled: true, fillColor: Colors.white, suffixIcon: const Icon(Icons.location_on), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      const SizedBox(height: 12),
                      buildDropdown(), const SizedBox(height: 12), buildRoomTypeSection(700), const SizedBox(height: 12), buildAmenitiesInput(700), const SizedBox(height: 12), buildPoliciesSection(), const SizedBox(height: 12),
                      GradientButton(width: double.infinity, onPressed: () { setState(() => showImageSections = true); _expandCtrl.forward(); }, child: const Text("Upload / Manage Images", style: TextStyle(color: Colors.white))),
                      if (showImageSections) buildImageSections(),
                      const SizedBox(height: 20),
                      TextFormField(controller: aboutController, maxLines: 3, decoration: InputDecoration(labelText: "About This Property", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade900, width: 2), borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextFormField(controller: ratingController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Rating (0.0 - 5.0)", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade900, width: 2), borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 12),
                        GradientButton(width: 150, onPressed: isSaving ? null : saveHotel, child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save PG", style: TextStyle(color: Colors.white))),
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
      ),
    );
  }
}

// ✅ FIX: Fixed LateInitializationError by making variables nullable
class MapPickerPage extends StatefulWidget {
  final double? initialLat, initialLng;
  const MapPickerPage({this.initialLat, this.initialLng, Key? key}) : super(key: key);
  @override State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  CameraPosition? _initial; LatLng? _picked;
  final TextEditingController _latC = TextEditingController(), _lngC = TextEditingController();

  @override void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    double lat = widget.initialLat ?? 20.5937; double lng = widget.initialLng ?? 78.9629;
    setState(() { _picked = LatLng(lat, lng); _initial = CameraPosition(target: _picked!, zoom: 15); _latC.text = lat.toStringAsFixed(6); _lngC.text = lng.toStringAsFixed(6); });
  }

  @override Widget build(BuildContext context) {
    if (_initial == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
        appBar: AppBar(title: const Text("Pick Location"), backgroundColor: Colors.greenAccent.shade700, actions: [TextButton(onPressed: () => Navigator.pop(context, {'lat': _picked!.latitude, 'lng': _picked!.longitude}), child: const Text("Done", style: TextStyle(color: Colors.white)))]),
        body: GoogleMap(initialCameraPosition: _initial!, onMapCreated: (c) {}, onTap: (p) => setState(() { _picked = p; _latC.text = p.latitude.toString(); _lngC.text = p.longitude.toString(); }), markers: {Marker(markerId: const MarkerId("p"), position: _picked!)})
    );
  }
}