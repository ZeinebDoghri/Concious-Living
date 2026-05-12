import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final List<String> conditions;
  final List<String> allergens;
  final int calorieGoal;
  final String role; // 'customer' | 'restaurant' | 'hotel'
  final bool notifyDailyIntake;
  final bool notifyAllergens;
  final bool notifyWeeklyReport;
  final String? avatarPath;
  final String? entityId;
  final String? restaurantId;
  final String? hotelId;
  final String? city;


  // Restaurant-only fields
  final String? restaurantName;
  final String? cuisineType;
  final int? covers;
  final int? teamSize;
  final List<String> staffRoles;
  final bool? allergyHandling;
  final double? wasteThreshold;
  final String? restaurantAddress;
  final String? operatingHours;
  final List<String> dietaryOptions;

  // Hotel-only fields
  final String? hotelName;
  final String? hotelType;
  final int? rooms;

  // Health Plan fields
  final String? healthGoal;
  final String? activityLevel;
  final int? proteinGoal_g;
  final int? carbsGoal_g;
  final int? fatGoal_g;
  final double? waterGoal_L;
  final double? bmi;
  final List<String> dietaryPreferences;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.conditions,
    required this.allergens,
    required this.calorieGoal,
    required this.role,
    required this.notifyDailyIntake,
    required this.notifyAllergens,
    required this.notifyWeeklyReport,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.avatarPath,
    this.entityId,
    this.restaurantId,
    this.hotelId,
    this.restaurantName,
    this.cuisineType,
    this.covers,
    this.teamSize,
    this.staffRoles = const <String>[],
    this.allergyHandling,
    this.wasteThreshold,
    this.restaurantAddress,
    this.operatingHours,
    this.dietaryOptions = const <String>[],
    this.hotelName,
    this.hotelType,
    this.rooms,
    this.healthGoal,
    this.activityLevel,
    this.proteinGoal_g,
    this.carbsGoal_g,
    this.fatGoal_g,
    this.waterGoal_L,
    this.bmi,
    this.dietaryPreferences = const <String>[],
    this.city,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    List<String>? conditions,
    List<String>? allergens,
    int? calorieGoal,
    String? role,
    bool? notifyDailyIntake,
    bool? notifyAllergens,
    bool? notifyWeeklyReport,
    String? avatarPath,
    String? entityId,
    String? restaurantId,
    String? hotelId,
    String? restaurantName,
    String? cuisineType,
    int? covers,
    int? teamSize,
    List<String>? staffRoles,
    bool? allergyHandling,
    double? wasteThreshold,
    String? restaurantAddress,
    String? operatingHours,
    List<String>? dietaryOptions,
    String? hotelName,
    String? hotelType,
    int? rooms,
    String? healthGoal,
    String? activityLevel,
    int? proteinGoal_g,
    int? carbsGoal_g,
    int? fatGoal_g,
    double? waterGoal_L,
    double? bmi,
    List<String>? dietaryPreferences,
    String? city,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      conditions: conditions ?? this.conditions,
      allergens: allergens ?? this.allergens,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      role: role ?? this.role,
      notifyDailyIntake: notifyDailyIntake ?? this.notifyDailyIntake,
      notifyAllergens: notifyAllergens ?? this.notifyAllergens,
      notifyWeeklyReport: notifyWeeklyReport ?? this.notifyWeeklyReport,
      avatarPath: avatarPath ?? this.avatarPath,
      entityId: entityId ?? this.entityId,
      restaurantId: restaurantId ?? this.restaurantId,
      hotelId: hotelId ?? this.hotelId,
      restaurantName: restaurantName ?? this.restaurantName,
      cuisineType: cuisineType ?? this.cuisineType,
      covers: covers ?? this.covers,
      teamSize: teamSize ?? this.teamSize,
      staffRoles: staffRoles ?? this.staffRoles,
      allergyHandling: allergyHandling ?? this.allergyHandling,
      wasteThreshold: wasteThreshold ?? this.wasteThreshold,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      operatingHours: operatingHours ?? this.operatingHours,
      dietaryOptions: dietaryOptions ?? this.dietaryOptions,
      hotelName: hotelName ?? this.hotelName,
      hotelType: hotelType ?? this.hotelType,
      rooms: rooms ?? this.rooms,
      healthGoal: healthGoal ?? this.healthGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      proteinGoal_g: proteinGoal_g ?? this.proteinGoal_g,
      carbsGoal_g: carbsGoal_g ?? this.carbsGoal_g,
      fatGoal_g: fatGoal_g ?? this.fatGoal_g,
      waterGoal_L: waterGoal_L ?? this.waterGoal_L,
      bmi: bmi ?? this.bmi,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      city: city ?? this.city,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'conditions': conditions,
      'allergens': allergens,
      'calorieGoal': calorieGoal,
      'role': role,
      'notifyDailyIntake': notifyDailyIntake,
      'notifyAllergens': notifyAllergens,
      'notifyWeeklyReport': notifyWeeklyReport,
      'avatarPath': avatarPath,
      'entityId': entityId,
      'restaurantId': restaurantId,
      'hotelId': hotelId,
      'restaurantName': restaurantName,
      'cuisineType': cuisineType,
      'covers': covers,
      'teamSize': teamSize,
      'staffRoles': staffRoles,
      'allergyHandling': allergyHandling,
      'wasteThreshold': wasteThreshold,
      'restaurantAddress': restaurantAddress,
      'operatingHours': operatingHours,
      'dietaryOptions': dietaryOptions,
      'hotelName': hotelName,
      'hotelType': hotelType,
      'rooms': rooms,
      'healthGoal': healthGoal,
      'activityLevel': activityLevel,
      'proteinGoal_g': proteinGoal_g,
      'carbsGoal_g': carbsGoal_g,
      'fatGoal_g': fatGoal_g,
      'waterGoal_L': waterGoal_L,
      'bmi': bmi,
      'dietaryPreferences': dietaryPreferences,
    };

    // Prevent merge-writes from overwriting fields with null.
    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: json['phone'] as String?,
      dateOfBirth: (json['dateOfBirth'] as String?) == null
          ? null
          : DateTime.tryParse(json['dateOfBirth'] as String),
      gender: json['gender'] as String?,
      conditions: (json['conditions'] as List?)?.cast<String>() ?? <String>[],
      allergens: (json['allergens'] as List?)?.cast<String>() ?? <String>[],
      calorieGoal: (json['calorieGoal'] ?? 2000) as int,
      role: (json['role'] ?? 'customer') as String,
      notifyDailyIntake: (json['notifyDailyIntake'] ?? true) as bool,
      notifyAllergens: (json['notifyAllergens'] ?? true) as bool,
      notifyWeeklyReport: (json['notifyWeeklyReport'] ?? true) as bool,
      avatarPath: json['avatarPath'] as String?,
      entityId: json['entityId'] as String?,
      restaurantId: json['restaurantId'] as String?,
      hotelId: json['hotelId'] as String?,
      restaurantName: json['restaurantName'] as String?,
      cuisineType: json['cuisineType'] as String?,
      covers: (json['covers'] as num?)?.toInt(),
      teamSize: json['teamSize'] as int?,
      staffRoles: (json['staffRoles'] as List?)?.cast<String>() ?? <String>[],
      allergyHandling: json['allergyHandling'] as bool?,
      wasteThreshold: (json['wasteThreshold'] as num?)?.toDouble(),
      restaurantAddress: json['restaurantAddress'] as String?,
      operatingHours: json['operatingHours'] as String?,
      dietaryOptions:
          (json['dietaryOptions'] as List?)?.cast<String>() ?? <String>[],
      hotelName: json['hotelName'] as String?,
      hotelType: json['hotelType'] as String?,
      rooms: (json['rooms'] as num?)?.toInt(),
      healthGoal: json['healthGoal'] as String?,
      activityLevel: json['activityLevel'] as String?,
      proteinGoal_g: (json['proteinGoal_g'] as num?)?.toInt(),
      carbsGoal_g: (json['carbsGoal_g'] as num?)?.toInt(),
      fatGoal_g: (json['fatGoal_g'] as num?)?.toInt(),
      waterGoal_L: (json['waterGoal_L'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      dietaryPreferences: (json['dietaryPreferences'] as List?)?.cast<String>() ?? <String>[],
      city: json['city'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String raw) {
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
