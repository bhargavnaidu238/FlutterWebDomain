import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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

  final int maxFileSizeBytes = 10 * 1024 * 1024;
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
          SnackBar(content: Text('${pf.name} is > 10MB and skipped')),
        );
        continue;
      }

      if (pf.bytes != null) {
        localImages[category]!.add(
          _LocalImage(name: pf.name, bytes: pf.bytes!),
        );
      }
    }

    setState(() {});
    await _uploadBatch(category);
  }

  Future<void> _uploadBatch(String category) async {
    if (localImages[category]!.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final batch = List<_LocalImage>.from(localImages[category]!);
      List<String> newUrls = [];

      for (final img in batch) {
        final extension = img.name.split('.').last;

        final fileName =
            "${widget.partnerId}/${widget.hotelId}/$category/${DateTime.now().millisecondsSinceEpoch}.$extension";

        await supabase.storage
            .from('FleminGolmages')
            .uploadBinary(
          fileName,
          img.bytes!,
          fileOptions: const FileOptions(upsert: true),
        );

        final publicUrl = supabase.storage
            .from('FleminGolmages')
            .getPublicUrl(fileName);

        newUrls.add(publicUrl);
      }

      uploadedUrls[category]!.addAll(newUrls);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded ${batch.length} images for $category')),
      );

      localImages[category]!.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e')),
      );
    }

    setState(() => _isUploading = false);
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
      appBar: AppBar(
        title: const Text("Upload Hotel Images"),
        backgroundColor: Colors.green.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () =>
                Navigator.pop(context, getAllCommaSeparated()),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "Upload images per category (<= 10MB each)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _buildCategoryCard(categories[i]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700),
              onPressed: () =>
                  Navigator.pop(context, getAllCommaSeparated()),
              child: const Text("Done"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String cat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(cat)),
                Text("Uploaded: ${uploadedUrls[cat]!.length}"),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isUploading ? null : () => _pickAndUpload(cat),
                  child: const Text("Pick & Upload"),
                )
              ],
            ),
            if (uploadedUrls[cat]!.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: uploadedUrls[cat]!.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.network(
                      uploadedUrls[cat]![i],
                      width: 90,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class _LocalImage {
  final String name;
  final Uint8List bytes;

  _LocalImage({
    required this.name,
    required this.bytes,
  });
}