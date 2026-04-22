import 'package:flutter/material.dart';

class AppColors {
  // Primary palette (brand)
  static const cherry = Color(0xFF8B1A1F);
  static const cherryDark = Color(0xFF6B1215);
  static const cherryLight = Color(0xFFB03A3F);
  static const cherryBlush = Color(0xFFFDEAEB);

  static const cherryHeaderText = Color(0xFFFFF8EE);

  static const olive = Color(0xFF5A7A18);
  static const oliveDark = Color(0xFF445C12);
  static const oliveLight = Color(0xFF7A9E22);
  static const oliveMist = Color(0xFFE8F3CC);

  static const oliveHeaderText = Color(0xFFF5FAE8);

  static const butter = Color(0xFFFFF3C4);
  static const butterDeep = Color(0xFFDDB93A);

  static const oat = Color(0xFFF7F2EC);
  static const oatDeep = Color(0xFFEDE5D8);

  // Extended neutrals
  static const parchment = Color(0xFFFFFFFF);
  static const sand = Color(0xFFE8DDD2);
  static const cocoa = Color(0xFF6B4F52);
  static const espresso = Color(0xFF3D2426);
  static const cream = Color(0xFFFDFAF7);
  static const fog = Color(0xFFA89698);

  // Semantic backgrounds (lightened)
  static const riskLowBg = oliveMist;
  static const riskModerateBg = butter;
  static const riskHighBg = cherryBlush;

  static const freshnessFreshBg = riskLowBg;
  static const freshnessWarnBg = riskModerateBg;
  static const freshnessBadBg = riskHighBg;

  // Semantic
  static const riskModerateText = Color(0xFF7A5E00);
  static const infoText = Color(0xFF185FA5);
  static const infoBg = Color(0xFFE6F1FB);
}

class AppRadii {
  static const screenCard = 20.0;
  static const innerCard = 16.0;
  static const button = 12.0;
  static const chip = 8.0;
  static const badge = 6.0;
  static const input = 12.0;
}

class AppSpacing {
  static const x4 = 4.0;
  static const x8 = 8.0;
  static const x12 = 12.0;
  static const x16 = 16.0;
  static const x20 = 20.0;
  static const x24 = 24.0;
  static const x32 = 32.0;
  static const x48 = 48.0;
}

class AppLimits {
  static const cholesterol = 300.0;
  static const saturatedFat = 20.0;
  static const sodium = 2300.0;
  static const sugar = 50.0;
}

class PrefKeys {
  static const seenOnboarding = 'seen_onboarding';
  static const venueType = 'venue_type';
  static const themePreference = 'theme_preference';
}

class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const roleSelector = '/role-selector';

  static const customerLogin = '/auth/customer/login';
  static const customerRegister = '/auth/customer/register';
  static const customerForgot = '/auth/customer/forgot';
  static const customerProfileSetup = '/auth/customer/profile-setup';

  static const restaurantLogin = '/auth/restaurant/login';
  static const restaurantRegister = '/auth/restaurant/register';
  static const restaurantForgot = '/auth/restaurant/forgot';
  static const restaurantSetup = '/auth/restaurant/setup';

  static const hotelLogin = '/auth/hotel/login';
  static const hotelRegister = '/auth/hotel/register';
  static const hotelForgotPassword = '/auth/hotel/forgot-password';
  static const hotelSetup = '/auth/hotel/setup';

  static const customerHome = '/customer/home';
  static const customerScan = '/customer/scan';
  static const customerResult = '/customer/result';
  static const customerHistory = '/customer/history';
  static const customerAllergens = '/customer/allergens';
  static const customerProfile = '/customer/profile';
  static const customerEditProfile = '/customer/profile/edit';
  static const healthGoals = '/customer/health-goals';
  static const nutritionProgress = '/customer/nutrition-progress';
  static const nutritionGoals = '/customer/nutrition-goals';

  static const restaurantDashboard = '/restaurant/dashboard';
  static const restaurantScan = '/restaurant/scan';
  static const restaurantScanResult = '/restaurant/scan/result';
  static const restaurantAlerts = '/restaurant/alerts';
  static const restaurantWaste = '/restaurant/waste';
  static const restaurantCompost = '/restaurant/compost';
  static const restaurantInventory = '/restaurant/inventory';
  static const restaurantProfile = '/restaurant/profile';
  static const restaurantProfileEdit = '/restaurant/profile/edit';

  static const hotelProfile = '/hotel/profile';
  static const hotelProfileEdit = '/hotel/profile/edit';

  static String customerHistoryDetail(String id) => '/customer/history/$id';

  static String restaurantAlertDetail(String id) => '/restaurant/alert/$id';

  static String restaurantInventoryItem(String id) => '/restaurant/inventory/$id';
}

