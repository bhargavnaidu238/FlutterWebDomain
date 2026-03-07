import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hotel_booking_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadImagesPage extends StatefulWidget {
  final String partnerId;
  final String hotelId;

  const UploadImagesPage({
    Key? key,
    required this.partnerId,
    required this.hotelId,
  }) : super(key: key);

  @override
  _UploadImagesPageState createState() => _UploadImagesPageState();
}

class _UploadImagesPageState extends State<UploadImagesPage> {
  bool isProduction = bool.fromEnvironment('dart.vm.product');

  final supabase = Supabase.instance.client;

  final List<String> categories = [
    "Facade",
    "Lobby/Entrance",
    "Standard Rooms",
    "Executive Rooms",
    "Suite Rooms"
  ];

  final Map<String, int> limits = {
    "Facade": 5,
    "Lobby/Entrance": 5,
    "Standard Rooms": 10,
    "Executive Rooms": 10,
    "Suite Rooms": 10,
  };

  final Map<String, List<String>> uploadedUrls = {};
  final Map<String, List<_LocalImage>> localImages = {};

  // ✅ PREVENTS SERVER CRASH: Files over 3MB are filtered out before upload
  final int maxFileSizeBytes = 3 * 1024 * 1024;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    for (var c in categories) {
      uploadedUrls[c] = [];
      localImages[c] = [];
    }
  }

  Future<void> _pickAndUpload(String category) async {
    int remaining = limits[category]! - uploadedUrls[category]!.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Limit reached for $category')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null) return;

    final selected = result.files.take(remaining).toList();

    for (final pf in selected) {
      if (pf.size > maxFileSizeBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pf.name} is too large (>3MB). Skipped.')),
        );
        continue;
      }

      if (pf.bytes != null) {
        localImages[category]!.add(
          _LocalImage(name: pf.name, bytes: pf.bytes!, path: pf.path),
        );
      }
    }

    setState(() {});
    // Trigger upload immediately after picking
    if (localImages[category]!.isNotEmpty) {
      await _uploadBatch(category);
    }
  }

  Future<void> _uploadBatch(String category) async {
    if (localImages[category]!.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final batch = List<_LocalImage>.from(localImages[category]!);
      List<String> newUrls = [];

      if (!isProduction) {
        // ================= LOCAL BACKEND UPLOAD =================
        final uri = Uri.parse("${ApiConfig.baseUrl}/${widget.partnerId}/${widget.hotelId}");
        final req = http.MultipartRequest('POST', uri);

        for (final img in batch) {
          req.files.add(http.MultipartFile.fromBytes('files', img.bytes!, filename: img.name));
        }
        req.fields['category'] = category;

        final streamed = await req.send();
        final resp = await http.Response.fromStream(streamed);

        if (resp.statusCode == 200) {
          final decoded = json.decode(resp.body);
          if (decoded['urls'] != null) {
            newUrls.addAll(List<String>.from(decoded['urls']));
          }
        }
      } else {
        // ================= SUPABASE PRODUCTION UPLOAD =================
        const String bucketName = 'hotels';

        for (final img in batch) {
          final fileName = "${widget.partnerId}/${widget.hotelId}/$category/${DateTime.now().millisecondsSinceEpoch}_${img.name}";

          // Upload binary directly to Supabase Storage
          await supabase.storage.from(bucketName).uploadBinary(fileName, img.bytes!);

          // Generate the Public URL
          final publicUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);
          newUrls.add(publicUrl);
        }
      }

      setState(() {
        uploadedUrls[category]!.addAll(newUrls);
        localImages[category]!.clear(); // Clear local bytes once uploaded to save RAM
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully uploaded ${batch.length} images for $category')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Map<String, String> getAllCommaSeparated() {
    final out = <String, String>{};
    for (var c in categories) {
      out[c] = uploadedUrls[c]!.join(',');
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Upload Hotel Images"),
        backgroundColor: Colors.green.shade800,
        actions: [
          if (_isUploading)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))),
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: _isUploading ? null : () => Navigator.pop(context, getAllCommaSeparated()),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "Images upload as you pick them. Max 3MB per file.",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _buildCategoryCard(categories[i]),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              onPressed: _isUploading ? null : () => Navigator.pop(context, getAllCommaSeparated()),
              child: const Text("DONE / SAVE ALL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String cat) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(cat, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                Text("${uploadedUrls[cat]!.length} Uploaded", style: const TextStyle(color: Colors.white70)),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isUploading ? null : () => _pickAndUpload(cat),
                  child: const Text("Pick & Upload"),
                )
              ],
            ),
            if (localImages[cat]!.isNotEmpty) _buildLocalPreview(cat),
            if (uploadedUrls[cat]!.isNotEmpty) _buildUploadedPreview(cat),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalPreview(String cat) {
    final list = localImages[cat]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Uploading...', style: TextStyle(color: Colors.orange, fontSize: 12)),
        const SizedBox(height: 6),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            itemBuilder: (_, i) => Opacity(
              opacity: 0.5,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 80,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Colors.black26),
                child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.memory(list[i].bytes!, fit: BoxFit.cover)),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildUploadedPreview(String cat) {
    final list = uploadedUrls[cat]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Uploaded Preview:', style: TextStyle(color: Colors.green, fontSize: 12)),
        const SizedBox(height: 6),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            itemBuilder: (_, i) => Container(
              margin: const EdgeInsets.only(right: 8),
              width: 80,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green.shade900)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  list[i],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class _LocalImage {
  final String name;
  final Uint8List? bytes;
  final String? path;
  _LocalImage({required this.name, required this.bytes, required this.path});
}