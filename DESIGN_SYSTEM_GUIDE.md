# Conscious Living App - Redesign Pattern Guide

## Completed Work ✓

### 1. Unified Color System (`lib/theme/role_colors.dart`)

- **Background**: `#F5F0E8` (AppColors.backgroundColor)
- **Primary**: `#8B1A1A` (AppColors.primary) - Burgundy for buttons, active states
- **Secondary**: `#E8A020` (AppColors.secondary) - Amber for alerts, highlights
- **Card**: `#FFFFFF` (AppColors.cardBackground) - White cards
- **Text Primary**: `#1A1A1A` (AppColors.textPrimary)
- **Text Secondary**: `#6B6B6B` (AppColors.textSecondary)
- **Status Colors**: success (#4CAF50), warning (#FF9800), danger (#D32F2F)

### 2. Unified Typography (`lib/theme/app_theme.dart`)

- All typography uses **Inter** font (no DM Serif Display anywhere)
- Page titles: **bold 22px** (`FontWeight.w700`)
- Section titles: **semibold 16px** (`FontWeight.w600`)
- Body text: **regular 14px** (`FontWeight.w400`)
- Captions: **12px**

### 3. Reusable Components Created

#### `lib/shared/widgets/app_card.dart`

```dart
// Standard card with 16px radius, white background, soft shadow
AppCard(
  child: yourContent,
  padding: EdgeInsets.all(16),
  borderRadius: BorderRadius.circular(16),
  backgroundColor: AppColors.cardBackground,
)

// Elevated card with more shadow
ElevatedAppCard(child: yourContent)

// Card with left accent color
AccentCard(
  child: yourContent,
  accentColor: AppColors.secondary,
)
```

#### `lib/shared/widgets/app_buttons.dart`

```dart
// Primary burgundy button (52px height)
PrimaryButton(
  label: 'Action',
  onPressed: () {},
)

// Secondary outlined button
SecondaryButton(
  label: 'Cancel',
  onPressed: () {},
)

// Compact amber button
CompactButton(
  label: 'Tag',
  onPressed: () {},
  backgroundColor: AppColors.secondary,
)
```

#### `lib/shared/widgets/app_inputs.dart`

```dart
// Standard text field (52px height, light grey border)
AppTextField(
  hintText: 'Email',
  labelText: 'Email Address',
)

// Search field
AppSearchField(
  hintText: 'Search...',
  onChanged: (value) {},
)

// Pill toggle (role selector)
PillToggle(
  options: ['Customer', 'Restaurant', 'Hotel'],
  onChanged: (index) {},
)
```

#### `lib/shared/widgets/app_bottom_nav.dart`

```dart
// Bottom navigation with centered scan button
// Automatically has 4 tabs based on role:
// - Customer: Home, Scan, Health, Profile
// - Restaurant: Dashboard, Scan, Waste, Profile
// - Hotel: Dashboard, Scan, Guests, Profile

AppBottomNav(
  currentIndex: _currentIndex,
  onTap: (index) => setState(() => _currentIndex = index),
  role: BottomNavRole.customer,
)
```

### 4. Screens Updated

✅ **Splash Screen** - Cream background, updated colors and animations
✅ **Onboarding Screen** - Unified color scheme, dark text on light background
✅ **Role Selector Screen** - Started update (background color, header styling)

## How to Apply Pattern to Remaining Screens

### Key Changes for All Screens:

#### 1. Background Colors

```dart
// OLD: backgroundColor: Color(0xFF0D0A14), or role-specific
// NEW:
backgroundColor: AppColors.backgroundColor, // #F5F0E8
```

#### 2. Text Colors (Light → Dark)

```dart
// OLD: color: Colors.white
// NEW: color: AppColors.textPrimary

// OLD: color: Colors.white.withValues(alpha: 0.6)
// NEW: color: AppColors.textSecondary
```

#### 3. Typography (Inter only, no DM Serif)

```dart
// OLD: GoogleFonts.dmSerifDisplay(fontSize: 22, fontWeight: FontWeight.w400)
// NEW: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)
```

#### 4. Input Fields (52px height with light border)

```dart
// Replace all TextFormField/TextField with:
AppTextField(
  hintText: 'Placeholder',
  labelText: 'Label',
  onChanged: (value) {},
)
// Handles: 52px height, light grey border, rounded corners, burgundy focus
```

#### 5. Buttons (52px height, 12px radius)

```dart
// Primary actions:
PrimaryButton(label: 'Continue', onPressed: () {})

// Secondary actions:
SecondaryButton(label: 'Cancel', onPressed: () {})

// Small inline:
CompactButton(label: 'Edit', onPressed: () {})
```

#### 6. Cards (16px radius, white background, soft shadow)

```dart
// Replace Card() with:
AppCard(child: content)
or
ElevatedAppCard(child: content)

// For list items:
AppCard(
  padding: EdgeInsets.all(16),
  onTap: () {},
  child: ListItemContent(),
)
```

## Screen-by-Screen Update Checklist

### Authentication Screens

- [ ] customer_login_screen.dart
- [ ] customer_register_screen.dart
- [ ] customer_forgot_password_screen.dart
- [ ] customer_profile_setup_screen.dart
- [ ] restaurant_login_screen.dart
- [ ] restaurant_register_screen.dart
- [ ] restaurant_forgot_password_screen.dart
- [ ] restaurant_setup_screen.dart
- [ ] hotel_login_screen.dart
- [ ] hotel_register_screen.dart
- [ ] hotel_forgot_password_screen.dart
- [ ] hotel_setup_screen.dart

**For each auth screen:**

1. Import: `import '../../theme/role_colors.dart'`
2. Change backgroundColor to `AppColors.backgroundColor`
3. Replace all TextFormField with `AppTextField`
4. Replace buttons with `PrimaryButton`, `SecondaryButton`
5. Update all text colors from white → AppColors.text[Primary|Secondary]
6. Replace typography fonts from DM Serif → Inter
7. Wrap forms in `AppCard` if applicable

### Customer Screens

- [ ] features/customer/home/home_screen.dart
- [ ] features/customer/scan/scan_screen.dart
- [ ] features/customer/scan/result_screen.dart
- [ ] features/customer/history/history_screen.dart
- [ ] features/customer/history/history_detail_screen.dart
- [ ] features/customer/allergens/allergen_screen.dart
- [ ] features/customer/profile/profile_screen.dart
- [ ] features/customer/profile/edit_profile_screen.dart
- [ ] features/customer/profile/health_goals_screen.dart
- [ ] features/customer/customer_shell.dart (Add AppBottomNav)

**For customer shell:**

```dart
// Add bottom navigation
AppBottomNav(
  currentIndex: _selectedIndex,
  onTap: (index) => _navigate(index),
  role: BottomNavRole.customer,
)
```

### Restaurant Screens

- [ ] features/restaurant/dashboard/dashboard_screen.dart
- [ ] features/restaurant/scan/staff_scan_screen.dart
- [ ] features/restaurant/scan/staff_result_screen.dart
- [ ] features/restaurant/scan/contamination_scan_screen.dart
- [ ] features/restaurant/scan/contamination_result_screen.dart
- [ ] features/restaurant/waste/waste_screen.dart
- [ ] features/restaurant/waste/compost_screen.dart
- [ ] features/restaurant/alerts/alerts_screen.dart
- [ ] features/restaurant/alerts/alert_detail_screen.dart
- [ ] features/restaurant/inventory/inventory_screen.dart
- [ ] features/restaurant/inventory/inventory_item_screen.dart
- [ ] features/restaurant/profile/restaurant_profile_screen.dart
- [ ] features/restaurant/profile/edit_restaurant_profile_screen.dart
- [ ] features/restaurant/restaurant_shell.dart (Add AppBottomNav with Waste tab)

### Hotel Screens

- [ ] features/hotel/dashboard/hotel_dashboard_screen.dart
- [ ] features/hotel/scan/hotel_scan_screen.dart
- [ ] features/hotel/scan/hotel_result_screen.dart
- [ ] features/hotel/scan/hotel_contamination_scan_screen.dart
- [ ] features/hotel/scan/hotel_contamination_result_screen.dart
- [ ] features/hotel/profile/hotel_profile_screen.dart
- [ ] features/hotel/profile/edit_hotel_profile_screen.dart
- [ ] features/hotel/hotel_shell.dart (Add AppBottomNav with Guests tab)

## Color Implementation Examples

### For Stats Cards

```dart
AppCard(
  padding: EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Today\'s Calories',
        style: Theme.of(context).textTheme.labelMedium,
      ),
      SizedBox(height: 8),
      Text(
        '2,345 kcal',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    ],
  ),
)
```

### For Alert Cards (Accent Left Border)

```dart
AccentCard(
  accentColor: AppColors.danger,
  child: Text('Allergen detected: Peanuts'),
)
```

### For Progress/Health Indicators

```dart
// Green for protein
ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: LinearProgressIndicator(
    value: 0.75,
    backgroundColor: AppColors.borderLight,
    valueColor: AlwaysStoppedAnimation(AppColors.success),
    minHeight: 8,
  ),
)

// Amber for carbs
// valueColor: AlwaysStoppedAnimation(AppColors.secondary)

// Red for fat
// valueColor: AlwaysStoppedAnimation(AppColors.danger)
```

### For Warning/Expiry Badges

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.secondary.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(6),
  ),
  child: Text(
    'Expires in 2h',
    style: TextStyle(
      color: AppColors.secondary,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

## Important Rules Applied Everywhere

✅ **No dark backgrounds** - All backgrounds are cream (#F5F0E8) or white
✅ **No serif fonts** - All typography is Inter
✅ **Consistent padding** - Cards use 16px internal padding
✅ **Soft shadows** - All elevated elements use `BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,2))`
✅ **Bottom nav** - All role screens have 4-tab bottom navigation
✅ **Button heights** - All primary buttons are 52px, inputs are 52px
✅ **Border radius** - Buttons/inputs 12px, cards 16px
✅ **Icons** - Material Icons (flutter team), size 24px for nav, 20px for buttons
✅ **List items** - Each item in a white card with 16px radius, not flat rows

## Testing Checklist

- [ ] Splash screen displays with cream background and burgundy glow
- [ ] Onboarding has dark text on light background, readable
- [ ] Role selector shows burgundy cards with proper styling
- [ ] All auth screens have cream background, burgundy buttons
- [ ] Bottom nav appears on all customer/restaurant/hotel screens
- [ ] All text is readable (dark on light)
- [ ] No dark backgrounds anywhere
- [ ] All buttons are 52px tall
- [ ] All inputs have light grey borders and are 52px tall
- [ ] Cards have proper 16px border radius and soft shadows
- [ ] Focus states are burgundy
- [ ] Success/warning/danger colors work throughout
- [ ] Fonts are all Inter (no DM Serif Display)

## Quick Find-Replace Commands (Batch Updates)

In VS Code, use Find & Replace (Ctrl+H) with Regex enabled:

1. **Find dark backgrounds:**
   - Find: `backgroundColor: (Color\(0x[0-9A-F]{8}\)|Colors.black)`
   - Replace: `backgroundColor: AppColors.backgroundColor`

2. **Fix white text:**
   - Find: `color: Colors\.white`
   - Replace: `color: AppColors.textPrimary`

3. **Fix serif display font:**
   - Find: `GoogleFonts\.dmSerifDisplay\(`
   - Replace: `GoogleFonts.inter(`

4. **Import statement:**
   - Add to each file: `import '../../theme/role_colors.dart';`
