# Firebase Setup (Conscious Living)

This app uses Firebase for:
- **Auth**: email/password sign-in
- **Firestore**: user profiles and feature data
- **Storage**: profile photos/logos

## 1) Create a Firebase project
1. Go to the Firebase Console and create a new project.
2. Enable the products:
   - **Authentication** → Sign-in method → enable **Email/Password**
   - **Cloud Firestore** → create a database (start in **test** mode for local dev only, then apply rules below)
   - **Storage** → create a bucket

## 2) Configure FlutterFire (recommended)
From the project root:

1. Install the FlutterFire CLI:
   - `dart pub global activate flutterfire_cli`

2. Configure Firebase for this Flutter app:
   - `flutterfire configure`

This generates/updates:
- `lib/core/firebase_options.dart` (used by [lib/main.dart](lib/main.dart))
- Platform config files (e.g. `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, etc.)

Note: this repo currently includes a placeholder [lib/core/firebase_options.dart](lib/core/firebase_options.dart) that throws an error on startup (especially visible on Chrome/Web). Running `flutterfire configure` should generate the real options file and replace the placeholder.

## 3) iOS / Android notes
- Android: the Gradle plugin and `google-services.json` must be present for the selected Firebase services.
- iOS: ensure CocoaPods are installed and run `pod install` when needed.

If you used `flutterfire configure`, most of this is handled automatically.

## 4) Firestore structure (high level)
The app expects:
- `users/{uid}`: the signed-in user profile document
- `venues/{venueId}/...`: venue-scoped collections (inventory, waste, alerts, etc.)

The exact venue authorization strategy is app-specific; see the rules section below.

## 5) Suggested Firestore security rules
Start secure and iterate.

Create/update **Firestore Rules** in the Firebase Console:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // User profile: each user can read/write their own document.
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Venue data: TODO tighten.
    // For early development, allow any signed-in user. Replace with membership checks.
    match /venues/{venueId} {
      allow read, write: if request.auth != null;

      match /{document=**} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

To tighten venue access, you’ll typically store a field like `ownerId` or `staffIds` on `venues/{venueId}` and check it in rules.

## 6) Suggested Storage security rules
Create/update **Storage Rules** in the Firebase Console:

```js
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // Profile photos are stored at: profile_photos/{uid}.jpg
    match /profile_photos/{userId}.jpg {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 7) Run the app
- `flutter pub get`
- `flutter run`

If you can run the app but registering/logging in shows `firebase_auth/configuration-not-found`, it almost always means **Email/Password** sign-in is not enabled yet in Firebase Console → Authentication → Sign-in method.

If you see a Firebase initialization error, confirm `lib/core/firebase_options.dart` is generated and that `flutterfire configure` was run for the correct bundle IDs / application IDs.
