import 'dart:convert';
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
  bool showAddRoomField = false;
  bool showAddAmenityField = false;
  bool showAddPolicyField = false;

  String? selectedPGType;
  final List<String> pgTypes = ['Gents', 'Ladies', 'Co-Live'];

  final List<String> fields = [
    "PG Name", "Address", "City", "State", "Country", "Pincode",
    "Total Single Sharing Rooms", "Total Double Sharing Rooms", "Total Three Sharing Rooms",
    "Total Four Sharing Rooms", "Total Five Sharing Rooms", "PG Contact"
  ];

  List<String> roomTypeOptions = ['Single Sharing', 'Double Sharing', 'Three Sharing', 'Four Sharing', 'Five Sharing'];
  Map<String, bool> roomTypeSelected = {};
  Map<String, TextEditingController> roomPriceControllers = {};

  List<String> amenityOptions = ['AC', 'TV', 'Fridge', 'Washing Machine', 'Free WIFI', 'Power Backup', 'Attached Bathroom', 'Elevator', 'Geyser', 'Parking'];
  Map<String, bool> amenitySelected = {};

  List<String> policyOptions = ['Couple Friendly', 'Alcohol Allowed', 'Guest Should Display Govt ID\'s', 'Non-Refundable', 'Refundable'];
  Map<String, bool> policySelected = {};

  final TextEditingController newRoomTypeCtrl = TextEditingController();
  final TextEditingController newAmenityCtrl = TextEditingController();
  final TextEditingController newPolicyCtrl = TextEditingController();

  final TextEditingController aboutController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final Map<String, List<Uint8List>> localImages = {};
  double? latitude, longitude;

  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOut);
    _initData();
  }

  void _initData() {
    for (var f in fields) controllers[f] = TextEditingController();
    for (var rt in roomTypeOptions) {
      roomTypeSelected[rt] = false;
      roomPriceControllers[rt] = TextEditingController(text: "0");
    }
    for (var a in amenityOptions) amenitySelected[a] = false;
    for (var p in policyOptions) policySelected[p] = false;

    localImages["Facade"] = [];
    localImages["Lobby/Entrance"] = [];

    if (widget.pgData != null) _populateExistingData();
  }

  void _populateExistingData() {
    final data = widget.pgData!;
    controllers["PG Name"]?.text = data['pg_name']?.toString() ?? '';
    controllers["Address"]?.text = data['address']?.toString() ?? '';
    controllers["City"]?.text = data['city']?.toString() ?? '';
    controllers["State"]?.text = data['state']?.toString() ?? '';
    controllers["Country"]?.text = data['country']?.toString() ?? '';
    controllers["Pincode"]?.text = data['pincode']?.toString() ?? '';
    controllers["Total Single Sharing Rooms"]?.text = data['total_single_sharing_rooms']?.toString() ?? '0';
    controllers["Total Double Sharing Rooms"]?.text = data['total_double_sharing_rooms']?.toString() ?? '0';
    controllers["Total Three Sharing Rooms"]?.text = data['total_three_sharing_rooms']?.toString() ?? '0';
    controllers["Total Four Sharing Rooms"]?.text = data['total_four_sharing_rooms']?.toString() ?? '0';
    controllers["Total Five Sharing Rooms"]?.text = data['total_five_sharing_rooms']?.toString() ?? '0';
    controllers["PG Contact"]?.text = data['pg_contact']?.toString() ?? '';

    selectedPGType = data['pg_type'];
    aboutController.text = (data['about_this_pg'] ?? data['about_this_property'] ?? '').toString();

    if ((data['hotel_location'] ?? '').contains(',')) {
      final parts = data['hotel_location']!.split(',');
      latitude = double.tryParse(parts[0]);
      longitude = double.tryParse(parts[1]);
      locationController.text = "Lat: ${latitude!.toStringAsFixed(3)}, Lng: ${longitude!.toStringAsFixed(3)}";
    }

    _parseCsvToMap(data['amenities'], amenitySelected, amenityOptions);
    _parseCsvToMap(data['policies'], policySelected, policyOptions);

    List<String> savedRooms = data['room_type']?.toString().split(',') ?? [];
    List<String> savedPrices = data['room_price']?.toString().split(',') ?? [];
    for (int i = 0; i < savedRooms.length; i++) {
      String rName = savedRooms[i].trim();
      if (rName.isNotEmpty) {
        if (!roomTypeOptions.contains(rName)) roomTypeOptions.add(rName);
        roomTypeSelected[rName] = true;
        roomPriceControllers[rName] = TextEditingController(text: i < savedPrices.length ? savedPrices[i] : "0");
      }
    }
    setState(() {});
  }

  void _parseCsvToMap(dynamic csv, Map<String, bool> targetMap, List<String> targetList) {
    if (csv == null) return;
    List<String> items = csv.toString().split(',');
    for (var item in items) {
      String trimmed = item.trim();
      if (trimmed.isNotEmpty) {
        if (!targetList.contains(trimmed)) targetList.add(trimmed);
        targetMap[trimmed] = true;
      }
    }
  }

  void _addNewAmenity() {
    String val = newAmenityCtrl.text.trim();
    if (val.isNotEmpty) {
      setState(() {
        if (!amenityOptions.contains(val)) amenityOptions.add(val);
        amenitySelected[val] = true;
        newAmenityCtrl.clear();
        showAddAmenityField = false;
      });
    }
  }

  void _addNewPolicy() {
    String val = newPolicyCtrl.text.trim();
    if (val.isNotEmpty) {
      setState(() {
        if (!policyOptions.contains(val)) policyOptions.add(val);
        policySelected[val] = true;
        newPolicyCtrl.clear();
        showAddPolicyField = false;
      });
    }
  }

  void _addNewRoom() {
    String val = newRoomTypeCtrl.text.trim();
    if (val.isNotEmpty) {
      setState(() {
        if (!roomTypeOptions.contains(val)) roomTypeOptions.add(val);
        roomTypeSelected[val] = true;
        roomPriceControllers[val] = TextEditingController(text: "0");
        newRoomTypeCtrl.clear();
        showAddRoomField = false;
      });
    }
  }

  List<String> get dynamicCategories {
    List<String> cats = ["Facade", "Lobby/Entrance"];
    roomTypeSelected.forEach((key, selected) { if (selected) cats.add(key); });
    return cats;
  }

  Future<void> _pickImages(String category) async {
    if ((localImages[category]?.length ?? 0) >= 10) {
      _showSnack("Max 10 images per category");
      return;
    }
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
    if (result != null) {
      setState(() {
        localImages.putIfAbsent(category, () => []);
        for (var file in result.files) {
          if (localImages[category]!.length < 10 && file.bytes != null) {
            if (file.size > 3 * 1024 * 1024) continue;
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
      final selRooms = roomTypeSelected.entries.where((e) => e.value).map((e) => e.key).toList();

      final Map<String, String> body = {
        'pg_id': widget.pgData?['pg_id']?.toString() ?? '',
        'partner_id': widget.partnerId,
        'pg_name': controllers["PG Name"]!.text,
        'pg_type': selectedPGType ?? '',
        'room_type': selRooms.join(','),
        'room_price': selRooms.map((r) => roomPriceControllers[r]!.text).join(','),
        'address': controllers["Address"]!.text,
        'city': controllers["City"]!.text,
        'state': controllers["State"]!.text,
        'country': controllers["Country"]!.text,
        'pincode': controllers["Pincode"]!.text,
        'total_single_sharing_rooms': controllers["Total Single Sharing Rooms"]!.text,
        'total_double_sharing_rooms': controllers["Total Double Sharing Rooms"]!.text,
        'total_three_sharing_rooms': controllers["Total Three Sharing Rooms"]!.text,
        'total_four_sharing_rooms': controllers["Total Four Sharing Rooms"]!.text,
        'total_five_sharing_rooms': controllers["Total Five Sharing Rooms"]!.text,
        'available_rooms': controllers["Total Double Sharing Rooms"]!.text,
        'amenities': amenitySelected.entries.where((e) => e.value).map((e) => e.key).join(','),
        'policies': policySelected.entries.where((e) => e.value).map((e) => e.key).join(','),
        'avg_rating': widget.pgData?['avg_rating']?.toString() ?? '0.0', // Rating removed from UI input
        'total_reviews': widget.pgData?['total_reviews']?.toString() ?? '0',
        'pg_contact': controllers["PG Contact"]!.text,
        'about_this_pg': aboutController.text,
        'hotel_location': "$latitude,$longitude",
        'status': "Active",
      };

      Map<String, List<String>> imageMap = {};
      bool hasImages = false;
      for (var cat in dynamicCategories) {
        if (localImages[cat]?.isNotEmpty ?? false) {
          hasImages = true;
          imageMap[cat] = localImages[cat]!.map((b) => base64Encode(b)).toList();
        }
      }
      if (hasImages) body['images'] = jsonEncode(imageMap);

      final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/webaddpgs'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: body).timeout(const Duration(seconds: 90));

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && (result['status'] == 'success' || result['status'] == true)) {
        _showSnack("PG saved successfully");
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ViewPGsPage(partnerId: widget.partnerId)));
      } else {
        _showSnack("Error: ${result['message']}");
      }
    } catch (e) {
      _showSnack("Error during save. Payload might be large.");
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: Colors.greenAccent.shade100,
      appBar: AppBar(backgroundColor: Colors.greenAccent.shade700, title: const Text("Add Paying Guest")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 15 : 40),
            child: Center(
              child: Wrap( // Changed to Wrap for mobile compatibility
                alignment: WrapAlignment.center,
                spacing: 30,
                runSpacing: 20,
                children: [
                  Container(
                    width: isMobile ? screenWidth * 0.95 : 750,
                    padding: EdgeInsets.all(isMobile ? 20 : 35),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("PG Registration", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 25),
                          DropdownButtonFormField<String>(value: selectedPGType, decoration: _inputStyle("PG Type"), items: pgTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => selectedPGType = v)),
                          const SizedBox(height: 15),
                          ...fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: controllers[f], decoration: _inputStyle(f), validator: (v) => (v == null || v.isEmpty) ? "Required" : null))),

                          TextFormField(controller: locationController, readOnly: true, decoration: _inputStyle("PG Location").copyWith(suffixIcon: const Icon(Icons.map)), onTap: _pickLocation),

                          const SizedBox(height: 25),
                          _sectionHeader("Room Sharing Types", () => setState(() => showAddRoomField = !showAddRoomField)),
                          if (showAddRoomField) _addInputRow(newRoomTypeCtrl, "Add Room Type", _addNewRoom),
                          Wrap(spacing: 8, children: roomTypeOptions.map((r) => FilterChip(label: Text(r), selected: roomTypeSelected[r] ?? false, onSelected: (v) => setState(() => roomTypeSelected[r] = v))).toList()),
                          ...roomTypeOptions.where((r) => roomTypeSelected[r] == true).map((r) => Padding(padding: const EdgeInsets.only(top: 10), child: TextFormField(controller: roomPriceControllers[r], decoration: _inputStyle("$r Price"), keyboardType: TextInputType.number))),

                          const SizedBox(height: 25),
                          _sectionHeader("Amenities", () => setState(() => showAddAmenityField = !showAddAmenityField)),
                          if (showAddAmenityField) _addInputRow(newAmenityCtrl, "Add Amenity", _addNewAmenity),
                          Wrap(spacing: 8, children: amenityOptions.map((a) => FilterChip(label: Text(a), selected: amenitySelected[a] ?? false, onSelected: (v) => setState(() => amenitySelected[a] = v))).toList()),

                          const SizedBox(height: 25),
                          _sectionHeader("Policies", () => setState(() => showAddPolicyField = !showAddPolicyField)),
                          if (showAddPolicyField) _addInputRow(newPolicyCtrl, "Add Policy", _addNewPolicy),
                          ...policyOptions.map((p) => CheckboxListTile(title: Text(p), value: policySelected[p] ?? false, onChanged: (v) => setState(() => policySelected[p] = v!), dense: true, activeColor: Colors.green, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading)),

                          const SizedBox(height: 25),
                          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => setState(() { showImageSections = !showImageSections; showImageSections ? _expandCtrl.forward() : _expandCtrl.reverse(); }), icon: const Icon(Icons.upload), label: const Text("Upload / Manage Images"), style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)))),

                          SizeTransition(sizeFactor: _expandAnim, child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Column(children: [
                            ...dynamicCategories.map((c) => Column(children: [
                              ListTile(title: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("Limit: 10 images"), trailing: Text("${localImages[c]?.length ?? 0} / 10"), onTap: () => _pickImages(c)),
                              if (localImages[c]?.isNotEmpty ?? false) SizedBox(height: 70, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: localImages[c]!.length, itemBuilder: (ctx, i) => _imageThumbnail(c, i))),
                              const Divider(),
                            ])),
                          ]))),

                          const SizedBox(height: 25),
                          TextFormField(controller: aboutController, maxLines: 3, decoration: _inputStyle("About This Property")),
                          const SizedBox(height: 25),
                          SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                  onPressed: isSaving ? null : savePG,
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade700, foregroundColor: Colors.white),
                                  child: const Text("Save PG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                              )
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isMobile) _buildPreviewSidebar(), // Only show sidebar on desktop or as a separate section
                ],
              ),
            ),
          ),
          if (isSaving) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() => Container(color: Colors.black54, child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Colors.white), SizedBox(height: 20), Text("Processing PG Data...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])));

  Widget _buildPreviewSidebar() => Container(width: 300, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(controllers["PG Name"]!.text.isEmpty ? "PG Name" : controllers["PG Name"]!.text, style: const TextStyle(fontWeight: FontWeight.bold)), const Divider(), Text("Type: ${selectedPGType ?? '-'}"), Text("Location Selected: ${latitude != null ? 'Yes' : 'No'}")]));

  Widget _imageThumbnail(String c, int i) => Stack(children: [Container(margin: const EdgeInsets.only(right: 5), width: 60, height: 60, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)), child: Image.memory(localImages[c]![i], fit: BoxFit.cover)), Positioned(right: 0, child: GestureDetector(onTap: () => setState(() => localImages[c]!.removeAt(i)), child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white))))]);
  Widget _sectionHeader(String title, VoidCallback onAdd) => Row(children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: onAdd)]);
  Widget _addInputRow(TextEditingController ctrl, String hint, VoidCallback onCheck) => Row(children: [Expanded(child: TextField(controller: ctrl, decoration: InputDecoration(hintText: hint))), IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: onCheck)]);
  InputDecoration _inputStyle(String label) => InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent.shade700, width: 1.5)));

  Future<void> _pickLocation() async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => MapPickerPage(initialLat: latitude, initialLng: longitude)));
    if (res != null) setState(() { latitude = res['lat']; longitude = res['lng']; locationController.text = "Lat: ${latitude!.toStringAsFixed(3)}, Lng: ${longitude!.toStringAsFixed(3)}"; });
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _expandCtrl.dispose();
    for (var c in controllers.values) c.dispose();
    for (var c in roomPriceControllers.values) c.dispose();
    newRoomTypeCtrl.dispose();
    newAmenityCtrl.dispose();
    newPolicyCtrl.dispose();
    aboutController.dispose();
    locationController.dispose();
    super.dispose();
  }
}

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
                Navigator.pop(context, {'lat': pickedLocation!.latitude, 'lng': pickedLocation!.longitude});
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
                Expanded(child: TextFormField(controller: latController, decoration: const InputDecoration(labelText: "Latitude"), onChanged: (_) => _updateLocationFromFields())),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: lngController, decoration: const InputDecoration(labelText: "Longitude"), onChanged: (_) => _updateLocationFromFields()))
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