class AppData {
  static const commonAllergens = <String>[
    'Gluten',
    'Dairy',
    'Eggs',
    'Peanuts',
    'Tree nuts',
    'Soy',
    'Fish',
    'Shellfish',
    'Sesame',
    'Celery',
    'Mustard',
  ];
}

class AppStrings {
  static const appNameUpper = 'CONSCIOUS LIVING';
  static const appName = 'Conscious Living';
  static const tagline = 'Eat smart. Waste less.';
  static const taglineLong = 'Eat smart · Waste less · Live better';

  static const next = 'Next';
  static const skip = 'Skip';
  static const getStarted = 'Get Started';

  static const whoAreYou = 'Who are you?';
  static const chooseRole = 'Choose your role to get started.';
  static const iAmCustomer = "I'm a Customer";
  static const iAmRestaurant = "I'm Restaurant Staff";
  static const iAmHotel = "I'm Hotel Staff";
  static const customerCardSubtitle = 'Scan dishes · Track nutrition · Allergen alerts';
  static const restaurantCardSubtitle = 'Waste monitoring · Food safety · Inventory alerts';
  static const hotelCardSubtitle = 'Room service · Guest health · Kitchen alerts';

  static const chooseBusinessType = 'Choose business type';
  static const chooseBusinessTypeSubtitle = 'Select what kind of place you manage.';
  static const restaurant = 'Restaurant';
  static const hotel = 'Hotel';

  static const welcomeBack = 'Welcome back';
  static const customerSignInTitle = 'Customer sign in';
  static const customerSignInSubtitle = 'Your health journey continues';
  static const restaurantSignInTitle = 'Restaurant sign in';
  static const restaurantSignInSubtitle = 'Manage your kitchen operations';
  static const signInToContinue = 'Sign in to continue your journey';

  static const emailAddress = 'Email address';
  static const password = 'Password';
  static const forgotPassword = 'Forgot password?';
  static const signIn = 'Sign In';
  static const orSignInWith = 'or sign in with';
  static const createAccount = 'Create account';
  static const notACustomer = 'Not a customer?';
  static const notRestaurantStaff = 'Not restaurant staff?';

  static const createYourAccount = 'Create your account';
  static const joinToday = 'Join Conscious Living today';
  static const fullName = 'Full name';
  static const confirmPassword = 'Confirm password';
  static const createAccountCta = 'Create account';
  static const alreadyHaveAccount = 'Already have an account? Sign in';

  static const termsPrefix = 'By creating an account you agree to our ';
  static const termsOfService = 'Terms of Service';

  static const resetPassword = 'Reset password';
  static const resetYourPassword = 'Reset password';
  static const resetPasswordSubtitle = "Enter your email and we'll send a reset link.";
  static const enterYourEmail = "Enter your email and we'll send a reset link.";
  static const checkYourEmail = 'Check your email';
  static const resetEmailSent = 'We sent a reset link to your inbox.';
  static const forgotYourPasswordTitle = 'Forgot your password?';
  static const forgotYourPasswordBody = "Enter your email and we'll send a reset link.";
  static const sendResetLink = 'Send reset link';
  static const resetSentTitle = 'Reset link sent!';
  static const resetSentBody = 'Check your inbox and follow the instructions.';
  static const backToSignIn = 'Back to sign in';

