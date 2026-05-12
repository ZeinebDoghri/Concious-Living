# 🌿 ORKA — Flutter AI Food Safety & Waste Reduction App

ORKA is a **Flutter / Dart** application focused on **food safety**, **food waste reduction**, and **nutrition tracking**.
It provides role-based experiences for **customers**, **restaurants**, and **hotels**, combining mobile UX with **computer vision** and **AI inference**.

## Overview

ORKA supports operational decision-making around:
- Food freshness and expiry handling
- Compostability and waste monitoring
- Food contamination screening
- Nutrition and calorie estimation
- Allergen awareness and scan history

The application uses:
- A cloud data layer with **Firebase (Auth, Firestore, Storage, Messaging)**
- A model inference backend exposed as HTTP APIs (see **Backend**)

## Features

### Customer portal
- Dish scan with results (nutrition/risk) and history persistence
- Health profile: goals, preferences, allergens
- Nutrition tools (calorie/macronutrient estimation)
- Food map experience (places + details)

### Restaurant / Hotel portal
- Staff scan workflows (multi-analysis depending on mode):
  - Compost segmentation
  - Food waste pipeline analysis
  - Food contamination analysis
- Dashboards (KPIs and charts)
- Inventory and history screens
- Alerts and follow-up workflows

### AI & analytics
- External inference APIs for vision models (image multipart upload)
- In-app AI assistant flows (Gemini API) for guidance and insights
- Optional on-device model assets via **ONNX Runtime** (see `assets/models/`)

## Tech Stack

### Frontend
- **Flutter** (multi-platform: Android / iOS / Web / Desktop)
- **Dart** (`environment: sdk: ^3.11.5`)
- Navigation: **GoRouter**
- State management: **Provider**
- UI: Material, `google_fonts`, `flutter_animate`, `lottie`
- Charts: `fl_chart`, `percent_indicator`

### Backend
- **FastAPI (Python)** for model-serving APIs
- **Hugging Face Spaces** for hosting public inference endpoints used by the app
- **Hugging Face / Computer Vision models** used through the APIs, including:
  - Compost segmentation (SegFormer-B3) exposed as `POST /segment`
  - Food waste pipeline (classifier + detector + mass estimation) exposed as `POST /analyze`
  - Food contamination screening (classifier + YOLO detector) exposed as `POST /analyze`
  - Nutrition & calorie inference (CalorieSwinV2-style API) exposed as `POST /predict`

Backend URL configuration in Flutter:
- Central API base URLs are defined in `lib/core/api_config.dart`.
- Additional endpoints exist in feature services (example: compost web service uses a Hugging Face Space base URL and calls `/health` + `/segment`).
- One nutrition endpoint is called directly from `lib/core/api_service.dart`.

### Cloud / data
- **Firebase Auth** (Email/Password)
- **Cloud Firestore** (profiles, scans, alerts, inventory, history)
- **Firebase Storage** (images)
- **Firebase Messaging** + local notifications
- Firebase Cloud Functions starter (TypeScript) is available in `docs/functions/`

### Other tools
- Local cache & storage: `shared_preferences`, `hive_flutter`
- Camera & scanning: `image_picker`, `mobile_scanner`
- Document export & sharing: `pdf`, `printing`, `share_plus`
- Optional image upload utility: Cloudinary integration (customer scan uploads)

## Directory Structure

Detailed overview (matches the current codebase layout):

```text
concious_living_app/
  lib/
    main.dart
    app_router.dart
    firebase_options.dart

    config/
      api_keys.dart

    constants/
      tunisian_calendar.dart

    core/
      api_config.dart
      api_service.dart
      constants.dart
      firebase_service.dart
      venue_alert_service.dart
      models/            (user_model.dart, scan_history_item.dart, ...)

    features/
      role_selector/
      onboarding/
      splash/

      auth/
        customer/
        restaurant/
        hotel/

      customer/
        customer_shell.dart
        home/
        scan/
        history/
        allergens/
        nutrition/
        nutritionist/
        foodmap/
        profile/

      restaurant/
        restaurant_shell.dart
        dashboard/
        alerts/
        inventory/
        history/
        scan/              (staff_scan_screen.dart, staff_result_screen.dart, contamination_*)
        waste/
        profile/

      hotel/
        hotel_shell.dart
        dashboard/
        scan/
        history/
        chatbot/
        profile/

      freshness/
      shared/

    providers/
      user_provider.dart
      venue_type_provider.dart
      (alerts_provider.dart, inventory_provider.dart, scan_history_provider.dart, ...)

    services/
      ai_chat_service.dart
      google_places_service.dart
      weather_service.dart
      (other feature services)

    shared/
      animations/
      widgets/
        (reusable UI components)

    theme/
      app_theme.dart

    widgets/             (app-wide widgets used by multiple features)

  assets/
    images/
    lottie/
    models/

  docs/
    architecture.md
    functions/          (Firebase Cloud Functions - TypeScript)
      package.json
      tsconfig.json
      src/

  android/ ios/ web/ macos/ windows/ linux/
```

For a detailed screen/route map, see [docs/architecture.md](docs/architecture.md).

## Getting Started

### Prerequisites
- Flutter SDK installed (stable)
- A Firebase project (Auth + Firestore + Storage)

### Install

```bash
flutter pub get
```

### Firebase (important)

Firebase setup steps are in [SETUP.md](SETUP.md).

Quick summary:
1. Create a Firebase project (Firebase Console)
2. Enable **Email/Password** in Authentication
3. Generate `firebase_options.dart` via FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### API Keys (no secrets in Git)

Keys are shipped as **placeholders** in [lib/config/api_keys.dart](lib/config/api_keys.dart):
- `geminiApiKeys` (list of keys)
- `openWeatherApiKey`
- `googlePlacesApiKey`

Add your real keys locally (do not commit).

### Backend URLs (FastAPI / Hugging Face Spaces)

If you deploy your own FastAPI services or new Hugging Face Spaces, update the base URLs in `lib/core/api_config.dart`.
Some endpoints are also referenced directly in specific features/services, so search for `hf.space` and update those URLs if needed.

### Run

```bash
flutter run
```

## Usage

- Customer: sign in → scan a dish → review results → save → review scan history → manage allergens/goals
- Restaurant/Hotel staff: sign in → open dashboard → run staff scan → review results → follow alerts/inventory/history flows

## Keywords

`ORKA` · `Flutter` · `Dart` · `Firebase` · `Firestore` · `Firebase Auth` · `Firebase Storage` · `Firebase Cloud Messaging (FCM)` · `GoRouter` · `Provider` · `FastAPI` · `Python` · `Hugging Face` · `Hugging Face Spaces` · `computer vision` · `image inference API` · `multipart upload` · `SegFormer` · `YOLO` · `food waste reduction` · `food safety` · `contamination detection` · `allergen detection` · `nutrition tracking` · `calorie estimation` · `Gemini API` · `ONNX Runtime` · `mobile app`

## Acknowledgments

- Flutter & Dart ecosystem
- Firebase (Auth, Firestore, Storage, Messaging)
- FastAPI ecosystem
- Hugging Face Spaces and open-source packages used in `pubspec.yaml`

---

<p align="center">
  Built with 💚 for a safer, smarter, and more conscious world.
</p>

