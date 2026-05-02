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
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
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
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String raw) {
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