  static const setupYourProfile = 'Set up your profile';
  static const continueCta = 'Continue';
  static const completeSetup = 'Complete setup';
  static const setupRestaurantProfile = 'Set up restaurant profile';

  static const yourHealthProfile = 'Your health profile';
  static const personaliseAlerts = 'Personalise your nutrient alerts';
  static const chronicConditionsQ = 'Do you have any chronic conditions?';
  static const dailyCalorieGoal = 'Daily calorie goal';

  static const notificationPreferences = 'Notification preferences';
  static const dailyIntakeSummary = 'Daily intake summary';
  static const allergenAlerts = 'Allergen alerts';
  static const weeklyHealthReport = 'Weekly health report';
  static const preferredLanguage = 'Preferred language';

  static const scanYourDish = 'Scan your dish';
  static const takePhotoOrUpload = 'Take a photo or upload from gallery';
  static const analysingDish = 'Analysing your dish...';
  static const centerDishHint = 'Center your dish inside the frame';
  static const uploadFromGallery = 'Upload from gallery';

  static const nutritionAnalysis = 'Nutrition analysis';
  static const overallRiskLevel = 'Overall risk level';
  static const ofDailyLimit = 'of daily limit';
  static const whatThisMeans = 'What this means for you';
  static const saveToHistory = 'Save to history';
  static const scanAnotherDish = 'Scan another dish';

  static const scanHistory = 'Scan history';
  static const searchScans = 'Search scans...';
  static const noScansYet = 'No scans yet';
  static const noScansSubtitle = 'Scan your first dish to see history here';
  static const today = 'Today';
  static const yesterday = 'Yesterday';
  static const thisWeek = 'This week';

  static const scanDetail = 'Scan detail';
  static const savedOn = 'Saved on';
  static const scanAgain = 'Scan again';

  static const myAllergenProfile = 'My allergen profile';
  static const allergenBanner = 'Your allergens are flagged every time you scan a dish.';
  static const myAllergens = 'My allergens';
  static const noAllergensTitle = 'No allergens registered';
  static const noAllergensSubtitle = 'Update your health profile to add allergens';
  static const editAllergenProfile = 'Edit allergen profile';
  static const recentAllergenWarnings = 'Recent allergen warnings';
  static const allergenInformation = 'Allergen information';

  static const profile = 'Profile';
  static const settings = 'Settings';
  static const dailyIntakeGoals = 'Daily intake goals';
  static const aboutProject = 'About the project';
  static const clearScanHistory = 'Clear scan history';
  static const signOut = 'Sign out';

  static const healthGoals = 'Health goals';
  static const saveGoals = 'Save goals';

  static const cholesterolLabel = 'Cholesterol';
  static const saturatedFatLabel = 'Saturated fat';
  static const sodiumLabel = 'Sodium';
  static const sugarLabel = 'Sugar';
  static const unitMg = 'mg';
  static const unitG = 'g';

  static const kitchenDashboard = 'Kitchen Dashboard';
  static const unresolved = 'unresolved';
  static const alerts = 'Alerts';
  static const wasteReport = 'Waste report';
  static const inventoryExpiry = 'Inventory & Expiry';
  static const inventoryAndExpiry = 'Inventory & Expiry';

  static const home = 'Home';
  static const scan = 'Scan';
  static const history = 'History';
  static const allergens = 'Allergens';

  static const wasteReportTitle = 'Waste Report';
  static const topWastedItems = 'Top wasted items';
  static const tapToSeeFullReport = 'Tap to see full report';
  static const compostOverview = 'Compost overview';
  static const viewCompostBreakdown = 'View compost breakdown';

  static const compostClassification = 'Compost Classification';
  static const whatsCompostable = "What's compostable?";
  static const nonCompostableItems = 'Non-compostable items';
  static const takeAction = 'Take action';
  static const logNewWasteBatch = 'Log new waste batch';

