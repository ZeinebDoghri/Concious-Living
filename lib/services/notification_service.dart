import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static StreamSubscription<String>? _tokenRefreshSub;

  static Future<void> saveFcmToken(String uid, {String? role}) async {
    if (kIsWeb) {
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _saveToken(uid, token, role: role, includeTimestamp: true);
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      newToken,
    ) {
      _saveToken(uid, newToken, role: role, includeTimestamp: false);
    });
  }

  static Future<void> _saveToken(
    String uid,
    String token, {
    String? role,
    required bool includeTimestamp,
  }) async {
    final userUpdate = <String, dynamic>{'fcmToken': token};
    if (includeTimestamp) {
      userUpdate['fcmTokenUpdatedAt'] = FieldValue.serverTimestamp();
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(userUpdate, SetOptions(merge: true));

    final entityCollection = role == 'restaurant'
        ? 'restaurants'
        : role == 'hotel'
        ? 'hotels'
        : null;
    if (entityCollection == null) return;

    await FirebaseFirestore.instance
        .collection(entityCollection)
        .doc(uid)
        .collection('staff')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }
}
