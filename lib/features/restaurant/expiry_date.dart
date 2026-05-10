import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../providers/venue_type_provider.dart';

class ExpiryDatePage extends StatefulWidget {
  const ExpiryDatePage({super.key});

  @override
  State<ExpiryDatePage> createState() => _ExpiryDatePageState();
}

class _ExpiryDatePageState extends State<ExpiryDatePage> {
  static const String _apiUrl =
      'https://jawher0000-expiry-date.hf.space/predict';

  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;
  String? _expiryDate;
  String? _status;
  String? _errorMessage;

  bool get _isExpired => (_status ?? '').toUpperCase() == 'EXPIRED';
  bool get _isValid => (_status ?? '').toUpperCase() == 'VALID';

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _expiryDate = (data['expiry_date'] ?? data['date'] ?? 'Not detected')
              .toString();
          _status = (data['status'] ?? 'UNKNOWN').toString();
        });
        await _saveResult();
        if (_isExpired) _showExpiredAlert();
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('expiry_scan_results') ?? '[]';
      final results = jsonDecode(jsonString) as List<dynamic>;

      String? imageUrl;
      try {
        final ref = FirebaseStorage.instance.ref(
          'scans/expiry/${DateTime.now().millisecondsSinceEpoch}_${_imageName ?? 'image.jpg'}',
        );
        await ref.putData(
          _imageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        imageUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint('Error uploading expiry image: $e');
      }

      results.add({
        'expiry_date': _expiryDate,
        'status': _status,
        'imageUrl': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await prefs.setString('expiry_scan_results', jsonEncode(results));
    } catch (e) {
      debugPrint('Error saving expiry result: $e');
    }
  }

  void _showExpiredAlert() {
    final colors = _roleColors(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF0F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFFF7070),
          size: 46,
        ),
        title: Text(
          'Product expired',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: colors.textTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This product expired on $_expiryDate.\nDo not consume it.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: colors.textBody, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(ctx).canPop()) {
                Navigator.of(ctx).pop();
              }
            },
            child: Text('OK', style: GoogleFonts.inter(color: colors.deep)),
          ),
        ],
      ),
    );
  }

  _ExpiryColors _roleColors(BuildContext context) {
    final role = context.watch<VenueTypeProvider>().venueType;
    final path = GoRouterState.of(context).uri.path;
    final isHotel = role == 'hotel' || path.startsWith('/hotel');
    return isHotel ? _ExpiryColors.hotel : _ExpiryColors.restaurant;
  }

  @override
  Widget build(BuildContext context) {
    final colors = _roleColors(context);
    final statusColor = _isExpired
        ? const Color(0xFFFF7070)
        : _isValid
        ? const Color(0xFF52C98A)
        : colors.primary;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 20, 18),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: AppShadows.md(colors.primary),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(
                          colors.isHotel
                              ? AppRoutes.hotelScan
                              : AppRoutes.restaurantScan,
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expiry date detection',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Scan a package label with the expiry AI model',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: colors.softBg,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.28),
                        ),
                        boxShadow: AppShadows.sm(colors.primary),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        child: _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_available_rounded,
                                    size: 58,
                                    color: colors.primary.withValues(
                                      alpha: 0.65,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No image selected',
                                    style: GoogleFonts.inter(
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _ExpiryActionButton(
                            colors: colors,
                            icon: Icons.camera_alt_rounded,
                            label: 'Camera',
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ExpiryActionButton(
                            colors: colors,
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (_isLoading)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppRadii.innerCard,
                          ),
                          boxShadow: AppShadows.sm(colors.primary),
                        ),
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: colors.primary),
                            const SizedBox(height: 12),
                            Text(
                              'Analyzing expiry date...',
                              style: GoogleFonts.inter(
                                color: colors.textBody,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_isLoading && _expiryDate != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(
                            AppRadii.innerCard,
                          ),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.32),
                          ),
                          boxShadow: AppShadows.sm(colors.primary),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _isExpired
                                  ? Icons.cancel_rounded
                                  : _isValid
                                  ? Icons.check_circle_rounded
                                  : Icons.help_rounded,
                              size: 48,
                              color: statusColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isExpired
                                  ? 'EXPIRED'
                                  : _isValid
                                  ? 'VALID'
                                  : 'UNKNOWN',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: $_expiryDate',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colors.textBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_isLoading && _errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFAB5B,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppRadii.innerCard,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFFFFAB5B,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            color: colors.textBody,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryActionButton extends StatelessWidget {
  final _ExpiryColors colors;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ExpiryActionButton({
    required this.colors,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
          boxShadow: AppShadows.sm(colors.primary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.deep, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.deep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryColors {
  final bool isHotel;
  final Color primary;
  final Color deep;
  final Color surface;
  final Color softBg;
  final Color textTitle;
  final Color textBody;
  final Color textMuted;

  const _ExpiryColors({
    required this.isHotel,
    required this.primary,
    required this.deep,
    required this.surface,
    required this.softBg,
    required this.textTitle,
    required this.textBody,
    required this.textMuted,
  });

  static const restaurant = _ExpiryColors(
    isHotel: false,
    primary: Color(0xFF8FA84A),
    deep: Color(0xFF5A7030),
    surface: Color(0xFFF5F8EE),
    softBg: Color(0xFFE3E8D1),
    textTitle: Color(0xFF26201B),
    textBody: Color(0xFF5C4F48),
    textMuted: Color(0xFF8C7E78),
  );

  static const hotel = _ExpiryColors(
    isHotel: true,
    primary: Color(0xFF5A9FC9),
    deep: Color(0xFF35658F),
    surface: Color(0xFFF0F5F8),
    softBg: Color(0xFFD9E9F5),
    textTitle: Color(0xFF26201B),
    textBody: Color(0xFF5C4F48),
    textMuted: Color(0xFF8C7E78),
  );
}