  static const compostableFruitVeg = 'Fruit & vegetable scraps';
  static const compostableCoffee = 'Coffee grounds';
  static const compostableEggshells = 'Eggshells';
  static const compostablePaper = 'Uncoated paper towels';
  static const nonCompostablePlastic = 'Plastic packaging';
  static const nonCompostableGlass = 'Glass';
  static const nonCompostableMetal = 'Metal';
  static const nonCompostableOil = 'Cooking oil';

  static const itemsNeedAttention = 'items need attention';
  static const inventory = 'Inventory';

  static const dashboard = 'Dashboard';
  static const waste = 'Waste';

  static const alertDetail = 'Alert detail';
  static const markAsResolved = 'Mark as resolved';
  static const markedResolved = 'Marked resolved';
  static const alertDetails = 'Alert details';
  static const alertNotFound = 'Alert not found';
  static const alertResolved = 'Alert resolved';

  static const pending = 'Pending';
  static const resolved = 'Resolved';

  static const dish = 'Dish';
  static const customer = 'Customer';
  static const allergen = 'Allergen';
  static const status = 'Status';
  static const recommendedNextSteps = 'Recommended next steps';
  static const stepConfirmWithCustomer = 'Confirm the allergen with the customer.';
  static const stepCheckIngredients = 'Check the ingredient list and prep surfaces.';
  static const stepSanitizeStation = 'Sanitize the station and prevent cross-contact.';

  static const resolveAlertConfirm = 'This will mark the alert as resolved. You can undo it.';

  static const remove = 'Remove';
  static const keep = 'Keep';
  static const useToday = 'Use today';

  static const ok = 'OK';
  static const cancel = 'Cancel';
  static const confirm = 'Confirm';
  static const undo = 'Undo';

  static const all = 'All';
  static const fresh = 'Fresh';
  static const expiringSoon = 'Expiring soon';
  static const spoiled = 'Spoiled';
  static const searchInventory = 'Search inventory...';
  static const inventoryItem = 'Inventory item';
  static const quantity = 'Quantity';
  static const expiry = 'Expiry';
  static const updateExpiry = 'Update expiry';

  static const wasteItemLettuce = 'Lettuce';
  static const wasteItemTomatoes = 'Tomatoes';
  static const wasteItemBread = 'Bread';
  static const wasteItemChicken = 'Chicken';

  static const justNow = 'Just now';
  static const minutesAgo = 'min ago';
  static const hoursAgo = 'h ago';
  static const daysAgo = 'd ago';

  static const validationInvalidEmail = 'Please enter a valid email.';
  static const validationPasswordMin = 'Password must be at least 6 characters.';
  static const validationRequiredField = 'This field is required.';
  static const validationPasswordsMismatch = 'Passwords do not match';
  static const genericError = 'Something went wrong. Please try again.';

  static String greetingForHour(int hour) {
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  static String kcal(int value) => '$value kcal';

  static String expiresOn(String date) => 'Expires: $date';

  static String expiringSoonUseBefore(String date) => 'Expiring soon. Use before $date';

  static String savedOnDate(String date) => '$savedOn $date';

  static String unresolvedCount(int count) => '[$count] $unresolved';

  static String itemsNeedAttentionCount(int count) => '[$count] $itemsNeedAttention';

  static String containsAllergen(String allergen) => '⚠ Contains $allergen';

  static String allergenDetected(String allergen) => '⚠ $allergen detected';

  static String percent(int value) => '$value%';

  static const freshnessFresh = 'Fresh';
  static const freshnessExpiringSoon = 'Expiring soon';
  static const freshnessSpoiled = 'Spoiled';

  static const riskLow = 'Low risk';
  static const riskModerate = 'Moderate';
  static const riskHigh = 'High risk';
}

const String apiBaseUrl = 'http://10.0.2.2:8000';
