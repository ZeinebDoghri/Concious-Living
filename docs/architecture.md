# Conscious Living — Flutter App Architecture

This document describes the **current** architecture of the Conscious Living Flutter app (as implemented in `lib/`), including folder structure, navigation, screen map, providers, and API/Firebase data flows.

---

## 1) FOLDER STRUCTURE

Complete `lib/` tree (includes the role-separated profile screens, the venue-aware staff dashboard, and the staff food-safety scan flow):

```text
lib/
  app_router.dart
  main.dart

  core/
    api_service.dart
    constants.dart
    firebase_options.dart
    firebase_service.dart
    models/
      alert_model.dart
      inventory_item_model.dart
      nutrient_result.dart
      scan_history_item.dart
      user_model.dart
      waste_item_model.dart

  features/
    auth/
      customer/
        customer_forgot_password_screen.dart
        customer_login_screen.dart
        customer_profile_setup_screen.dart
        customer_register_screen.dart
      hotel/
        hotel_forgot_password_screen.dart
        hotel_login_screen.dart
        hotel_register_screen.dart
        hotel_setup_screen.dart
      restaurant/
        restaurant_forgot_password_screen.dart
        restaurant_login_screen.dart
        restaurant_register_screen.dart
        restaurant_setup_screen.dart

    customer/
      allergens/
        allergen_screen.dart
      history/
        history_detail_screen.dart
        history_screen.dart
      home/
        home_screen.dart
      profile/
        edit_profile_screen.dart
        health_goals_screen.dart
        profile_screen.dart
      scan/
        result_screen.dart
        scan_screen.dart
      customer_shell.dart

    hotel/
      profile/
        edit_hotel_profile_screen.dart
        hotel_profile_screen.dart

    onboarding/
      onboarding_screen.dart

    restaurant/
      alerts/
        alert_detail_screen.dart
        alerts_screen.dart
      dashboard/
        dashboard_screen.dart
      inventory/
        inventory_item_screen.dart
        inventory_screen.dart
      profile/
        edit_restaurant_profile_screen.dart
        restaurant_profile_screen.dart
      scan/
        staff_result_screen.dart
        staff_scan_screen.dart
      waste/
        compost_screen.dart
        waste_screen.dart
      restaurant_shell.dart

    role_selector/
      role_selector_screen.dart

    splash/
      splash_screen.dart

  providers/
    alerts_provider.dart
    inventory_provider.dart
    scan_history_provider.dart
    user_provider.dart
    venue_type_provider.dart

  shared/
    widgets/
      animated_button.dart
      cherry_header.dart
      empty_state.dart
      freshness_badge.dart
      nutrient_card.dart
      olive_header.dart
      risk_badge.dart
      shimmer_card.dart

  theme/
    app_theme.dart
```

---

## 2) NAVIGATION FLOW

### Source of truth

- Route constants: `lib/core/constants.dart` (`AppRoutes`)
- Router config: `lib/app_router.dart` (`createAppRouter()`)
- Customer tab shell: `lib/features/customer/customer_shell.dart`
- Staff tab shell: `lib/features/restaurant/restaurant_shell.dart`

### Route tree (all routes)

