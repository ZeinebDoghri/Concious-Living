import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FreshnessCheckPage extends StatefulWidget {
  const FreshnessCheckPage({super.key});

  @override
  State<FreshnessCheckPage> createState() => _FreshnessCheckPageState();
}

class _FreshnessCheckPageState extends State<FreshnessCheckPage> {
  static const String _apiUrl =
      'https://jawher0000-freshness-check.hf.space/predict';

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;
  String? _status;
  double? _confidence;
  String? _label;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  // -------------------------------
  // 📷 PICK IMAGE
  // -------------------------------
  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name;
      _status = null;
      _confidence = null;
      _label = null;
      _errorMessage = null;
    });

    await _predict();
  }

  // -------------------------------
  // 📡 SEND TO API
  // -------------------------------
  Future<void> _predict() async {
    if (_imageBytes == null) return;

    setState(() => _isLoading = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _imageBytes!,
          filename: _imageName ?? 'image.jpg',
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _status = data['status'] ?? 'unknown';
          _confidence = (data['confidence'] ?? 0).toDouble();
          _label = data['label'] ?? 'Unknown';
        });

        // 💾 Save if not fresh
        if (_status == 'not_fresh') {
          await _saveFreshnessResult();
        }
      } else {
        setState(() => _errorMessage = 'Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------------------------
  // 💾 SAVE NOT FRESH RESULT
  // -------------------------------
  Future<void> _saveFreshnessResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert image to base64
      final imageBase64 = base64Encode(_imageBytes!);

      // Get existing results
      final jsonString = prefs.getString('freshness_scan_results') ?? '[]';
      final List<dynamic> results = jsonDecode(jsonString);

      // Add new result
      results.add({
        'image': imageBase64,
        'status': 'not_fresh',
        'confidence': _confidence,
        'scanned_at': DateTime.now().toIso8601String(),
      });

      // Save back
      await prefs.setString('freshness_scan_results', jsonEncode(results));
    } catch (e) {
      debugPrint('Error saving freshness result: $e');
    }
  }

  // -------------------------------
  // 🎨 UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freshness Check'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // IMAGE PREVIEW
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No image selected',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // BUTTONS - CAMERA + GALLERY
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // LOADING
            if (_isLoading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Analyzing freshness...'),
                ],
              ),

            // RESULT - FRESH
            if (!_isLoading && _status == 'fresh')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Fresh ✅',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_confidence != null)
                      Text(
                        'Confidence: ${_confidence!.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    if (_label != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _label!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // RESULT - NOT FRESH
            if (!_isLoading && _status == 'not_fresh')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Not Fresh ❌',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_confidence != null)
                      Text(
                        'Confidence: ${_confidence!.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    if (_label != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _label!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // ERROR
            if (!_isLoading && _errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
