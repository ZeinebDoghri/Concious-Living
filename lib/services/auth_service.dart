import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<void> ensureUserDocument(User user, String role) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'uid': user.uid,
        'id': user.uid,
        'email': user.email,
        'name': user.displayName ?? '',
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'allergens': [],
        'calorieGoal': 2000,
        'nutrientLimits': {
          'cholesterol_mg': 300,
          'saturated_fat_g': 20,
          'sodium_mg': 2300,
          'sugar_g': 50,
        },
        'notifyDailyIntake': true,
        'notifyAllergens': true,
        'notifyWeeklyReport': true,
      });
    }
  }
}