```text
/
└─ /splash
   └─ /onboarding
      └─ /role-selector

      ├─ CUSTOMER PATH
      │  ├─ Auth
      │  │  ├─ /auth/customer/login
      │  │  ├─ /auth/customer/register
      │  │  ├─ /auth/customer/forgot
      │  │  └─ /auth/customer/profile-setup
      │  └─ CustomerShell (StatefulShellRoute indexedStack)
      │     ├─ Tab: Home
      │     │  └─ /customer/home
      │     ├─ Tab: Scan
      │     │  ├─ /customer/scan
      │     │  └─ /customer/result
      │     ├─ Tab: History
      │     │  ├─ /customer/history
      │     │  └─ /customer/history/:id
      │     ├─ Tab: Allergens
      │     │  └─ /customer/allergens
      │     └─ Tab: Profile
      │        ├─ /customer/profile
      │        ├─ /customer/profile/edit
      │        ├─ /customer/health-goals
      │        ├─ /customer/nutrition-goals        (alias → HealthGoalsScreen)
      │        └─ /customer/nutrition-progress     (alias → HealthGoalsScreen)
      │
      ├─ RESTAURANT STAFF PATH
      │  ├─ Auth
      │  │  ├─ /auth/restaurant/login
      │  │  ├─ /auth/restaurant/register
      │  │  ├─ /auth/restaurant/forgot
      │  │  └─ /auth/restaurant/setup
      │  ├─ Profile edit (top-level)
      │  │  └─ /restaurant/profile/edit
      │  └─ RestaurantShell (StatefulShellRoute indexedStack)
      │     ├─ Tab: Dashboard
      │     │  └─ /restaurant/dashboard
      │     ├─ Tab: Scan
      │     │  ├─ /restaurant/scan
      │     │  └─ /restaurant/scan/result
      │     ├─ Tab: Alerts
      │     │  ├─ /restaurant/alerts
      │     │  └─ /restaurant/alert/:id
      │     ├─ Tab: Waste
      │     │  ├─ /restaurant/waste
      │     │  └─ /restaurant/compost
      │     ├─ Tab: Inventory
      │     │  ├─ /restaurant/inventory
      │     │  └─ /restaurant/inventory/:id
      │     └─ Tab: Profile
      │        └─ /restaurant/profile
      │
      └─ HOTEL STAFF PATH
         ├─ Auth
         │  ├─ /auth/hotel/login
         │  ├─ /auth/hotel/register
         │  ├─ /auth/hotel/forgot-password
         │  └─ /auth/hotel/setup
         ├─ Profile edit (top-level)
         │  └─ /hotel/profile/edit
        └─ RestaurantShell (same staff shell; venue-aware)
          ├─ Tab: Dashboard
          │  └─ /restaurant/dashboard            (venue-aware UI)
          ├─ Tab: Scan
          │  ├─ /restaurant/scan
          │  └─ /restaurant/scan/result
          ├─ Tab: Alerts
            │  ├─ /restaurant/alerts
            │  └─ /restaurant/alert/:id
            ├─ Tab: Waste
            │  ├─ /restaurant/waste
            │  └─ /restaurant/compost
            ├─ Tab: Inventory
            │  ├─ /restaurant/inventory
            │  └─ /restaurant/inventory/:id
            └─ Tab: Profile
               └─ /hotel/profile
```

Notes:
- **Hotel staff** reuses the staff shell (`RestaurantShell`) and shared staff routes; the **venue** is switched using `VenueTypeProvider`.
- Some routes are defined with parameter segments in `app_router.dart` (e.g. `/restaurant/alert/:id`) while helper builders exist in `AppRoutes` (e.g. `restaurantAlertDetail(id)` → `/restaurant/alert/<id>`).

---

## 3) SCREEN MAP TABLE

> Columns: **Role | Screen name | File path | Route | Description**

