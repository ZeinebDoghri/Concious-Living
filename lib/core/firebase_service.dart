import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'models/alert_model.dart';
import 'models/compost_session_model.dart';
import 'models/inventory_item_model.dart';
import 'models/scan_history_item.dart';
import 'models/user_model.dart';
import 'models/waste_item_model.dart';

class FirebaseService {
  static const Duration _networkTimeout = Duration(seconds: 20);

  static void _debug(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }

  // AUTH
  static Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    _debug('[FirebaseService.registerWithEmail] start');
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(_networkTimeout);
      _debug('[FirebaseService.registerWithEmail] ok uid=${cred.user?.uid ?? ""}');
      return cred;
    } on TimeoutException {
      _debug('[FirebaseService.registerWithEmail] TIMEOUT after $_networkTimeout');
      rethrow;
    } catch (e) {
      _debug('[FirebaseService.registerWithEmail] error: $e');
      rethrow;
    }
  }

  static Future<UserCredential> loginWithEmail(
    String email,
    String password,
  ) async {
    _debug('[FirebaseService.loginWithEmail] start');
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(_networkTimeout);
      _debug('[FirebaseService.loginWithEmail] ok uid=${cred.user?.uid ?? ""}');
      return cred;
    } on TimeoutException {
      _debug('[FirebaseService.loginWithEmail] TIMEOUT after $_networkTimeout');
      rethrow;
    } catch (e) {
      _debug('[FirebaseService.loginWithEmail] error: $e');
      rethrow;
    }
  }

  static Future<void> sendPasswordReset(String email) async {
    await FirebaseAuth.instance
        .sendPasswordResetEmail(email: email)
        .timeout(_networkTimeout);
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  static User? get currentUser => FirebaseAuth.instance.currentUser;

  // FIRESTORE COLLECTIONS
  static final _db = FirebaseFirestore.instance;

  // Users collection: stores UserModel JSON
  static Future<void> saveUser(UserModel user) async {
    _debug('[FirebaseService.saveUser] start uid=${user.id}');
    try {
      await _db
          .collection('users')
          .doc(user.id)
          .set(user.toJson(), SetOptions(merge: true))
          .timeout(_networkTimeout);
      _debug('[FirebaseService.saveUser] ok uid=${user.id}');
    } on TimeoutException {
      _debug('[FirebaseService.saveUser] TIMEOUT after $_networkTimeout uid=${user.id}');
      rethrow;
    } catch (e) {
      _debug('[FirebaseService.saveUser] error uid=${user.id}: $e');
      rethrow;
    }
  }

  static Future<UserModel?> getUser(String uid) async {
    _debug('[FirebaseService.getUser] start uid=$uid');
    final doc = await _db
        .collection('users')
        .doc(uid)
        .get()
        .timeout(_networkTimeout);
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!);
  }

  // Scan history: subcollection under each user
  static Future<void> saveScan(String userId, ScanHistoryItem scan) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('scans')
        .doc(scan.id)
        .set(scan.toJson());
  }

  static Stream<List<ScanHistoryItem>> watchScans(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('scans')
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => ScanHistoryItem.fromJson(d.data()))
              .toList(),
        );
  }

  static Future<void> deleteScan(String userId, String scanId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('scans')
        .doc(scanId)
        .delete();
  }

  // Allergen alerts (restaurant/hotel collection)
  static Future<void> saveAlert(AlertModel alert) async {
    await _db.collection('alerts').doc(alert.id).set(alert.toJson());
  }

  static Stream<List<AlertModel>> watchAlerts(String venueId) {
    return _db
        .collection('alerts')
        .where('venueId', isEqualTo: venueId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => AlertModel.fromJson(d.data())).toList(),
        );
  }

  static Future<void> resolveAlert(String alertId) async {
    await _db.collection('alerts').doc(alertId).update({'status': 'resolved'});
  }

  // Inventory items (restaurant/hotel collection)
  static Future<void> saveInventoryItem(
    InventoryItemModel item,
    String venueId,
  ) async {
    await _db
        .collection('venues')
        .doc(venueId)
        .collection('inventory')
        .doc(item.id)
        .set(item.toJson());
  }

  static Stream<List<InventoryItemModel>> watchInventory(String venueId) {
    return _db
        .collection('venues')
        .doc(venueId)
        .collection('inventory')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => InventoryItemModel.fromJson(d.data())).toList(),
        );
  }

  static Future<void> removeInventoryItem(String venueId, String itemId) async {
    await _db
        .collection('venues')
        .doc(venueId)
        .collection('inventory')
        .doc(itemId)
        .delete();
  }

  // Waste logs
  static Future<void> logWaste(String venueId, WasteItemModel item) async {
    await _db
        .collection('venues')
        .doc(venueId)
        .collection('waste')
        .add(item.toJson());
  }

  static Stream<List<WasteItemModel>> watchWaste(String venueId) {
    return _db
        .collection('venues')
        .doc(venueId)
        .collection('waste')
        .orderBy('loggedAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => WasteItemModel.fromJson(d.data())).toList(),
        );
  }

  // Profile photo upload to Firebase Storage
  static Future<String> uploadProfilePhoto({
    required String userId,
    File? file,
    Uint8List? bytes,
  }) async {
    if ((file == null && bytes == null) || (file != null && bytes != null)) {
      throw ArgumentError('Provide exactly one of file or bytes.');
    }

    final ref = FirebaseStorage.instance.ref('profile_photos/$userId.jpg');
    if (file != null) {
      await ref.putFile(file);
    } else {
      await ref.putData(
        bytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    }
    return await ref.getDownloadURL();
  }

  // ── Compost sessions ────────────────────────────────────────────────────────

  static Future<void> saveCompostSession(
    String venueId,
    CompostSession session,
  ) async {
    await _db
        .collection('venues')
        .doc(venueId)
        .collection('compost_logs')
        .doc(session.id)
        .set(session.toJson());
  }

  static Stream<List<CompostSession>> watchCompostSessions(String venueId) {
    return _db
        .collection('venues')
        .doc(venueId)
        .collection('compost_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => CompostSession.fromJson(d.data())).toList(),
        );
  }

  static Future<String> uploadCompostThumbnail({
    required String venueId,
    required String sessionId,
    required Uint8List bytes,
  }) async {
    final ref = FirebaseStorage.instance.ref(
      'venues/$venueId/compost/$sessionId.jpg',
    );
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }
}
