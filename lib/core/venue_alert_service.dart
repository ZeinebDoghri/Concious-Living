/// VenueAlertService
///
/// When a customer with allergens scans a product at a restaurant or hotel,
/// this service writes a live alert into the venue's Firestore collection.
/// Staff dashboards listen to the stream and display it in real time.
///
/// Firestore collection: `venue_alerts`
/// Document fields:
///   venueId       String   — uid of the restaurant / hotel manager
///   venueType     String   — 'restaurant' | 'hotel'
///   customerId    String   — uid of the customer
///   customerName  String
///   room          String?  — hotel room number if known
///   allergens     List<String>
///   productName   String   — the scanned item
///   riskLevel     String   — 'low' | 'moderate' | 'high'
///   scannedAt     Timestamp
///   resolved      bool
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class VenueAlertService {
  static final _col = FirebaseFirestore.instance.collection('venue_alerts');

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Called right after a customer scan result is determined.
  /// [venueId] is the uid of the restaurant/hotel currently logged in on that device,
  /// or resolved from a QR / NFC token. Pass null to skip (no venue context).
  static Future<void> notifyVenue({
    required String venueId,
    required String venueType,
    required String customerId,
    required String customerName,
    required List<String> allergens,
    required String productName,
    required String riskLevel,
    String? room,
  }) async {
    if (allergens.isEmpty) return; // no allergens → no alert needed

    await _col.add({
      'venueId':      venueId,
      'venueType':    venueType,
      'customerId':   customerId,
      'customerName': customerName,
      'room':         room,
      'allergens':    allergens,
      'productName':  productName,
      'riskLevel':    riskLevel,
      'scannedAt':    FieldValue.serverTimestamp(),
      'resolved':     false,
    });
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Stream of unresolved alerts for a specific venue (restaurant or hotel).
  /// Ordered newest-first. Limit 50 for dashboard performance.
  static Stream<QuerySnapshot<Map<String, dynamic>>> alertsStream(
    String venueId,
  ) {
    return _col
        .where('venueId', isEqualTo: venueId)
        .where('resolved', isEqualTo: false)
        .orderBy('scannedAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Mark a specific alert as resolved.
  static Future<void> resolve(String alertId) async {
    await _col.doc(alertId).update({'resolved': true});
  }

  /// Mark all unresolved alerts for a venue as resolved.
  static Future<void> resolveAll(String venueId) async {
    final snap = await _col
        .where('venueId', isEqualTo: venueId)
        .where('resolved', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'resolved': true});
    }
    await batch.commit();
  }
}
