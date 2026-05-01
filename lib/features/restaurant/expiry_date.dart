import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ExpiryDatePage extends StatefulWidget {
  const ExpiryDatePage({super.key});

  @override
  State<ExpiryDatePage> createState() => _ExpiryDatePageState();
}

class _ExpiryDatePageState extends State<ExpiryDatePage> {
  static const String _apiUrl =
      'https://jawher0000-expiry-date.hf.space/predict';

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;
  String? _expiryDate;
  String? _status;
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
      _expiryDate = null;
      _status = null;
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
          _expiryDate = data['expiry_date'] ?? 'Non détectée';
          _status = data['status'] ?? 'UNKNOWN';
        });

        // � Save to shared_preferences
        await _saveResult();

        // 🚨 alerte si expiré
        if (_status == 'EXPIRED') {
          _showExpiredAlert();
        }
      } else {
        setState(() => _errorMessage = 'Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------------------------
  // 💾 SAVE RESULT TO SHARED PREFERENCES
  // -------------------------------
  Future<void> _saveResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert image bytes to base64
      final imageBase64 = base64Encode(_imageBytes!);
      
      // Get existing results
      final jsonString = prefs.getString('expiry_scan_results') ?? '[]';
      final List<dynamic> results = jsonDecode(jsonString);
      
      // Add new result
      results.add({
        'expiry_date': _expiryDate,
        'status': _status,
        'image': imageBase64,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Save back
      await prefs.setString('expiry_scan_results', jsonEncode(results));
    } catch (e) {
      debugPrint('Error saving result: $e');
    }
  }

  // -------------------------------
  // 🚨 ALERTE EXPIRÉ
  // -------------------------------
  void _showExpiredAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        icon: const Icon(Icons.warning_rounded, color: Colors.red, size: 48),
        title: const Text(
          'Produit Expiré !',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Ce produit a expiré le $_expiryDate.\nNe pas consommer.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // -------------------------------
  // 🎨 UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détection Date d\'Expiration'),
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
                        Text('Aucune image sélectionnée',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // BOUTONS CAMERA + GALERIE
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Caméra'),
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
                    label: const Text('Galerie'),
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
                  Text('Analyse en cours...'),
                ],
              ),

            // RÉSULTAT
            if (!_isLoading && _expiryDate != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _status == 'EXPIRED'
                      ? Colors.red.shade50
                      : _status == 'VALID'
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _status == 'EXPIRED'
                        ? Colors.red
                        : _status == 'VALID'
                            ? Colors.green
                            : Colors.grey,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _status == 'EXPIRED'
                          ? Icons.cancel_rounded
                          : _status == 'VALID'
                              ? Icons.check_circle_rounded
                              : Icons.help_rounded,
                      size: 48,
                      color: _status == 'EXPIRED'
                          ? Colors.red
                          : _status == 'VALID'
                              ? Colors.green
                              : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status == 'EXPIRED'
                          ? 'EXPIRÉ'
                          : _status == 'VALID'
                              ? 'VALIDE'
                              : 'INCONNU',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _status == 'EXPIRED'
                            ? Colors.red
                            : _status == 'VALID'
                                ? Colors.green
                                : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date : $_expiryDate',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

            // ERREUR
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