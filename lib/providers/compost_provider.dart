import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../core/firebase_service.dart';
import '../core/models/compost_session_model.dart';
import '../core/models/scan_result.dart';
import '../features/restaurant/waste/compost_inference_service.dart';
import '../services/compost_ingestion_service.dart';

enum CompostState { idle, pickingImage, analyzing, done, error, saving }

class CompostProvider extends ChangeNotifier {
  final CompostInferenceService _inferenceService = CompostInferenceService();
  final _picker = ImagePicker();

  CompostState _state = CompostState.idle;
  CompostState get state => _state;

  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  CompostInferenceResult? _result;
  String? _errorMessage;
  bool _isSaved = false;

  File? get selectedImageFile => _selectedImageFile;
  Uint8List? get selectedImageBytes => _selectedImageBytes;
  CompostInferenceResult? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get isSaved => _isSaved;
  bool get hasImage =>
      _selectedImageFile != null || _selectedImageBytes != null;
  bool get isAnalyzing => _state == CompostState.analyzing;
  bool get hasResult => _state == CompostState.done && _result != null;
  bool get isModelLoaded => _inferenceService.isModelLoaded;

  List<CompostSession> _sessions = [];
  List<CompostSession> get sessions => _sessions;
  StreamSubscription<List<CompostSession>>? _sessionSub;
  String? _venueId;

  /// 'restaurants' or 'hotels' — resolved from the user's role at init
  String _entityCollection = 'restaurants';

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> init(String uid) async {
    final resolved = await _resolveVenueInfo(uid);
    final venueId = resolved.$1;
    if (venueId.isEmpty || _venueId == venueId) return;
    _venueId = venueId;
    _entityCollection = resolved.$2;
    unawaited(_inferenceService.init());
    _sessionSub?.cancel();
    _sessionSub = FirebaseService.watchCompostSessions(venueId, _entityCollection).listen(
      (list) {
        _sessions = list;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[CompostProvider] Firestore stream error: $e');
      },
    );
  }