| Role | Screen name | File path | Route | Description |
|---|---|---|---|---|
| Public | SplashScreen | lib/features/splash/splash_screen.dart | /splash | Boot gate: checks auth/profile and redirects. |
| Public | OnboardingScreen | lib/features/onboarding/onboarding_screen.dart | /onboarding | Intro slides + marks onboarding as seen. |
| Public | RoleSelectorScreen | lib/features/role_selector/role_selector_screen.dart | /role-selector | Pick role; sets venue type for staff flows. |
| Customer | CustomerLoginScreen | lib/features/auth/customer/customer_login_screen.dart | /auth/customer/login | Customer sign-in (Firebase Auth). |
| Customer | CustomerRegisterScreen | lib/features/auth/customer/customer_register_screen.dart | /auth/customer/register | Customer account creation. |
| Customer | CustomerForgotPasswordScreen | lib/features/auth/customer/customer_forgot_password_screen.dart | /auth/customer/forgot | Password reset via Firebase Auth. |
| Customer | CustomerProfileSetupScreen | lib/features/auth/customer/customer_profile_setup_screen.dart | /auth/customer/profile-setup | Customer profile/health setup after auth. |
| Customer | CustomerShell | lib/features/customer/customer_shell.dart | (shell) | Bottom-nav tab scaffold for customer area. |
| Customer | HomeScreen | lib/features/customer/home/home_screen.dart | /customer/home | Customer dashboard (progress, alerts, scans, quick actions). |
| Customer | ScanScreen | lib/features/customer/scan/scan_screen.dart | /customer/scan | Capture/upload dish photo and call FastAPI nutrient prediction. |
| Customer | ResultScreen | lib/features/customer/scan/result_screen.dart | /customer/result | Shows predicted nutrients + allows save to history. |
| Customer | HistoryScreen | lib/features/customer/history/history_screen.dart | /customer/history | Scan history list, restore/delete actions. |
| Customer | HistoryDetailScreen | lib/features/customer/history/history_detail_screen.dart | /customer/history/:id | View a saved scan. |
| Customer | AllergenScreen | lib/features/customer/allergens/allergen_screen.dart | /customer/allergens | Manage allergen profile + education section. |
| Customer | ProfileScreen | lib/features/customer/profile/profile_screen.dart | /customer/profile | Customer profile display + settings shortcuts. |
| Customer | EditProfileScreen | lib/features/customer/profile/edit_profile_screen.dart | /customer/profile/edit | Customer profile edit + deep-link to health sections. |
| Customer | HealthGoalsScreen | lib/features/customer/profile/health_goals_screen.dart | /customer/health-goals | Nutrient goals editor. |
| Customer | HealthGoalsScreen (alias) | lib/features/customer/profile/health_goals_screen.dart | /customer/nutrition-goals | Alias route for goals (same screen). |
| Customer | HealthGoalsScreen (alias) | lib/features/customer/profile/health_goals_screen.dart | /customer/nutrition-progress | Alias route for progress (same screen). |
| Restaurant | RestaurantLoginScreen | lib/features/auth/restaurant/restaurant_login_screen.dart | /auth/restaurant/login | Staff sign-in (Firebase Auth). |
| Restaurant | RestaurantRegisterScreen | lib/features/auth/restaurant/restaurant_register_screen.dart | /auth/restaurant/register | Staff account creation. |
| Restaurant | RestaurantForgotPasswordScreen | lib/features/auth/restaurant/restaurant_forgot_password_screen.dart | /auth/restaurant/forgot | Password reset via Firebase Auth. |
| Restaurant | RestaurantSetupScreen | lib/features/auth/restaurant/restaurant_setup_screen.dart | /auth/restaurant/setup | Restaurant venue/profile setup after auth. |
| Restaurant | RestaurantShell | lib/features/restaurant/restaurant_shell.dart | (shell) | Bottom-nav tab scaffold for staff area (venue-aware). |
| Restaurant | DashboardScreen | lib/features/restaurant/dashboard/dashboard_screen.dart | /restaurant/dashboard | Venue-aware staff dashboard (KPIs, chart, actions). |
| Restaurant | StaffScanScreen | lib/features/restaurant/scan/staff_scan_screen.dart | /restaurant/scan | Staff food-safety scan UI with freshness or compost mode. |
| Restaurant | StaffResultScreen | lib/features/restaurant/scan/staff_result_screen.dart | /restaurant/scan/result | Staff scan result screen for freshness or compost outcomes. |
| Restaurant | AlertsScreen | lib/features/restaurant/alerts/alerts_screen.dart | /restaurant/alerts | List of allergen alerts for the venue. |
| Restaurant | AlertDetailScreen | lib/features/restaurant/alerts/alert_detail_screen.dart | /restaurant/alert/:id | Alert resolution workflow. |
| Restaurant | WasteScreen | lib/features/restaurant/waste/waste_screen.dart | /restaurant/waste | Waste reporting overview. |
| Restaurant | CompostScreen | lib/features/restaurant/waste/compost_screen.dart | /restaurant/compost | Compost classification + tips. |
| Restaurant | InventoryScreen | lib/features/restaurant/inventory/inventory_screen.dart | /restaurant/inventory | Inventory list + freshness/expiry actions. |
| Restaurant | InventoryItemScreen | lib/features/restaurant/inventory/inventory_item_screen.dart | /restaurant/inventory/:id | Single inventory item details/update. |
| Restaurant | RestaurantProfileScreen | lib/features/restaurant/profile/restaurant_profile_screen.dart | /restaurant/profile | Restaurant profile display + settings/actions. |
| Restaurant | EditRestaurantProfileScreen | lib/features/restaurant/profile/edit_restaurant_profile_screen.dart | /restaurant/profile/edit | Restaurant profile edit (multi-step). |
| Hotel | HotelLoginScreen | lib/features/auth/hotel/hotel_login_screen.dart | /auth/hotel/login | Hotel staff sign-in (Firebase Auth). |
| Hotel | HotelRegisterScreen | lib/features/auth/hotel/hotel_register_screen.dart | /auth/hotel/register | Hotel staff account creation. |
| Hotel | HotelForgotPasswordScreen | lib/features/auth/hotel/hotel_forgot_password_screen.dart | /auth/hotel/forgot-password | Password reset via Firebase Auth. |
| Hotel | HotelSetupScreen | lib/features/auth/hotel/hotel_setup_screen.dart | /auth/hotel/setup | Hotel venue/profile setup after auth. |
| Hotel | HotelProfileScreen | lib/features/hotel/profile/hotel_profile_screen.dart | /hotel/profile | Hotel profile display + actions. |
| Hotel | EditHotelProfileScreen | lib/features/hotel/profile/edit_hotel_profile_screen.dart | /hotel/profile/edit | Hotel profile edit (multi-step). |

