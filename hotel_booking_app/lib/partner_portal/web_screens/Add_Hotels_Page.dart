import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:hotel_booking_app/services/api_service.dart';
import 'View_Hotels_Page.dart';

class AddHotelsPage extends StatefulWidget {
  final String partnerId;
  final Map<String, dynamic>? hotelData;

  const AddHotelsPage({required this.partnerId, Key? key, this.hotelData}) : super(key: key);

  @override
  State<AddHotelsPage> createState() => _AddHotelsPageState();
}

class _AddHotelsPageState extends State<AddHotelsPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};

  bool showAddRoomField = false;
  bool showAddAmenityField = false;
  bool showAddPolicyField = false;
  bool showImageSections = false;
  bool isSaving = false;

  final TextEditingController newRoomTypeCtrl = TextEditingController();
  final TextEditingController newAmenityCtrl = TextEditingController();
  final TextEditingController newPolicyCtrl = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  double avgRating = 0.0;
  int totalReviews = 0;

  String? selectedHotelType;
  String? selectedCustomization;
  double? latitude, longitude;

  List<String> roomTypes = ['Standard Room', 'Executive Room', 'Suite Room'];
  Map<String, bool> roomSelected = {};
  Map<String, TextEditingController> roomPrices = {};

  List<String> amenities = ['AC', 'TV', 'Free WIFI', 'Power Backup', 'Attached Bathroom', 'Elevator', 'Geyser', 'Parking'];
  Map<String, bool> amenitySelected = {};

  List<String> policies = ['Couple Friendly', 'Alcohol Allowed', 'Guest Should Display Govt ID\'s', 'Non-Refundable', 'Refundable'];
  Map<String, bool> policySelected = {};

  final Map<String, List<Uint8List>> localImages = {};

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
    List<String> fields = ["hotel_name", "address", "city", "state", "country", "pincode", "total_rooms", "hotel_contact"];
    for (var f in fields) {
      controllers[f] = TextEditingController();
      controllers[f]!.addListener(() => setState(() {}));
    }
    for (var r in roomTypes) { roomSelected[r] = false; roomPrices[r] = TextEditingController(text: "0"); }
    for (var a in amenities) amenitySelected[a] = false;
    for (var p in policies) policySelected[p] = false;

    localImages["Facade"] = [];
    localImages["Lobby/Entrance"] = [];

    if (widget.hotelData != null) {
      _populateExistingData();
    }
  }

  void _populateExistingData() {
    final data = widget.hotelData!;
    controllers["hotel_name"]!.text = data['hotel_name']?.toString() ?? "";
    controllers["address"]!.text = data['address']?.toString() ?? "";
    controllers["city"]!.text = data['city']?.toString() ?? "";
    controllers["state"]!.text = data['state']?.toString() ?? "";
    controllers["country"]!.text = data['country']?.toString() ?? "";
    controllers["pincode"]!.text = data['pincode']?.toString() ?? "";
    controllers["total_rooms"]!.text = data['total_rooms']?.toString() ?? "0";
    controllers["hotel_contact"]!.text = data['hotel_contact']?.toString() ?? "";
    aboutController.text = data['about_this_property']?.toString() ?? "";
    avgRating = double.tryParse(data['avg_rating']?.toString() ?? "0.0") ?? 0.0;
    totalReviews = int.tryParse(data['total_reviews']?.toString() ?? "0") ?? 0;
    selectedHotelType = data['hotel_type'];
    selectedCustomization = data['customization'];
    String? loc = data['hotel_location'];
    if (loc != null && loc.contains(',')) {
      List<String> parts = loc.split(',');
      latitude = double.tryParse(parts[0]);
      longitude = double.tryParse(parts[1]);
      locationController.text = "Lat: $latitude, Lng: $longitude";
    }
    _parseCsvToMap(data['amenities'], amenitySelected, amenities);
    _parseCsvToMap(data['policies'], policySelected, policies);
    List<String> savedRooms = data['room_type']?.toString().split(',') ?? [];
    List<String> savedPrices = data['room_price']?.toString().split(',') ?? [];
    for (int i = 0; i < savedRooms.length; i++) {
      String rName = savedRooms[i].trim();
      if (rName.isNotEmpty) {
        if (!roomTypes.contains(rName)) roomTypes.add(rName);
        roomSelected[rName] = true;
        roomPrices[rName] = TextEditingController(text: i < savedPrices.length ? savedPrices[i] : "0");
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
        if (!amenities.contains(val)) amenities.add(val);
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
        if (!policies.contains(val)) policies.add(val);
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
        if (!roomTypes.contains(val)) roomTypes.add(val);
        roomSelected[val] = true;
        roomPrices[val] = TextEditingController(text: "0");
        newRoomTypeCtrl.clear();
        showAddRoomField = false;
      });
    }
  }

  List<String> get dynamicCategories {
    List<String> cats = ["Facade", "Lobby/Entrance"];
    roomSelected.forEach((key, selected) { if (selected) cats.add(key); });
    return cats;
  }

  Future<void> _pickImages(String category) async {
    if ((localImages[category]?.length ?? 0) >= 10) {
      _showSnack("Maximum 10 images allowed for $category");
      return;
    }
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
    if (result != null) {
      setState(() {
        localImages.putIfAbsent(category, () => []);
        for (var file in result.files) {
          if (localImages[category]!.length < 10 && file.bytes != null) {
            if (file.size > 3 * 1024 * 1024) {
              _showSnack("${file.name} is too large. Please select images under 3MB.");
              continue;
            }
            localImages[category]!.add(file.bytes!);
          }
        }
      });
    }
  }

  Future<void> saveHotel() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack("All fields are mandatory");
      return;
    }
    if (latitude == null) {
      _showSnack("Please select location on map");
      return;
    }
    setState(() => isSaving = true);
    try {
      final selRooms = roomSelected.entries.where((e) => e.value).map((e) => e.key).toList();
      final selPrices = selRooms.map((r) => roomPrices[r]?.text.isEmpty ?? true ? "0" : roomPrices[r]!.text).toList();
      final Map<String, String> body = {
        'hotel_id': widget.hotelData?['hotel_id']?.toString() ?? '',
        'partner_id': widget.partnerId,
        'hotel_name': controllers["hotel_name"]!.text,
        'hotel_type': selectedHotelType ?? 'Hotel',
        'customization': selectedCustomization ?? 'No',
        'room_type': selRooms.isEmpty ? 'Standard' : selRooms.join(','),
        'room_price': selPrices.isEmpty ? '0' : selPrices.join(','),
        'address': controllers["address"]!.text,
        'city': controllers["city"]!.text,
        'state': controllers["state"]!.text,
        'country': controllers["country"]!.text,
        'pincode': controllers["pincode"]!.text,
        'total_rooms': controllers["total_rooms"]!.text,
        'available_rooms': controllers["total_rooms"]!.text,
        'amenities': amenitySelected.entries.where((e) => e.value).map((e) => e.key).join(','),
        'policies': policySelected.entries.where((e) => e.value).map((e) => e.key).join(','),
        'avg_rating': avgRating.toString(),
        'total_reviews': totalReviews.toString(),
        'hotel_contact': controllers["hotel_contact"]!.text,
        'about_this_property': aboutController.text,
        'hotel_location': "$latitude,$longitude",
        'status': "Active",
        'hotel_images': widget.hotelData?['hotel_images']?.toString() ?? '',
      };
      Map<String, List<String>> imageMap = {};
      bool hasNewImages = false;
      for (var entry in localImages.entries) {
        String cat = entry.key;
        List<Uint8List> bytesList = entry.value;
        if (bytesList.isNotEmpty) {
          hasNewImages = true;
          List<String> encodedList = [];
          for (var bytes in bytesList) { encodedList.add(base64Encode(bytes)); }
          imageMap[cat] = encodedList;
        }
      }
      if (hasNewImages) { body['images'] = jsonEncode(imageMap); }
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/webaddhotels'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      ).timeout(const Duration(seconds: 90));
      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['status'] == 'success') {
        _showSnack(result['message']);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ViewHotelsPage(partnerId: widget.partnerId)),
          );
        }
      } else {
        _showSnack("Error: ${result['message']}");
      }
    } catch (e) {
      _showSnack("Error: Server communication failed.");
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB9F6CA),
      appBar: AppBar(backgroundColor: const Color(0xFF00C853), title: Text(widget.hotelData == null ? "Add Hotels" : "Edit Hotel"), elevation: 0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;
          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 15 : 40),
                child: Center(
                  child: Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: isMobile ? constraints.maxWidth : 750,
                        padding: const EdgeInsets.all(35),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Hotel Registration", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 25),
                              DropdownButtonFormField<String>(value: selectedHotelType, decoration: _inputStyle("Hotel Type"), items: ['Hotel', 'Home Stays', 'Dormitory', 'Farm House','Lodge', 'Party Rooms', 'Resort', 'Villa'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => selectedHotelType = v), validator: (v) => v == null ? "Required" : null),
                              const SizedBox(height: 15),
                              DropdownButtonFormField<String>(value: selectedCustomization, decoration: _inputStyle("Customization"), items: ['Yes', 'No'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => selectedCustomization = v), validator: (v) => v == null ? "Required" : null),
                              const SizedBox(height: 15),
                              ...controllers.keys.map((k) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: controllers[k], decoration: _inputStyle(k.replaceAll("_", " ")), validator: (v) => (v == null || v.isEmpty) ? "Required" : null))),
                              TextFormField(controller: locationController, readOnly: true, decoration: _inputStyle("Location").copyWith(suffixIcon: const Icon(Icons.map)), onTap: () async {
                                final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => MapPickerPage(initialLat: latitude, initialLng: longitude)));
                                if (res != null) setState(() { latitude = res['lat']; longitude = res['lng']; locationController.text = "Lat: ${latitude!.toStringAsFixed(3)}, Lng: ${longitude!.toStringAsFixed(3)}"; });
                              }),
                              const SizedBox(height: 25),
                              _sectionHeader("Room Types", () => setState(() => showAddRoomField = !showAddRoomField)),
                              if (showAddRoomField) _addInputRow(newRoomTypeCtrl, "Room Type Name", _addNewRoom),
                              Wrap(spacing: 8, children: roomTypes.map((r) => FilterChip(label: Text(r), selected: roomSelected[r] ?? false, onSelected: (v) => setState(() => roomSelected[r] = v))).toList()),
                              ...roomTypes.where((r) => roomSelected[r] == true).map((r) => Padding(padding: const EdgeInsets.only(top: 10), child: TextFormField(controller: roomPrices[r], decoration: _inputStyle("$r Price"), keyboardType: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? "Required" : null))),
                              const SizedBox(height: 25),
                              _sectionHeader("Amenities", () => setState(() => showAddAmenityField = !showAddAmenityField)),
                              if (showAddAmenityField) _addInputRow(newAmenityCtrl, "Amenity", _addNewAmenity),
                              Wrap(spacing: 8, children: amenities.map((a) => FilterChip(label: Text(a), selected: amenitySelected[a] ?? false, onSelected: (v) => setState(() => amenitySelected[a] = v))).toList()),
                              const SizedBox(height: 25),
                              _sectionHeader("Policies", () => setState(() => showAddPolicyField = !showAddPolicyField)),
                              if (showAddPolicyField) _addInputRow(newPolicyCtrl, "Policy", _addNewPolicy),
                              ...policies.map((p) => CheckboxListTile(title: Text(p, style: const TextStyle(fontSize: 13)), value: policySelected[p] ?? false, onChanged: (v) => setState(() => policySelected[p] = v!), dense: true, activeColor: Colors.green, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading)),
                              const SizedBox(height: 25),
                              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => setState(() { showImageSections = !showImageSections; showImageSections ? _expandCtrl.forward() : _expandCtrl.reverse(); }), icon: const Icon(Icons.upload), label: const Text("Upload / Manage Images"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.white, padding: const EdgeInsets.all(15)))),
                              SizeTransition(sizeFactor: _expandAnim, child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Column(children: [
                                ...dynamicCategories.map((c) => Column(children: [
                                  ListTile(title: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("Limit: 10 images"), trailing: Text("${localImages[c]?.length ?? 0} / 10"), onTap: () => _pickImages(c)),
                                  if (localImages[c]?.isNotEmpty ?? false) SizedBox(height: 70, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: localImages[c]!.length, itemBuilder: (ctx, i) => _imageThumbnail(c, i))),
                                  const Divider(),
                                ])),
                              ]))),
                              const SizedBox(height: 25),
                              TextFormField(controller: aboutController, maxLines: 3, decoration: _inputStyle("About Property"), validator: (v) => (v == null || v.isEmpty) ? "Required" : null),
                              const SizedBox(height: 20),
                              _buildFooter(),
                            ],
                          ),
                        ),
                      ),
                      if (!isMobile) const SizedBox(width: 30),
                      if (isMobile) const SizedBox(height: 30),
                      _buildPreviewSidebar(isMobile ? constraints.maxWidth : 300),
                    ],
                  ),
                ),
              ),
              if (isSaving)
                Container(color: Colors.black54, child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Colors.white), SizedBox(height: 20), Text("Saving Hotel...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      SizedBox(height: 50, width: 150, child: ElevatedButton(onPressed: isSaving ? null : saveHotel, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.white), child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save Hotel"))),
    ]);
  }

  Widget _buildPreviewSidebar(double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Live Preview", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        const Divider(),
        Text(controllers["hotel_name"]!.text.isEmpty ? "Hotel Name" : controllers["hotel_name"]!.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 5),
        Text("${controllers["address"]!.text} ${controllers["city"]!.text}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const Divider(),
        Text("Avg Rating: $avgRating ⭐", style: const TextStyle(fontSize: 12)),
        Text("Total Reviews: $totalReviews", style: const TextStyle(fontSize: 12)),
        Text("Type: ${selectedHotelType ?? '-'}", style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  Widget _imageThumbnail(String c, int i) => Stack(children: [Container(margin: const EdgeInsets.only(right: 5), width: 60, height: 60, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)), child: Image.memory(localImages[c]![i], fit: BoxFit.cover)), Positioned(right: 0, child: GestureDetector(onTap: () => setState(() => localImages[c]!.removeAt(i)), child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white))))]);
  Widget _sectionHeader(String title, VoidCallback onAdd) => Row(children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: onAdd)]);
  Widget _addInputRow(TextEditingController ctrl, String hint, VoidCallback onCheck) => Row(children: [Expanded(child: TextField(controller: ctrl, decoration: InputDecoration(hintText: hint))), IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: onCheck)]);
  InputDecoration _inputStyle(String label) => InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 13, color: Colors.black54), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.black26)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF00C853), width: 1.5)));
  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class MapPickerPage extends StatefulWidget {
  final double? initialLat, initialLng;
  const MapPickerPage({this.initialLat, this.initialLng, Key? key}) : super(key: key);
  @override State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? _loc;
  final TextEditingController latC = TextEditingController(), lngC = TextEditingController();
  GoogleMapController? _mc;

  @override void initState() { super.initState(); _initLoc(); }

  Future<void> _initLoc() async {
    LatLng base = const LatLng(12.9716, 77.5946);
    try {
      Position p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      base = LatLng(p.latitude, p.longitude);
    } catch (_) {}
    setState(() { _loc = LatLng(widget.initialLat ?? base.latitude, widget.initialLng ?? base.longitude); latC.text = _loc!.latitude.toString(); lngC.text = _loc!.longitude.toString(); });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location"), backgroundColor: Colors.green),
      body: _loc == null ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Padding(padding: const EdgeInsets.all(10), child: Row(children: [
          Expanded(child: TextField(controller: latC, decoration: const InputDecoration(labelText: "Lat"))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: lngC, decoration: const InputDecoration(labelText: "Lng"))),
          ElevatedButton(onPressed: () => Navigator.pop(context, {'lat': _loc!.latitude, 'lng': _loc!.longitude}), child: const Text("Done"))
        ])),
        Expanded(child: GoogleMap(initialCameraPosition: CameraPosition(target: _loc!, zoom: 14), onMapCreated: (c) => _mc = c, onTap: (l) => setState(() { _loc = l; latC.text = l.latitude.toString(); lngC.text = l.longitude.toString(); }), markers: {Marker(markerId: const MarkerId("m"), position: _loc!)}))
      ]),
    );
  }
}