import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for user profile service
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  throw UnimplementedError('UserProfileService must be overridden');
});

/// The raw preference store.
///
/// Exposed as a provider so the backup can capture *every* key the app owns
/// rather than a hand-maintained list of them. Enumerating keys would rebuild
/// the same drift problem the export key set already suffers from: add a
/// preference, forget the list, lose it silently on restore.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
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

  /// beginner, intermediate, advanced.
  ///
  /// Strength, not daily movement -- `activityLevel` is a calorie input and a
  /// poor proxy for it, because an active postman is not an experienced
  /// lifter. This is what turns a rep range into an actual starting weight,
  /// so guessing it wrong prescribes a load someone cannot safely handle.
  ///
  /// Defaults to `beginner` when absent, which is every profile saved before
  /// this field existed. That default is deliberate: it produces the lightest
  /// prescriptions, so an unknown user is never over-loaded.
  final String trainingExperience;

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
    this.trainingExperience = 'beginner',
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
        'trainingExperience': trainingExperience,
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
        // Absent on every profile saved before this field existed.
        trainingExperience: json['trainingExperience'] as String? ?? 'beginner',
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
    String? trainingExperience,
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
      trainingExperience: trainingExperience ?? this.trainingExperience,
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

  /// Loads the saved profile, or null when setup has not run yet.
  ///
  /// Note this used to be unrecoverable: the profile was written as
  /// `key:value,key:value`, but list fields (equipment, exclusions, injuries)
  /// stringify as `[a, b]` and contain the field separator, so the format could
  /// not be parsed back. It is plain JSON now.
  UserProfile? loadProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;

    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[PROFILE] Error loading profile: $e');
      return null;
    }
  }

  // Save user profile
  ///
  /// [markSetupComplete] exists for onboarding, which must **not** flip the
  /// flag here. The router takes `profileService` as its `refreshListenable`
  /// and redirects `/onboarding -> /` the moment `isSetupCompleted` turns
  /// true, so marking completion at the point the profile is written tears the
  /// wizard down while it is still awaiting the workout, meal and calendar
  /// generators that run after it. The calendar schedule is generated last and
  /// through `ref.read`, so it is the first thing to die on the disposed
  /// container -- which is why the symptom was "onboarding didn't create my
  /// plan" with a profile that otherwise looked fine, and why it never
  /// recovered: the flag was already true, so onboarding never ran again.
  Future<void> saveProfile(
    UserProfile profile, {
    bool markSetupComplete = true,
  }) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    if (markSetupComplete) {
      await setSetupCompleted(true);
    }
    notifyListeners(); // Notify router to refresh
  }

  // Clear profile
  Future<void> clearProfile() async {
    await _prefs.remove(_profileKey);
    await setSetupCompleted(false);
    notifyListeners(); // Notify router to refresh and redirect to onboarding
  }
}
