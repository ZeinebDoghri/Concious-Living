# ORKA — Conscious Living

> Application mobile IA pour la sécurité alimentaire, la réduction du gaspillage et le suivi nutritionnel.

---

## Description

**ORKA** est une application mobile Flutter construite autour du thème du *Conscious Living*. Elle répond à deux défis urgents dans la restauration et l'hôtellerie : le gaspillage alimentaire et la sécurité sanitaire.

Avec une simple photo d'un plat, d'un buffet ou d'une étiquette produit, ORKA transforme l'information visuelle en décisions intelligentes pour les équipes cuisine, les hôtels et les clients individuels. Elle calcule également l'impact environnemental via le suivi du compost et l'équivalent CO₂ par scan.

**Côté gaspillage & durabilité :**
- Détection des restes et estimation des quantités
- Surveillance de la fraîcheur et lecture des dates de péremption
- Alertes avant que les aliments deviennent impropres à la consommation
- Suivi du compost avec calcul de l'équivalent CO₂ — impact environnemental mesurable par scan

**Côté santé & nutrition :**
- Reconnaissance de plats et signalement des allergènes en temps réel
- Analyse calorique et nutritionnelle personnalisée (protéines, glucides, lipides, sodium, cholestérol)
- Suivi quotidien des apports et alertes de dépassement
- Adapté aux personnes atteintes de maladies chroniques

**Assistants IA spécialisés :**
- **Nora** — Nutritionniste IA pour les clients
- **Chef AI** — Assistant opérations cuisine pour les restaurants
- **Sage** — Consultant durabilité pour les hôtels (HACCP, déchets, sécurité)

---

## Technologies utilisées

| Couche | Technologies |
|---|---|
| **Mobile** | Flutter 3.x / Dart |
| **Backend & Base de données** | Firebase (Firestore, Authentication, Cloud Messaging, Hosting) |
| **IA / Vision par ordinateur** | Google Gemini API, YOLO v8 (détection de contamination) |
| **Inference APIs** | Hugging Face Spaces (SegFormer-B3 compost, EfficientNet waste, freshness) |
| **Stockage images** | Cloudinary |
| **Cartographie** | Google Places API |
| **Navigation** | go_router |
| **Gestion d'état** | Provider |
| **Interface chat** | DashChat 2 |
| **Fonctions cloud** | Firebase Cloud Functions (Node.js 18) |

---

## Prérequis

- Flutter SDK **3.19.0+**
- Dart **3.3.0+**
- Android Studio (pour émulateur Android) ou appareil physique Android
- Node.js **18+** (pour Firebase Cloud Functions)
- Un projet Firebase configuré (voir section Configuration)

---

## Installation

```bash
git clone https://github.com/ZeinebDoghri/Concious-Living.git
cd Concious-Living
flutter pub get
```

---

## Configuration

### 1. Clés API

Crée le fichier `lib/config/api_keys.dart` à partir du template :

```bash
cp .env.example lib/config/api_keys.dart
```

Remplis-le avec tes propres clés (Gemini, Google Places, Cloudinary, OpenWeather).

### 2. Firebase

- Crée un projet sur [Firebase Console](https://console.firebase.google.com)
- Télécharge `google-services.json` → place-le dans `android/app/`
- Télécharge `GoogleService-Info.plist` → place-le dans `ios/Runner/`
- Active dans Firebase : **Firestore**, **Authentication** (Email/Password), **Cloud Messaging**

### 3. Firebase Functions

```bash
cd functions
npm install
cd ..
```

---

## Lancement

```bash
# Sur émulateur ou appareil Android connecté
flutter run

# Sur navigateur (Chrome)
flutter run -d chrome

# Build APK Android (release)
flutter build apk --release
# APK généré dans : build/app/outputs/flutter-apk/app-release.apk
```

---

## Variables d'environnement

Voir `.env.example` pour toutes les clés nécessaires.

| Variable | Description |
|---|---|
| `GEMINI_API_KEY_1` à `_5` | Clés Google Gemini API (rotation 5 clés x 6 modèles) |
| `GOOGLE_PLACES_API_KEY` | Google Places API (carte alimentaire) |
| `OPENWEATHER_API_KEY` | OpenWeatherMap (météo) |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary (stockage images scans) |

---

## Structure du projet

```
lib/
├── config/          # Clés API (non versionnées — à créer depuis .env.example)
├── core/            # Modèles, constantes, Firebase service, API config
├── features/
│   ├── auth/        # Authentification (Customer, Restaurant, Hotel)
│   ├── customer/    # Home, scan, nutrition, carte, profil, chatbot Nora
│   ├── restaurant/  # Dashboard, scan, inventaire, alertes, déchets, Chef AI
│   └── hotel/       # Dashboard, scan, profil, chatbot Sage
├── providers/       # State management (Provider)
├── services/        # AI Chat, Cloudinary, Nutrition, Weather, Google Places
└── shared/          # Widgets partagés, scaffold chatbot IA
functions/           # Firebase Cloud Functions (Node.js)
docs/                # Documentation technique et diagrammes
demo/                # APK, captures d'écran, vidéo de démonstration
```

---

## Démo

- APK Android : `demo/app-release.apk`
- Captures d'écran : `demo/screenshots/`

---

## Fonctionnalités principales

| Fonctionnalité | Description |
|---|---|
| Scan IA multi-modèles | Fraîcheur, contamination, gaspillage, compost en une photo |
| Suivi CO₂ & compost | Calcul de l'impact environnemental par scan |
| Analyse nutritionnelle | Calories, macros, micros, suivi quotidien personnalisé |
| Chatbots IA | Nora (nutrition), Chef AI (cuisine), Sage (durabilité hôtel) |
| Détection allergènes | Signalement temps réel depuis photo de plat |
| Carte alimentaire | Restaurants & hôtels proches via Google Places |
| Historique des scans | Sauvegarde Firebase + images Cloudinary |
| Alertes HACCP | Conformité et sécurité alimentaire en temps réel |
| Gestion multi-rôles | Customer · Restaurant · Hotel — interfaces dédiées |

---

## Auteurs

| Nom | Classe | Année universitaire |
|---|---|---|
| Eya | *(à compléter)* | 2025–2026 |
| Zeineb Doghri | *(à compléter)* | 2025–2026 |

**Tuteur :** *(à compléter)*  
**École :** ESPRIT School of Engineering
