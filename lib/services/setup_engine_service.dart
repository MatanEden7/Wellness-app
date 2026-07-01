import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'user_profile_service.dart';

class SetupEngineService {
  late YamlMap _spec;
  bool _isInitialized = false;
  
  // Load the setup spec from assets
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final yamlString = await rootBundle.loadString('assets/data/setup_engine_spec.yaml');
    _spec = loadYaml(yamlString) as YamlMap;
    _isInitialized = true;
    print('[SETUP-ENGINE] ✅ Spec loaded successfully');
  }
  
  // Calculate BMR using Mifflin-St Jeor equation
  double calculateBMR({
    required String sex,
    required double weightKg,
    required int heightCm,
    required int ageYears,
  }) {
    if (sex == 'male') {
      return 10 * weightKg + 6.25 * heightCm - 5 * ageYears + 5;
    } else {
      return 10 * weightKg + 6.25 * heightCm - 5 * ageYears - 161;
    }
  }
  
  // Get activity factor
  double getActivityFactor(String activityLevel) {
    final factors = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };
    return factors[activityLevel] ?? 1.2;
  }
  
  // Calculate TDEE
  double calculateTDEE(double bmr, String activityLevel) {
    return bmr * getActivityFactor(activityLevel);
  }
  
  // Calculate calorie target based on goal
  double calculateCalorieTarget(double tdee, String goal) {
    switch (goal) {
      case 'fat_loss':
        return tdee - 400;
      case 'muscle_gain':
        return tdee + 250;
      case 'maintenance':
      case 'mobility_rehab':
        return tdee;
      default:
        return tdee;
    }
  }
  
  // Calculate protein target in grams
  double calculateProteinTarget(double weightKg, String goal) {
    final proteinPerKg = {
      'fat_loss': 2.2,
      'muscle_gain': 2.0,
      'maintenance': 1.8,
      'mobility_rehab': 1.6,
    };
    return weightKg * (proteinPerKg[goal] ?? 1.8);
  }
  
  // Calculate fat target in grams (minimum)
  double calculateFatTarget(double weightKg, double calorieTarget, double proteinG) {
    final fatMinGPerKg = 0.6;
    final fatMinG = weightKg * fatMinGPerKg;
    
    // Can be higher based on remaining calories, but start with minimum
    return fatMinG;
  }
  
  // Calculate carbs target in grams (fills remaining calories)
  double calculateCarbsTarget(double calorieTarget, double proteinG, double fatG) {
    final caloriesFromProtein = proteinG * 4;
    final caloriesFromFat = fatG * 9;
    final remainingCalories = calorieTarget - caloriesFromProtein - caloriesFromFat;
    final carbsG = remainingCalories / 4;
    return carbsG > 0 ? carbsG : 0;
  }
  
  // Get macro percentages for display (chip/progress visuals)
  // This matches the percent_defaults from the spec (lines 91-95)
  static Map<String, int> getMacroPercentages(String goal) {
    final defaults = {
      'fat_loss': {'protein_pct': 35, 'fat_pct': 30, 'carbs_pct': 35},
      'muscle_gain': {'protein_pct': 30, 'fat_pct': 25, 'carbs_pct': 45},
      'maintenance': {'protein_pct': 25, 'fat_pct': 30, 'carbs_pct': 45},
      'mobility_rehab': {'protein_pct': 25, 'fat_pct': 35, 'carbs_pct': 40},
    };
    
    final goalDefaults = defaults[goal] ?? defaults['maintenance']!;
    return {
      'protein': goalDefaults['protein_pct']!,
      'fat': goalDefaults['fat_pct']!,
      'carbs': goalDefaults['carbs_pct']!,
    };
  }
  
  // Create complete user profile from inputs
  UserProfile createUserProfile({
    required String sex,
    required int ageYears,
    required int heightCm,
    required double weightKg,
    required String goal,
    required String activityLevel,
    required int trainingDaysPerWeek,
    required List<String> equipment,
    required String dietType,
    required String mealCountPerDay,
    required List<String> exclusions,
    required List<String> injuries,
    String energyUnit = 'kcal',
    String weightUnit = 'g',
  }) {
    // Calculate all derived values
    final bmr = calculateBMR(
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
    );
    
    final tdee = calculateTDEE(bmr, activityLevel);
    final calorieTarget = calculateCalorieTarget(tdee, goal);
    final proteinG = calculateProteinTarget(weightKg, goal);
    final fatG = calculateFatTarget(weightKg, calorieTarget, proteinG);
    final carbsG = calculateCarbsTarget(calorieTarget, proteinG, fatG);
    
    print('[SETUP-ENGINE] 📊 Calculated targets:');
    print('  BMR: ${bmr.toStringAsFixed(0)} kcal');
    print('  TDEE: ${tdee.toStringAsFixed(0)} kcal');
    print('  Target: ${calorieTarget.toStringAsFixed(0)} kcal');
    print('  Protein: ${proteinG.toStringAsFixed(0)}g');
    print('  Fat: ${fatG.toStringAsFixed(0)}g');
    print('  Carbs: ${carbsG.toStringAsFixed(0)}g');
    
    return UserProfile(
      sex: sex,
      ageYears: ageYears,
      heightCm: heightCm,
      weightKg: weightKg,
      goal: goal,
      activityLevel: activityLevel,
      trainingDaysPerWeek: trainingDaysPerWeek,
      equipment: equipment,
      dietType: dietType,
      mealCountPerDay: mealCountPerDay,
      exclusions: exclusions,
      injuries: injuries,
      energyUnit: energyUnit,
      weightUnit: weightUnit,
      bmr: bmr,
      tdee: tdee,
      calorieTarget: calorieTarget,
      proteinTargetG: proteinG,
      fatTargetG: fatG,
      carbsTargetG: carbsG,
    );
  }
  
  // Get workout split recommendation based on training days
  String getWorkoutSplit(int daysPerWeek) {
    if (daysPerWeek >= 5) {
      return 'ppl_5d'; // Push/Pull/Legs
    } else if (daysPerWeek >= 3) {
      return 'full_body_3d';
    } else {
      return 'full_body_3d'; // Default to 3-day even if they chose 2
    }
  }
  
  // Get meal distribution based on meal count
  List<double> getMealDistribution(String mealCount) {
    switch (mealCount) {
      case '2':
        return [0.45, 0.55];
      case '3':
        return [0.30, 0.40, 0.30];
      case '4':
        return [0.25, 0.30, 0.25, 0.20];
      case 'intermittent_fasting_16_8':
        return [0.40, 0.35, 0.25]; // Lunch, snack, dinner
      default:
        return [0.30, 0.40, 0.30];
    }
  }
  
  // Get workout schedule days
  List<String> getWorkoutScheduleDays(int daysPerWeek) {
    if (daysPerWeek >= 5) {
      return ['Mon', 'Tue', 'Thu', 'Fri', 'Sat'];
    } else if (daysPerWeek >= 3) {
      return ['Mon', 'Wed', 'Fri'];
    } else {
      return ['Mon', 'Thu'];
    }
  }
  
  // Get exercises filtered by equipment availability
  List<Map<String, dynamic>> getAvailableExercises(List<String> equipment) {
    // Return exercises that match the available equipment
    // This would be expanded to read from the spec in a full implementation
    return [
      {'name': 'Push-ups', 'equipment': 'none', 'muscle': 'Chest'},
      {'name': 'Squats', 'equipment': 'none', 'muscle': 'Quadriceps'},
      {'name': 'Dumbbell Press', 'equipment': 'dumbbells', 'muscle': 'Chest'},
      {'name': 'Barbell Squat', 'equipment': 'barbell_rack', 'muscle': 'Quadriceps'},
    ];
  }
  
  // Get rehab exercises for injuries
  List<Map<String, dynamic>> getRehabExercises(List<String> injuries) {
    final rehabMap = {
      'shoulder': [
        {'name': 'External Rotation (band)', 'sets': 3, 'reps': 15},
        {'name': 'YTWs (light DB)', 'sets': 3, 'reps': 12},
        {'name': 'Face Pull (light)', 'sets': 3, 'reps': 15},
      ],
      'back': [
        {'name': 'Bird Dog', 'sets': 3, 'reps': 12},
        {'name': 'McGill Curl-Up', 'sets': 3, 'reps': '10-15'},
        {'name': 'Hip Hinge PVC', 'sets': 3, 'reps': 12},
      ],
      'knee': [
        {'name': 'Step-up (low box)', 'sets': 3, 'reps': 10},
        {'name': 'Spanish Squat (band)', 'sets': 3, 'reps': 12},
        {'name': 'Hamstring Curl (band)', 'sets': 3, 'reps': 12},
      ],
    };
    
    final exercises = <Map<String, dynamic>>[];
    for (final injury in injuries) {
      if (injury != 'none' && rehabMap.containsKey(injury)) {
        exercises.addAll(rehabMap[injury]!);
      }
    }
    return exercises;
  }
  
  // Get food suggestions based on diet type
  List<String> getFoodSuggestions(String dietType, List<String> exclusions) {
    final omnivoreProteins = ['Chicken Breast', 'Turkey', 'Eggs', 'Greek Yogurt', 'Salmon', 'Tuna'];
    final carnivoreProteins = ['Ribeye Steak', 'Ground Beef', 'Eggs', 'Salmon', 'Beef Liver'];
    final herbivoreProteins = ['Firm Tofu', 'Tempeh', 'Lentils', 'Chickpeas', 'Black Beans'];
    
    final carbs = ['Rice', 'Oats', 'Pasta', 'Bread', 'Potato', 'Sweet Potato', 'Quinoa'];
    final fats = ['Olive Oil', 'Avocado', 'Almonds', 'Peanut Butter', 'Tahini'];
    final veggies = ['Broccoli', 'Spinach', 'Mixed Veg', 'Tomato', 'Cucumber'];
    
    List<String> foods = [];
    
    // Add proteins based on diet type
    switch (dietType) {
      case 'omnivore':
        foods.addAll(omnivoreProteins);
        break;
      case 'carnivore':
        foods.addAll(carnivoreProteins);
        break;
      case 'herbivore':
        foods.addAll(herbivoreProteins);
        break;
    }
    
    // Add carbs and fats (except for strict carnivore)
    if (dietType != 'carnivore') {
      foods.addAll(carbs);
      foods.addAll(fats);
      foods.addAll(veggies);
    } else {
      // Carnivore gets limited options
      foods.addAll(['Butter', 'Ghee']);
    }
    
    // Filter by exclusions
    foods.removeWhere((food) {
      if (exclusions.contains('dairy') && ['Greek Yogurt', 'Milk', 'Butter', 'Ghee'].contains(food)) {
        return true;
      }
      if (exclusions.contains('gluten') && ['Bread', 'Pasta', 'Oats'].contains(food)) {
        return true;
      }
      if (exclusions.contains('nuts') && ['Almonds', 'Peanut Butter'].contains(food)) {
        return true;
      }
      if (exclusions.contains('eggs') && food == 'Eggs') {
        return true;
      }
      if (exclusions.contains('soy') && ['Tofu', 'Tempeh'].contains(food)) {
        return true;
      }
      return false;
    });
    
    return foods;
  }
}

