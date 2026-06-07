# ORKA — Conscious Living

> AI-powered mobile application for food safety, waste reduction, and personalized nutrition tracking.

![Flutter](https://img.shields.io/badge/Flutter-3.19.0+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.3.0+-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Functions-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Description

**ORKA** is a Flutter mobile application built around the theme of *Conscious Living*. It addresses two urgent challenges in the food service industry: food waste and health safety.

With a single photo of a dish, buffet, or product label, ORKA transforms visual information into intelligent decisions for kitchen teams, hotels, and individual customers. The app also calculates environmental impact through compost tracking and CO₂ equivalent per scan.

ORKA serves three distinct user types through dedicated portals:

| Portal | Users | Core Features |
|---|---|---|
| 🍽️ **Restaurant** | Managers & kitchen staff | Freshness detection, expiry alerts, waste monitoring, contamination alerts, compost tracking |
| 🏨 **Hotel** | F&B teams | Multi-department waste analytics, HACCP compliance, cross-kitchen safety, Sage AI consultant |
| 👤 **Customer** | End consumers | Dish scanning, allergen detection, nutrient tracking, daily limit alerts, Nora AI nutritionist |

All AI predictions are powered by vision models analyzing food photos in real time.

---

## Technologies

| Layer | Technologies |
|---|---|
| **Mobile** | Flutter 3.x / Dart |
| **Backend & Database** | Firebase (Firestore, Authentication, Cloud Messaging, Cloud Functions) |
| **AI / Computer Vision** | Google Gemini API, YOLOv8 (contamination detection) |
| **Inference APIs** | Hugging Face Spaces (SegFormer-B3 compost, EfficientNet waste, freshness, Dual SwinV2-Small nutrition) |
| **Image Storage** | Cloudinary |
| **Mapping** | Google Places API |
| **Navigation** | go_router |
| **State Management** | Provider |
| **Chat UI** | DashChat 2 |
| **Cloud Functions** | Firebase Cloud Functions (Node.js 18) |

---

## Prerequisites

- **Flutter SDK** 3.19.0+
- **Dart** 3.3.0+
- **Android Studio** (for Android emulator) or a physical Android / iOS device
- **Node.js 18+** (for Firebase Cloud Functions)
- A configured Firebase project (see Configuration section)
- A Cloudinary account (free tier is sufficient)

---

## Installation

```bash
# 1. Clone the repository
git clone https://github.com/ZeinebDoghri/Esprit-AI_Project-3AI4-2526-ORKA.git
cd Esprit-AI_Project-3AI4-2526-ORKA

# 2. Install Flutter dependencies
flutter pub get

# 3. Install Firebase Cloud Functions dependencies
cd functions
npm install
cd ..
```

---

## Configuration

### 1. API Keys

Create your API keys file from the provided template:

```bash
cp .env.example lib/config/api_keys.dart
```

Open `lib/config/api_keys.dart` and fill in your own keys (Gemini, Google Places, Cloudinary, OpenWeather).
> ⚠️ **Never commit this file.** It is listed in `.gitignore`.

### 2. Firebase

1. Create a project on [Firebase Console](https://console.firebase.google.com)
2. Download `google-services.json` → place it in `android/app/`
3. Download `GoogleService-Info.plist` → place it in `ios/Runner/`
4. Enable: **Firestore**, **Authentication** (Email/Password), **Cloud Messaging**

> A `google-services.json.example` is included to show the expected structure. Replace it with your own credentials.

---

## Running the App

```bash
# Run on a connected emulator or physical device
flutter run

# Run in Chrome (web preview only)
flutter run -d chrome

# Build a release APK for Android
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Build for iOS (macOS only)
flutter build ios --release
```

---

## Environment Variables

See `.env.example` for all required keys. Never put real values in the repository.

| Variable | Description |
|---|---|
| `GEMINI_API_KEY_1` to `_5` | Google Gemini API keys (5-key rotation across 6 models) |
| `GOOGLE_PLACES_API_KEY` | Google Places API (food map feature) |
| `OPENWEATHER_API_KEY` | OpenWeatherMap (weather-based recommendations) |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary (scan image storage) |

---

## Project Structure

```
lib/
├── config/          # API keys — not versioned, create from .env.example
├── core/            # Models, constants, Firebase service, API config
├── features/
│   ├── auth/        # Authentication (Customer, Restaurant, Hotel)
│   ├── customer/    # Home, scan, nutrition, map, profile, Nora chatbot
│   ├── restaurant/  # Dashboard, scan, inventory, alerts, waste, Chef AI
│   └── hotel/       # Dashboard, scan, profile, Sage chatbot
├── providers/       # State management (Provider)
├── services/        # AI Chat, Cloudinary, Nutrition, Weather, Google Places
└── shared/          # Shared widgets, AI chatbot scaffold
functions/           # Firebase Cloud Functions (Node.js 18)
docs/                # Technical documentation and architecture diagrams
demo/
├── app-release.apk
├── screenshots/
│   ├── home.png
│   ├── dashboard.png
│   └── profil.png
└── demo.mp4
```

---

## AI Models

All models are hosted externally and called via REST API. **No model files are stored in this repository.**

| Model | Hosted on | Link |
|---|---|---|
| Nutrition prediction | Hugging Face Spaces | [Link](https://huggingface.co/spaces/zeinebzino/nutrients-model) |
| Allergen detection | Hugging Face Spaces | [Link](https://huggingface.co/spaces/nadiahafhouf/allergyModel) |
| Freshness detection | Hugging Face Spaces | [Link](https://huggingface.co/spaces/jawher0000/freshness-check) |
| Expiry detection | Roboflow Universe | [Link](https://universe.roboflow.com/ml-model-tlmqd/expiry-date-recognition) |
| Compost segmentation | Hugging Face Spaces | [Link](https://huggingface.co/spaces/touuuuuuuuuuta/compost-api) |
| Calories prediction | Hugging Face Spaces | ([Link](https://huggingface.co/spaces/chamsun/myAPI) |
| Waste estimation | Hugging Face Spaces | ([Link](https://huggingface.co/spaces/Fatmaaaaa10/food-waste-pipeline) |
| Contamination detection | Hugging Face Spaces | ([Link](https://huggingface.co/spaces/AhmedBH03/projetai53) |

---

## Datasets

Training datasets are not included in this repository. All datasets are public and can be downloaded from the links below.

| Dataset | Used for | Source | Link |
|---|---|---|---|
| Nutrition5k | Nutrition & calorie prediction | Kaggle | [Link](https://www.kaggle.com/datasets/gillesokhin/nutrition5k-dataset) |
| Food 101 | Allergen detection | Kaggle | [Link](https://www.kaggle.com/datasets/dansbecker/food-101) |
| Fresh and Stale Classification | Freshness detection | Kaggle | [Link](https://www.kaggle.com/datasets/swoyam2609/fresh-and-stale-classification) |
| Expiry Date Recognition | Expiry detection | Roboflow Universe | [Link](https://universe.roboflow.com/ml-model-tlmqd/expiry-date-recognition) |
| FoodSeg103 | Compost segmentation | Kaggle | [Link](https://www.kaggle.com/datasets/ggrill/foodseg103) |
| FoodSeg103 | Waste estimation | Kaggle | [Link](https://www.kaggle.com/datasets/ggrill/foodseg103) |

> No training data is stored in this repository.

---

## Key Features

| Feature | Description |
|---|---|
| Multi-model AI scan | Freshness, contamination, waste, compost — from a single photo |
| CO₂ & compost tracking | Environmental impact calculated per scan |
| Nutrition analysis | Calories, proteins, carbs, fats, sugar, cholesterol, sodium — personalized daily tracking with limit alerts |
| AI assistants | Nora (nutrition · customer), Chef AI (kitchen ops · restaurant), Sage (sustainability · hotel) |
| Allergen detection | Real-time flagging from dish photos |
| Food map | Nearby restaurants & hotels via Google Places |
| Scan history | Saved in Firebase + images on Cloudinary |
| HACCP alerts | Real-time food safety compliance for restaurant and hotel portals |
| Multi-role management | Customer · Restaurant · Hotel — fully dedicated interfaces |

---

## Demo

- **APK (Android):** `demo/app-release.apk`
- **Screenshots:** `demo/screenshots/`
- **Demo video:** [Watch ORKA Demo](https://esprittncom-my.sharepoint.com/personal/aziza_eya_esprit_tn/_layouts/15/stream.aspx?id=%2Fpersonal%2Faziza_eya_esprit_tn%2FDocuments%2FORKA_Demo%2Emp4)

---

## Authors

| Name | Class | Academic Year |
|---|---|---|
| Eya Aziza | 3AI4 | 2025–2026 |
| Zeineb Doghri | 3AI4 | 2025–2026 |
| Fatma Lajmi | 3AI4 | 2025–2026 |
| Nadia Hafhouf | 3AI4 | 2025–2026 |
| Chams Nmiri | 3AI4 | 2025–2026 |
| Jawher Farhat | 3AI4 | 2025–2026 |
| Ahmed Belhsen | 3AI4 | 2025–2026 |

**Supervisors:** Nardine Hanfi · Safouene Jebali
**School:** ESPRIT School of Engineering
