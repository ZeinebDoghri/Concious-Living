import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  static const _webClientId =
      '50634132035-mbsntvba4fvadj3udlrsp2340tbjnith.apps.googleusercontent.com';

  static Future<UserCredential?> signIn() async {
    final googleSignIn = kIsWeb
        ? GoogleSignIn(clientId: _webClientId, scopes: const ['email'])
        : GoogleSignIn(scopes: const ['email']);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  static Future<UserCredential?> signInWithGoogle() => signIn();
}
