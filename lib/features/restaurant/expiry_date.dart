import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../../providers/user_provider.dart';
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
  String? _savedDocId; // Anti-duplicate guard

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
      _savedDocId = null; // reset for each new scan
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
          _expiryDate =
              (data['expiry_date'] ?? data['date'] ?? 'Not detected')
                  .toString();
          _status = (data['status'] ?? 'UNKNOWN').toString();
        });

        // Use the exact call order requested
        await _askProductNameAndSave();
        
        if (_isExpired) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showExpiredAlert();
          });
        }
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

  // ✅ Parse expiry date string → DateTime
  DateTime? _parseExpiryDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'Not detected') return null;

    final formats = [
      RegExp(r'^(\d{2})/(\d{2})/(\d{4})$'), // DD/MM/YYYY
      RegExp(r'^(\d{2})/(\d{4})$'),           // MM/YYYY
      RegExp(r'^(\d{4})-(\d{2})-(\d{2})$'),  // YYYY-MM-DD
    ];

    try {
      if (formats[0].hasMatch(raw)) {
        final parts = raw.split('/');
        return DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
      if (formats[1].hasMatch(raw)) {
        final parts = raw.split('/');
        final month = int.parse(parts[0]);
        final year = int.parse(parts[1]);
        return DateTime(year, month + 1, 0);
      }
      if (formats[2].hasMatch(raw)) {
        return DateTime.parse(raw);
      }
    } catch (_) {}
    return null;
  }

  // ✅ Compute inventory status from expiry date
  String _computeInventoryStatus(DateTime? expiryDt) {
    if (expiryDt == null) return 'spoiled';
    final now = DateTime.now();
    final diff = expiryDt.difference(now).inDays;
    if (diff < 0) return 'spoiled';
    if (diff <= 3) return 'expiring';
    return 'fresh';
  }

  // ✅ Clean product name — remove UUID-like prefixes and file extensions
  String _cleanProductName(String? rawName) {
    if (rawName == null || rawName.isEmpty) return 'Scanned product';

    String name = rawName
        // Remove file extensions
        .replaceAll(
            RegExp(r'\.(jfif|jpg|jpeg|png|webp|gif|bmp)$',
                caseSensitive: false),
            '')
        // Remove "scaled_" prefix followed by UUID-like hex strings
        .replaceAll(
            RegExp(r'^scaled_[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}_?',
                caseSensitive: false),
            '')
        // Remove generic "image_XXXXXXXXXX" patterns
        .replaceAll(RegExp(r'^image_\d+_?', caseSensitive: false), '')
        // Replace underscores/hyphens with spaces and trim
        .replaceAll(RegExp(r'[_-]'), ' ')
        .trim();

    return name.isEmpty ? 'Scanned product' : name;
  }

  // ✅ Ask product name and save
  Future<void> _askProductNameAndSave() async {
    if (_savedDocId != null) return; // anti-duplicate guard
    
    // Since we don't have the UI for asking the product name in this file yet,
    // we just call _saveToFirestore directly to maintain the expected flow
    await _saveToFirestore();
  }

  // ✅ Save image + expiry date to Firestore + local prefs
  Future<void> _saveToFirestore() async {
    if (_savedDocId != null) return; // anti-duplicate guard

    try {
      // ── 1. Upload image to Storage ───────────────────────────────────────
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

      // ── 2. Local SharedPreferences backup ───────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('expiry_scan_results') ?? '[]';
      final results = jsonDecode(jsonString) as List<dynamic>;
      results.add({
        'expiry_date': _expiryDate,
        'status': _status,
        'imageUrl': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await prefs.setString('expiry_scan_results', jsonEncode(results));

      // ── 3. Save to Firestore history (same collection as history page) ───
      final productName = _cleanProductName(_imageName);
      final expiryDt = _parseExpiryDate(_expiryDate);
      final inventoryStatus = _computeInventoryStatus(expiryDt);

      if (mounted) {
        final role =
            Provider.of<VenueTypeProvider>(context, listen: false).venueType;
        final userProvider =
            Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.currentUser;
        final entityCollection = role == 'hotel' ? 'hotels' : 'restaurants';
        final venueId = role == 'hotel'
            ? (user?.entityId ?? user?.hotelId ?? user?.id ?? '')
            : (user?.entityId ?? user?.restaurantId ?? user?.id ?? '');

        if (venueId.isNotEmpty) {
          final doc = await FirebaseFirestore.instance
              .collection(entityCollection)
              .doc(venueId)
              .collection('scans')
              .add({
            'type': 'expiry_check',
            'expiryDate': _expiryDate ?? '',
            'status': inventoryStatus,
            'productName': productName,
            'imageUrl': imageUrl ?? '',
            'timestamp': FieldValue.serverTimestamp(),
            'scannedAt': FieldValue.serverTimestamp(),
            'venueId': venueId,
          });
          _savedDocId = doc.id;
          debugPrint('✅ Saved to Firestore: ${doc.id} — $productName ($inventoryStatus)');
        } else {
          _savedDocId = DateTime.now().millisecondsSinceEpoch.toString();
          debugPrint('⚠️ No venueId — saved locally only');
        }
      } else {
        _savedDocId = DateTime.now().millisecondsSinceEpoch.toString();
      }
    } catch (e) {
      debugPrint('❌ Error saving: $e');
    }
  }

  void _showExpiredAlert() {
    // ✅ Capture colors BEFORE showing dialog (no context.watch in callback)
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

  // ✅ context.read instead of context.watch (no rebuild listener in callbacks)
  _ExpiryColors _roleColors(BuildContext context) {
    final role =
        Provider.of<VenueTypeProvider>(context, listen: false).venueType;
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
            // ── Header ────────────────────────────────────────────────────
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
                      GoRouter.of(context).go(
                        colors.isHotel
                            ? AppRoutes.hotelDashboard
                            : AppRoutes.restaurantDashboard,
                      );
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
                          '📅 Expiry date detection',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'AI model scans package labels instantly 🔍',
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

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  children: [
                    // Image preview
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
                                  const Text(
                                    '📸',
                                    style: TextStyle(fontSize: 64),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Tap to select an image',
                                    style: GoogleFonts.inter(
                                        color: colors.textMuted,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ✅ FIX: Use unique keys to avoid Duplicate GlobalKey error
                    Row(
                      children: [
                        Expanded(
                          child: _ExpiryActionButton(
                            key: const ValueKey('btn_camera'),
                            colors: colors,
                            icon: Icons.camera_alt_rounded,
                            label: '📷 Camera',
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ExpiryActionButton(
                            key: const ValueKey('btn_gallery'),
                            colors: colors,
                            icon: Icons.photo_library_outlined,
                            label: '🖼️ Gallery',
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Loading state
                    if (_isLoading)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppRadii.innerCard),
                          boxShadow: AppShadows.sm(colors.primary),
                        ),
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: colors.primary),
                            const SizedBox(height: 12),
                            Text(
                              '⏳ Analyzing expiry date...',
                              style: GoogleFonts.inter(
                                color: colors.textBody,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This may take a few seconds',
                              style: GoogleFonts.inter(
                                color: colors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Result card
                    if (!_isLoading && _expiryDate != null)
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1).animate(
                          CurvedAnimation(
                            parent: ModalRoute.of(context)?.animation ?? AlwaysStoppedAnimation(1),
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius:
                                BorderRadius.circular(AppRadii.innerCard),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.32)),
                            boxShadow: AppShadows.sm(colors.primary),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _isExpired
                                    ? '❌'
                                    : _isValid
                                        ? '✅'
                                        : '❓',
                                style: const TextStyle(fontSize: 56),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isExpired
                                    ? 'Product Expired'
                                    : _isValid
                                        ? 'Product Valid'
                                        : 'Unknown Status',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Expiry date: $_expiryDate',
                                style: GoogleFonts.inter(
                                    fontSize: 14, color: colors.textBody, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF52C98A).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF52C98A).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '📦 Added to inventory',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF2D8A56),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Error card
                    if (!_isLoading && _errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFAB5B).withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadii.innerCard),
                          border: Border.all(
                              color: const Color(0xFFFFAB5B)
                                  .withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              '⚠️',
                              style: TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                    color: colors.textBody, height: 1.45),
                              ),
                            ),
                          ],
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

// ── Action Button ─────────────────────────────────────────────────────────────

class _ExpiryActionButton extends StatelessWidget {
  final _ExpiryColors colors;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ExpiryActionButton({
    super.key,   // ✅ FIX: accepts key to avoid Duplicate GlobalKey
    required this.colors,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: use Material + InkWell instead of GestureDetector to avoid GlobalKey issues
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border:
                Border.all(color: colors.primary.withValues(alpha: 0.35)),
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
      ),
    );
  }
}

// ── Color Themes ──────────────────────────────────────────────────────────────

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