---

## 4) DATA FLOW DIAGRAM

### Text diagram (how data moves)

```text
[Firebase Auth]
   │  (authStateChanges)
   ▼
[UserProvider] ───────► Screens (login/setup/profile/home/dashboard)
   │
   └── uses ──► [FirebaseService] ──► Firestore users/{uid}

[Firestore: scans/{uid}]
   ▼  (stream)
[ScanHistoryProvider] ───────────► Screens (Home/History/Profile)
   └── save/delete ─► FirebaseService.saveScan/deleteScan

[Firestore: venue alerts]
   ▼  (stream)
[AlertsProvider] ───────────────► Screens (Alerts/AlertDetail/Dashboard/RestaurantProfile)
   └── resolve/save ─► FirebaseService.resolveAlert/saveAlert

[Firestore: venue inventory]
   ▼  (stream)
[InventoryProvider] ────────────► Screens (Inventory/InventoryItem/Dashboard/RestaurantProfile)
   └── save/remove ─► FirebaseService.saveInventoryItem/removeInventoryItem

[Camera/Gallery]
   ▼
ScanScreen
   │  multipart POST
   ▼
ApiService.predictNutrients
   │  POST {apiBaseUrl}/predict/nutrients
   ▼
NutrientResult
   ▼
ResultScreen
   │  user taps "Save"
   ▼
ScanHistoryProvider.addScan
   ▼
FirebaseService.saveScan
   ▼
Firestore scans/{uid}

[Camera/Gallery]
  ▼
StaffScanScreen
  │  freshness mode
  ├─► ApiService.predictFreshness
  │      POST mock result today, future POST {apiBaseUrl}/predict/freshness
  │      ▼
  │   StaffResultScreen
  │      ├─ Update inventory → InventoryProvider / /restaurant/inventory
  │      └─ Log removal for spoiled items → InventoryProvider.removeItem
  │
  └─► compost mode
       ApiService.predictCompost
         POST mock result today, future POST {apiBaseUrl}/predict/compost
         ▼
       StaffResultScreen
         └─ Log to waste record → FirebaseService.logWaste
```

Key files:
- `lib/providers/user_provider.dart`
- `lib/providers/scan_history_provider.dart`
- `lib/providers/alerts_provider.dart`
- `lib/providers/inventory_provider.dart`
- `lib/core/firebase_service.dart`
- `lib/core/api_service.dart`
- `lib/features/customer/scan/scan_screen.dart`
- `lib/features/customer/scan/result_screen.dart`

---

## 5) PROVIDER MAP

Providers are registered at app start in `lib/main.dart`:

- `VenueTypeProvider` (`lib/providers/venue_type_provider.dart`)
  - Manages: venue type selection (`restaurant` vs `hotel`) + persistence via `SharedPreferences`.
  - Consumed by:
    - `RoleSelectorScreen` (sets selection)
    - `RestaurantShell` (tab label/icon + routing behavior)
    - `DashboardScreen` (venue-aware UI via `Consumer<VenueTypeProvider>`)

- `UserProvider` (`lib/providers/user_provider.dart`)
  - Manages: auth session (listens to `FirebaseAuth.instance.authStateChanges()`), current `UserModel`, nutrient goals, profile CRUD.
  - Consumed by:
    - Customer auth: `CustomerLoginScreen`, `CustomerRegisterScreen`, `CustomerProfileSetupScreen`
    - Restaurant auth: `RestaurantLoginScreen`, `RestaurantRegisterScreen`, `RestaurantSetupScreen`
    - Hotel auth: `HotelLoginScreen`, `HotelRegisterScreen`, `HotelSetupScreen`
    - Customer profile: `ProfileScreen`, `EditProfileScreen`, `HealthGoalsScreen`
    - Customer home: `HomeScreen`
    - Restaurant profile: `RestaurantProfileScreen`, `EditRestaurantProfileScreen`
    - Hotel profile: `HotelProfileScreen`, `EditHotelProfileScreen`
    - Staff dashboard: `DashboardScreen`

