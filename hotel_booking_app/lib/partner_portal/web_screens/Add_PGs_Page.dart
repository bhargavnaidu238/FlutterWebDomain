import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'View_PGs_Page.dart';
import 'package:hotel_booking_app/services/api_service.dart';

class AddPGSPage extends StatefulWidget {
  final String partnerId;
  final Map<String, dynamic>? pgData;

  const AddPGSPage({required this.partnerId, Key? key, this.pgData}) : super(key: key);

  @override
  State<AddPGSPage> createState() => _AddPGSPageState();
}

class _AddPGSPageState extends State<AddPGSPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool isSaving = false;
  bool showImageSections = false;

  String? selectedPGType;
  final List<String> pgTypes = ['Gents', 'Ladies', 'Co-Live'];

  final List<String> fields = [
    "pg_name", "address", "city", "state", "country", "pincode",
    "total_single_sharing_rooms", "total_double_sharing_rooms", "total_three_sharing_rooms",
    "total_four_sharing_rooms", "total_five_sharing_rooms", "description",
    "pg_contact"
  ];

  final List<String> roomTypeOptions = ['Single Sharing', 'Double Sharing', 'Three Sharing', 'Four Sharing', 'Five Sharing'];
  final Map<String, bool> roomTypeSelected = {
    'Single Sharing': false, 'Double Sharing': false, 'Three Sharing': false, 'Four Sharing': false, 'Five Sharing': false,
  };
  final Map<String, TextEditingController> roomPriceControllers = {};

  final List<String> amenityOptions = ['AC', 'TV', 'Fridge', 'Washing Machine', 'Free WIFI', 'Power Backup', 'Attached Bathroom', 'Elevator', 'Geyser', 'Parking'];
  final Map<String, bool> policies = {'Couple Friendly': false, 'Alcohol Allowed': false, 'Guest Should Display Govt ID\'s': false, 'Non-Refundable': false, 'Refundable': false};

  final TextEditingController aboutController = TextEditingController();
  final TextEditingController ratingController = TextEditingController(text: '0.0');
  final TextEditingController locationController = TextEditingController();

  // Image handling matches add_hotels.dart
  final List<String> categories = ["Facade", "Lobby/Entrance", "Single Sharing", "Double Sharing", "Three Sharing", "Four Sharing", "Five Sharing"];
  final Map<String, List<Uint8List>> localImages = {};

  double? latitude, longitude;
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
    for (var c in categories) localImages[c] = [];

    if (widget.pgData != null) _populateExistingData();
  }

  void _populateExistingData() {
    final data = widget.pgData!;
    for (var f in fields) controllers[f]?.text = data[f]?.toString() ?? '';
    selectedPGType = data['pg_type'];
    aboutController.text = data['about_this_pg'] ?? '';
    ratingController.text = (data['rating'] ?? '0.0').toString();
    controllers['amenities']?.text = data['amenities'] ?? '';

    // Location
    if ((data['hotel_location'] ?? '').contains(',')) {
      final parts = data['hotel_location']!.split(',');
      latitude = double.tryParse(parts[0]);
      longitude = double.tryParse(parts[1]);
      if (latitude != null) locationController.text = "Lat: ${latitude!.toStringAsFixed(3)}, Lng: ${longitude!.toStringAsFixed(3)}";
    }

    // Room Selection
    final savedRooms = (data['room_type'] ?? '').toString().split(',');
    final savedPrices = (data['room_price'] ?? '').toString().split(',');
    for (int i = 0; i < savedRooms.length; i++) {
      String rt = savedRooms[i].trim();
      if (roomTypeOptions.contains(rt)) {
        roomTypeSelected[rt] = true;
        if (i < savedPrices.length) roomPriceControllers[rt]?.text = savedPrices[i].trim();
      }
    }

    // Policies
    for (var k in policies.keys) {
      policies[k] = (data['policies'] ?? '').toString().split(',').contains(k);
    }
  }

  Future<void> _pickImages(String category) async {
    if ((localImages[category]?.length ?? 0) >= 10) {
      _showSnack("Maximum 10 images allowed for $category");
      return;
    }

    final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true
    );

    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (localImages[category]!.length < 10 && file.bytes != null) {
            if (file.size > 3 * 1024 * 1024) {
              _showSnack("${file.name} is too large (>3MB).");
              continue;
            }
            localImages[category]!.add(file.bytes!);
          }
        }
      });
    }
  }

  Future<void> savePG() async {
    if (!_formKey.currentState!.validate()) return;
    if (latitude == null) { _showSnack("Please select location on map"); return; }

    setState(() => isSaving = true);

    try {
      final selectedRooms = roomTypeOptions.where((rt) => roomTypeSelected[rt] == true).toList();

      final Map<String, String> body = {
        'pg_id': widget.pgData?['pg_id']?.toString() ?? '',
        'partner_id': widget.partnerId,
        'pg_name': controllers["pg_name"]!.text,
        'pg_type': selectedPGType ?? '',
        'room_type': selectedRooms.join(','),
        'room_price': selectedRooms.map((rt) => roomPriceControllers[rt]!.text).join(','),
        'address': controllers["address"]!.text,
        'city': controllers["city"]!.text,
        'state': controllers["state"]!.text,
        'country': controllers["country"]!.text,
        'pincode': controllers["pincode"]!.text,
        'total_single_sharing_rooms': controllers["total_single_sharing_rooms"]!.text,
        'total_double_sharing_rooms': controllers["total_double_sharing_rooms"]!.text,
        'total_three_sharing_rooms': controllers["total_three_sharing_rooms"]!.text,
        'total_four_sharing_rooms': controllers["total_four_sharing_rooms"]!.text,
        'total_five_sharing_rooms': controllers["total_five_sharing_rooms"]!.text,
        'available_rooms': controllers["total_double_sharing_rooms"]!.text, // Default logic
        'amenities': controllers['amenities']!.text,
        'description': controllers["description"]!.text,
        'policies': policies.entries.where((e) => e.value).map((e) => e.key).join(','),
        'rating': ratingController.text,
        'pg_contact': controllers["pg_contact"]!.text,
        'about_this_pg': aboutController.text,
        'hotel_location': "$latitude,$longitude",
        'status': "Active",
      };

      // Image Encoding logic from add_hotels.dart
      Map<String, List<String>> imageMap = {};
      bool hasNewImages = false;
      for (var cat in categories) {
        if (localImages[cat]!.isNotEmpty) {
          hasNewImages = true;
          imageMap[cat] = localImages[cat]!.map((bytes) => base64Encode(bytes)).toList();
        }
      }
      if (hasNewImages) body['images'] = jsonEncode(imageMap);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/webaddpgs'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      ).timeout(const Duration(seconds: 90));

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && (result['status'] == 'success' || result['status'] == true)) {
        _showSnack("PG Saved Successfully");
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ViewPGsPage(partnerId: widget.partnerId)));
        }
      } else {
        _showSnack("Error: ${result['message']}");
      }
    } catch (e) {
      _showSnack("Save Error: Payload may be too large or connection timed out.");
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.greenAccent.shade700, title: const Text("Add/Edit PG")),
      backgroundColor: Colors.greenAccent.shade100,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)]),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("PG Registration", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              _buildDropdown(),
                              const SizedBox(height: 15),
                              ...fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildTextField(f))),

                              TextFormField(
                                controller: locationController, readOnly: true,
                                decoration: _inputStyle("PG Location").copyWith(suffixIcon: const Icon(Icons.map)),
                                onTap: _pickLocationOnMap,
                              ),
                              const SizedBox(height: 20),
                              _buildRoomTypeSection(),
                              const SizedBox(height: 20),
                              _buildAmenitiesSection(),
                              const SizedBox(height: 20),
                              _buildPoliciesSection(),
                              const SizedBox(height: 25),

                              // Image Upload Section Toggle
                              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                                onPressed: () => setState(() { showImageSections = !showImageSections; showImageSections ? _expandCtrl.forward() : _expandCtrl.reverse(); }),
                                icon: const Icon(Icons.image), label: const Text("Manage Images"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                              )),

                              SizeTransition(sizeFactor: _expandAnim, child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Column(children: categories.map((c) => _buildImageCategoryTile(c)).toList()),
                              )),

                              const SizedBox(height: 25),
                              TextFormField(controller: aboutController, maxLines: 3, decoration: _inputStyle("About PG")),
                              const SizedBox(height: 20),
                              _buildFooter(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _buildPreviewSidebar(),
                  ],
                ),
              ),
            ),
          ),
          if (isSaving) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildImageCategoryTile(String category) {
    return Column(
      children: [
        ListTile(
          title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: Text("${localImages[category]?.length ?? 0} / 10"),
          onTap: () => _pickImages(category),
        ),
        if (localImages[category]?.isNotEmpty ?? false)
          SizedBox(height: 80, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: localImages[category]!.length,
            itemBuilder: (ctx, i) => _imageThumbnail(category, i),
          )),
        const Divider(),
      ],
    );
  }

  Widget _imageThumbnail(String c, int i) => Stack(children: [
    Container(margin: const EdgeInsets.only(right: 8), width: 70, height: 70, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)), child: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.memory(localImages[c]![i], fit: BoxFit.cover))),
    Positioned(right: 0, child: GestureDetector(onTap: () => setState(() => localImages[c]!.removeAt(i)), child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white))))
  ]);

  Widget _buildFooter() {
    return Row(children: [
      Expanded(child: TextFormField(controller: ratingController, decoration: _inputStyle("Rating (0.0-5.0)"))),
      const SizedBox(width: 15),
      SizedBox(height: 50, width: 150, child: ElevatedButton(onPressed: isSaving ? null : savePG, style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade700, foregroundColor: Colors.white), child: const Text("Save PG"))),
    ]);
  }

  Widget _buildLoadingOverlay() => Container(
    color: Colors.black54,
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
      CircularProgressIndicator(color: Colors.white),
      SizedBox(height: 20),
      Text("Uploading Data & Images...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ])),
  );

  InputDecoration _inputStyle(String label) => InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)));

  Widget _buildTextField(String field) => TextFormField(
    controller: controllers[field],
    decoration: _inputStyle(field.replaceAll("_", " ")),
    validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
  );

  Widget _buildDropdown() => DropdownButtonFormField<String>(
    value: selectedPGType,
    items: pgTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
    onChanged: (v) => setState(() => selectedPGType = v),
    decoration: _inputStyle("PG Type"),
  );

  Widget _buildRoomTypeSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Room Sharing Types", style: TextStyle(fontWeight: FontWeight.bold)),
      Wrap(spacing: 8, children: roomTypeOptions.map((rt) => FilterChip(
          label: Text(rt), selected: roomTypeSelected[rt]!,
          onSelected: (v) => setState(() => roomTypeSelected[rt] = v))).toList()),
      ...roomTypeOptions.where((rt) => roomTypeSelected[rt]!).map((rt) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextFormField(controller: roomPriceControllers[rt], decoration: _inputStyle("$rt Price")),
      ))
    ],
  );

  Widget _buildAmenitiesSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Amenities", style: TextStyle(fontWeight: FontWeight.bold)),
      TextFormField(controller: controllers['amenities'], decoration: _inputStyle("Comma separated amenities")),
    ],
  );

  Widget _buildPoliciesSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Policies", style: TextStyle(fontWeight: FontWeight.bold)),
      ...policies.keys.map((k) => CheckboxListTile(title: Text(k), value: policies[k], onChanged: (v) => setState(() => policies[k] = v!), dense: true, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading)),
    ],
  );

  Widget _buildPreviewSidebar() => Container(
    width: 300, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(controllers["pg_name"]!.text.isEmpty ? "PG Name" : controllers["pg_name"]!.text, style: const TextStyle(fontWeight: FontWeight.bold)),
      const Divider(),
      Text("Type: ${selectedPGType ?? '-'}"),
      Text("Rating: ${ratingController.text}"),
      const SizedBox(height: 10),
      const Text("Photos Selected:", style: TextStyle(fontSize: 12, color: Colors.grey)),
      ...categories.map((c) => Text("$c: ${localImages[c]!.length}", style: const TextStyle(fontSize: 11))),
    ]),
  );

  Future<void> _pickLocationOnMap() async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => MapPickerPage(initialLat: latitude, initialLng: longitude)));
    if (res != null) {
      setState(() {
        latitude = res['lat']; longitude = res['lng'];
        locationController.text = "Lat: ${latitude!.toStringAsFixed(3)}, Lng: ${longitude!.toStringAsFixed(3)}";
      });
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _expandCtrl.dispose();
    for (var c in controllers.values) c.dispose();
    for (var c in roomPriceControllers.values) c.dispose();
    aboutController.dispose();
    ratingController.dispose();
    locationController.dispose();
    super.dispose();
  }
}

