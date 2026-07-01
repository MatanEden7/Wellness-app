import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for user profile service
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  throw UnimplementedError('UserProfileService must be overridden');
});

// Simple provider for setup completion status - avoids recreating router
final isSetupCompletedProvider = Provider<bool>((ref) {
  final profileService = ref.watch(userProfileServiceProvider);
  // This creates a listenable that notifies when isSetupCompleted changes
  return profileService.isSetupCompleted;
});

// User profile data model
class UserProfile {
  // Basic info
  final String sex; // male, female
  final int ageYears;
  final int heightCm;
  final double weightKg;
  
  // Goals
  final String goal; // fat_loss, muscle_gain, maintenance, mobility_rehab
  final String activityLevel; // sedentary, light, moderate, active, very_active
  final int trainingDaysPerWeek;
  
  // Equipment & preferences
  final List<String> equipment;
  final String dietType; // omnivore, carnivore, herbivore
  final String mealCountPerDay; // 2, 3, 4, intermittent_fasting_16_8
  final List<String> exclusions;
  final List<String> injuries;
  
  // Units
  final String energyUnit; // kcal, kJ
  final String weightUnit; // g, oz
  
  // Calculated values (from formulas)
  final double bmr;
  final double tdee;
  final double calorieTarget;
  final double proteinTargetG;
  final double fatTargetG;
  final double carbsTargetG;

  const UserProfile({
    required this.sex,
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.activityLevel,
    required this.trainingDaysPerWeek,
    required this.equipment,
    required this.dietType,
    required this.mealCountPerDay,
    required this.exclusions,
    required this.injuries,
    required this.energyUnit,
    required this.weightUnit,
    required this.bmr,
    required this.tdee,
    required this.calorieTarget,
    required this.proteinTargetG,
    required this.fatTargetG,
    required this.carbsTargetG,
  });

  Map<String, dynamic> toJson() => {
    'sex': sex,
    'ageYears': ageYears,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'goal': goal,
    'activityLevel': activityLevel,
    'trainingDaysPerWeek': trainingDaysPerWeek,
    'equipment': equipment,
    'dietType': dietType,
    'mealCountPerDay': mealCountPerDay,
    'exclusions': exclusions,
    'injuries': injuries,
    'energyUnit': energyUnit,
    'weightUnit': weightUnit,
    'bmr': bmr,
    'tdee': tdee,
    'calorieTarget': calorieTarget,
    'proteinTargetG': proteinTargetG,
    'fatTargetG': fatTargetG,
    'carbsTargetG': carbsTargetG,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    sex: json['sex'] as String,
    ageYears: json['ageYears'] as int,
    heightCm: json['heightCm'] as int,
    weightKg: (json['weightKg'] as num).toDouble(),
    goal: json['goal'] as String,
    activityLevel: json['activityLevel'] as String,
    trainingDaysPerWeek: json['trainingDaysPerWeek'] as int,
    equipment: List<String>.from(json['equipment'] as List),
    dietType: json['dietType'] as String,
    mealCountPerDay: json['mealCountPerDay'] as String,
    exclusions: List<String>.from(json['exclusions'] as List),
    injuries: List<String>.from(json['injuries'] as List),
    energyUnit: json['energyUnit'] as String,
    weightUnit: json['weightUnit'] as String,
    bmr: (json['bmr'] as num).toDouble(),
    tdee: (json['tdee'] as num).toDouble(),
    calorieTarget: (json['calorieTarget'] as num).toDouble(),
    proteinTargetG: (json['proteinTargetG'] as num).toDouble(),
    fatTargetG: (json['fatTargetG'] as num).toDouble(),
    carbsTargetG: (json['carbsTargetG'] as num).toDouble(),
  );

  UserProfile copyWith({
    String? sex,
    int? ageYears,
    int? heightCm,
    double? weightKg,
    String? goal,
    String? activityLevel,
    int? trainingDaysPerWeek,
    List<String>? equipment,
    String? dietType,
    String? mealCountPerDay,
    List<String>? exclusions,
    List<String>? injuries,
    String? energyUnit,
    String? weightUnit,
    double? bmr,
    double? tdee,
    double? calorieTarget,
    double? proteinTargetG,
    double? fatTargetG,
    double? carbsTargetG,
  }) {
    return UserProfile(
      sex: sex ?? this.sex,
      ageYears: ageYears ?? this.ageYears,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      equipment: equipment ?? this.equipment,
      dietType: dietType ?? this.dietType,
      mealCountPerDay: mealCountPerDay ?? this.mealCountPerDay,
      exclusions: exclusions ?? this.exclusions,
      injuries: injuries ?? this.injuries,
      energyUnit: energyUnit ?? this.energyUnit,
      weightUnit: weightUnit ?? this.weightUnit,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      proteinTargetG: proteinTargetG ?? this.proteinTargetG,
      fatTargetG: fatTargetG ?? this.fatTargetG,
      carbsTargetG: carbsTargetG ?? this.carbsTargetG,
    );
  }
}

class UserProfileService extends ChangeNotifier {
  final SharedPreferences _prefs;
  
  static const String _profileKey = 'user_profile';
  static const String _setupCompletedKey = 'setup_completed';
  
  UserProfileService(this._prefs);
  
  // Check if user has completed setup
  bool get isSetupCompleted => _prefs.getBool(_setupCompletedKey) ?? false;
  
  Future<void> setSetupCompleted(bool completed) async {
    await _prefs.setBool(_setupCompletedKey, completed);
  }
  
  // Load user profile
  UserProfile? loadProfile() {
    final json = _prefs.getString(_profileKey);
    if (json == null) return null;
    
    try {
      final Map<String, dynamic> data = {};
      // Parse simple JSON string format
      json.split(',').forEach((pair) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          data[parts[0].trim()] = parts[1].trim();
        }
      });
      return UserProfile.fromJson(data);
    } catch (e) {
      print('[PROFILE] Error loading profile: $e');
      return null;
    }
  }
  
  // Save user profile
  Future<void> saveProfile(UserProfile profile) async {
    try {
      final json = profile.toJson();
      // Simple string storage format
      final jsonString = json.entries
          .map((e) => '${e.key}:${e.value}')
          .join(',');
      await _prefs.setString(_profileKey, jsonString);
      await setSetupCompleted(true);
      print('[PROFILE] ✅ Profile saved successfully');
      notifyListeners(); // Notify router to refresh
    } catch (e) {
      print('[PROFILE] ❌ Error saving profile: $e');
      rethrow;
    }
  }
  
  // Clear profile
  Future<void> clearProfile() async {
    await _prefs.remove(_profileKey);
    await setSetupCompleted(false);
    print('[PROFILE] 🗑️ Profile cleared');
    notifyListeners(); // Notify router to refresh and redirect to onboarding
  }
}