- `ScanHistoryProvider` (`lib/providers/scan_history_provider.dart`)
  - Manages: scan history list for the signed-in user; streams from Firestore and supports add/delete/restore.
  - Consumed by:
    - `HomeScreen` (recent scans + weekly summary)
    - `HistoryScreen` / `HistoryDetailScreen`
    - `ProfileScreen` (activity + clear history)
    - `ResultScreen` (save scan)
    - `DashboardScreen` (used for venue KPI estimation)

- `AlertsProvider` (`lib/providers/alerts_provider.dart`)
  - Manages: venue alerts stream, pending count, resolve/unresolve.
  - Consumed by:
    - `AlertsScreen` / `AlertDetailScreen`
    - `RestaurantProfileScreen`
    - `DashboardScreen`
    - `HomeScreen` (customer-facing alert summary)

- `InventoryProvider` (`lib/providers/inventory_provider.dart`)
  - Manages: venue inventory stream, expiry/freshness updates, CRUD.
  - Consumed by:
    - `InventoryScreen` / `InventoryItemScreen`
    - `RestaurantProfileScreen`
    - `DashboardScreen`
    - `StaffResultScreen` (remove spoiled items / jump to inventory)

---

## 6) API INTEGRATION MAP

### FastAPI backend

Base URL is defined in `lib/core/constants.dart`:

- `apiBaseUrl = http://10.0.2.2:8000`

Endpoints used by the app:

- `POST {apiBaseUrl}/predict/nutrients`
  - Implemented in: `lib/core/api_service.dart` (`ApiService.predictNutrients(File image)`)
  - Called by screen:
    - `ScanScreen` (`lib/features/customer/scan/scan_screen.dart`)
  - Returned model:
    - `NutrientResult` (`lib/core/models/nutrient_result.dart`)
  - Next step in UI:
    - Navigates to `ResultScreen` (`/customer/result`) with parsed nutrient data.

- `POST {apiBaseUrl}/predict/freshness`
  - Implemented in: `lib/core/api_service.dart` (`ApiService.predictFreshness(File image)`)
  - Called by screen:
    - `StaffScanScreen` (`lib/features/restaurant/scan/staff_scan_screen.dart`) when freshness mode is selected
  - Returned shape (mock for now):
    - `{ status, confidence, daysLeft }`
  - Next step in UI:
    - Navigates to `StaffResultScreen` (`/restaurant/scan/result`).

- `POST {apiBaseUrl}/predict/compost`
  - Implemented in: `lib/core/api_service.dart` (`ApiService.predictCompost(File image)`)
  - Called by screen:
    - `StaffScanScreen` (`lib/features/restaurant/scan/staff_scan_screen.dart`) when compost mode is selected
  - Returned shape (mock for now):
    - `{ isCompostable, confidence, category }`
  - Next step in UI:
    - Navigates to `StaffResultScreen` (`/restaurant/scan/result`).

### Firebase (not FastAPI, but core to the app)

- Auth: email/password via `FirebaseAuth` (wrapped by `FirebaseService` and orchestrated by `UserProvider`).
- Firestore:
  - `users/{uid}` → `UserProvider`
  - `scans/{uid}` (or equivalent collection) → `ScanHistoryProvider`
  - `alerts/{venueId}` → `AlertsProvider`
  - `inventory/{venueId}` → `InventoryProvider`
  - `venues/{venueId}/waste` → `FirebaseService.logWaste(...)` from `StaffResultScreen`

---

### Optional: Mermaid overview (visual)

```mermaid
flowchart LR
  subgraph App
    A[main.dart\nMultiProvider] --> R[GoRouter\napp_router.dart]
    R --> CS[CustomerShell]
    R --> SS[RestaurantShell\n(venue-aware)]

    CS --> CH[Customer Screens]
    SS --> SH[Staff Screens]

    CH --> P[Providers]
    SH --> P

    P --> FB[FirebaseService]
    P --> API[ApiService]
  end

  FB --> Auth[(Firebase Auth)]
  FB --> FS[(Firestore)]
  API --> FastAPI[(FastAPI Backend)]
```