// -------------------- MODEL ---------------------
class LocalPickedImage {
  final String name;
  final Uint8List? bytes;
  final String? path;

  LocalPickedImage({required this.name, required this.bytes, required this.path});
}

// -------------------- MAP PICKER ---------------------
class MapPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const MapPickerPage({this.initialLat, this.initialLng, Key? key}) : super(key: key);

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late CameraPosition _initialPosition;
  LatLng? pickedLocation;

  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _determineInitialPosition();
  }

  Future<void> _determineInitialPosition() async {
    double lat, lng;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      lat = widget.initialLat ?? position.latitude;
      lng = widget.initialLng ?? position.longitude;
    } catch (e) {
      lat = widget.initialLat ?? 20.5937;
      lng = widget.initialLng ?? 78.9629;
    }

    setState(() {
      pickedLocation = LatLng(lat, lng);
      _initialPosition = CameraPosition(target: pickedLocation!, zoom: 15);

      latController.text = pickedLocation!.latitude.toStringAsFixed(6);
      lngController.text = pickedLocation!.longitude.toStringAsFixed(6);
    });
  }

  void _updateLocationFromFields() {
    final lat = double.tryParse(latController.text);
    final lng = double.tryParse(lngController.text);

    if (lat != null && lng != null) {
      setState(() {
        pickedLocation = LatLng(lat, lng);
        _mapController?.animateCamera(CameraUpdate.newLatLng(pickedLocation!));
      });
    }
  }

  @override
  void dispose() {
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick PG Location"),
        backgroundColor: Colors.greenAccent.shade700,
        actions: [
          TextButton(
            onPressed: () {
              if (pickedLocation != null) {
                Navigator.pop(context, {
                  'lat': pickedLocation!.latitude,
                  'lng': pickedLocation!.longitude,
                });
              }
            },
            child: const Text("Done", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: pickedLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "Latitude", border: OutlineInputBorder()),
                    onChanged: (_) => _updateLocationFromFields(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: lngController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "Longitude", border: OutlineInputBorder()),
                    onChanged: (_) => _updateLocationFromFields(),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (controller) => _mapController = controller,
              onTap: (pos) {
                setState(() {
                  pickedLocation = pos;
                  latController.text = pos.latitude.toStringAsFixed(6);
                  lngController.text = pos.longitude.toStringAsFixed(6);
                });
              },
              markers: pickedLocation != null ? {Marker(markerId: const MarkerId("picked"), position: pickedLocation!)} : {},
            ),
          ),
        ],
      ),
    );
  }
}