  /// Returns (venueId, entityCollection) e.g. ('abc123', 'restaurants')
  Future<(String, String)> _resolveVenueInfo(String uid) async {
    if (uid.isEmpty) return ('', 'restaurants');
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    final role = (userData['role'] ?? 'restaurant').toString();
    final collection = role == 'hotel' ? 'hotels' : 'restaurants';
    final venueId = (userData['entityId'] ??
            userData['restaurantId'] ??
            userData['hotelId'] ??
            uid)
        .toString();
    return (venueId, collection);
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> pickFromCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null) return;
      await _setPickedFile(picked);
    } catch (e) {
      _errorMessage = 'Could not open camera: $e';
      _state = CompostState.error;
      notifyListeners();
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null) return;
      await _setPickedFile(picked);
    } catch (e) {
      _errorMessage = 'Could not open gallery: $e';
      _state = CompostState.error;
      notifyListeners();
    }
  }

  Future<void> _setPickedFile(XFile picked) async {
    _state = CompostState.pickingImage;
    _result = null;
    _isSaved = false;
    _errorMessage = null;
    notifyListeners();

    if (kIsWeb) {
      _selectedImageBytes = await picked.readAsBytes();
      _selectedImageFile = null;
    } else {
      _selectedImageFile = File(picked.path);
      _selectedImageBytes = null;
    }

    _state = CompostState.idle;
    notifyListeners();
  }

  // ── Classification ─────────────────────────────────────────────────────────

  Future<void> classify() async {
    if (!hasImage) return;

    _state = CompostState.analyzing;
    _errorMessage = null;
    _result = null;
    notifyListeners();

    try {
      final Uint8List imageBytes;
      if (_selectedImageBytes != null) {
        imageBytes = _selectedImageBytes!;
      } else {
        imageBytes = await _selectedImageFile!.readAsBytes();
      }
      debugPrint('[CompostProvider] image bytes=${imageBytes.length}');
      CompostInferenceResult? compostResult;

      await _inferenceService.classify(imageBytes).then((value) {
        compostResult = value;
      });

      _result = compostResult;
      _state = CompostState.done;
    } catch (e) {
      _errorMessage = 'Classification failed: $e';
      _state = CompostState.error;
    }

    notifyListeners();
  }

  // ── Save session ───────────────────────────────────────────────────────────

  Future<bool> saveSession() async {
    if (_result == null || _venueId == null || _isSaved) return false;

    _state = CompostState.saving;
    notifyListeners();

    try {
      final sessionId = const Uuid().v4();
      final now = DateTime.now();
      String? imageUrl;

      // Upload thumbnail (non-blocking if it fails)
      try {
        final Uint8List thumbBytes;
        if (_selectedImageBytes != null) {
          thumbBytes = _selectedImageBytes!;
        } else {
          thumbBytes = await _selectedImageFile!.readAsBytes();
        }
        imageUrl = await FirebaseService.uploadCompostThumbnail(
          venueId: _venueId!,
          sessionId: sessionId,
          bytes: thumbBytes,
        );
      } catch (e) {
        debugPrint('[CompostProvider] Storage upload failed (non-fatal): $e');
      }

      // 1) Save to venues/{venueId}/compost_logs — drives the local History list
      final session = CompostSession(
        id: sessionId,
        compostablePct: _result!.compostablePct,
        nonCompostablePct: _result!.nonCompostablePct,
        backgroundPct: _result!.backgroundPct,
        timestamp: now,
        imageUrl: imageUrl,
        inferenceTimeMs: _result!.inferenceTimeMs,
      );
      await FirebaseService.saveCompostSession(_venueId!, session, _entityCollection);

      // 2) Update compost_totals + waste_logs — drives dashboard KPI cards
      final compostableRatio = _result!.compostablePct / 100.0;
      // Use a fixed 0.5 kg estimate per scan (a scale reading would be ideal,
      // but compost-screen scans don't capture weight directly).
      const estimatedWasteKg = 0.5;
      final scanForIngestion = ScanResult(
        id: sessionId,
        entityId: _venueId!,
        timestamp: now,
        nutrition: const ScanNutrition(
          cholesterol_mg: 0,
          saturated_fat_g: 0,
          sodium_mg: 0,
          sugar_g: 0,
        ),
        waste: ScanWaste(
          estimatedWasteKg: estimatedWasteKg,
          compostableRatio: compostableRatio.clamp(0.0, 1.0),
        ),
      );
      try {
        await CompostIngestionService.onScanComplete(scanForIngestion);
      } catch (e) {
        debugPrint('[CompostProvider] CompostIngestionService error (non-fatal): $e');
      }

      // 3) Write to {restaurants|hotels}/{venueId}/scans — drives scans queries
      try {
        await FirebaseFirestore.instance
            .collection(_entityCollection)
            .doc(_venueId!)
            .collection('scans')
            .doc(sessionId)
            .set({
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'compost',
          'zone': 'Kitchen',
          'compostable_pct': _result!.compostablePct,
          'non_compostable_pct': _result!.nonCompostablePct,
          'background_pct': _result!.backgroundPct,
          'compostable_kg': estimatedWasteKg * compostableRatio,
          'waste_kg': estimatedWasteKg,
          'riskLevel': 'safe',
          'imageUrl': imageUrl ?? '',
          'inferenceTimeMs': _result!.inferenceTimeMs,
        });
      } catch (e) {
        debugPrint('[CompostProvider] scans write error (non-fatal): $e');
      }

      _isSaved = true;
      _state = CompostState.done;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not save session: $e';
      _state = CompostState.done;
      notifyListeners();
      return false;
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  void reset() {
    _state = CompostState.idle;
    _selectedImageFile = null;
    _selectedImageBytes = null;
    _result = null;
    _errorMessage = null;
    _isSaved = false;
    notifyListeners();
  }

  // ── Analytics helpers ──────────────────────────────────────────────────────

  double get todayCompostablePct {
    final today = _todaySessions;
    if (today.isEmpty) return 0;
    return today.fold(0.0, (s, e) => s + e.compostablePct) / today.length;
  }

  double get todayNonCompostablePct {
    final today = _todaySessions;
    if (today.isEmpty) return 0;
    return today.fold(0.0, (s, e) => s + e.nonCompostablePct) / today.length;
  }

  int get todaySessionCount => _todaySessions.length;

  List<CompostSession> get _todaySessions {
    final now = DateTime.now();
    return _sessions.where((s) {
      return s.timestamp.year == now.year &&
          s.timestamp.month == now.month &&
          s.timestamp.day == now.day;
    }).toList();
  }

  List<double> get weeklyCompostPct {
    final result = List<double>.filled(7, 0);
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final daySessions = _sessions.where((s) {
        return s.timestamp.year == day.year &&
            s.timestamp.month == day.month &&
            s.timestamp.day == day.day;
      }).toList();
      if (daySessions.isNotEmpty) {
        result[i] =
            daySessions.fold(0.0, (s, e) => s + e.compostablePct) /
            daySessions.length;
      }
    }
    return result;
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _inferenceService.dispose();
    super.dispose();
  }
}
