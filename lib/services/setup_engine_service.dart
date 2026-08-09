import 'package:flutter/foundation.dart';
import 'user_profile_service.dart';

/// The daily numbers the app tracks against, and the intermediates they came
/// from. Produced as a set by [SetupEngineService.calculateTargets] because
/// the four macro numbers are not independent -- carbs are whatever calories
/// protein and fat leave behind, so computing them separately lets them drift
/// out of agreement with the calorie target.
class NutritionTargets {
  const NutritionTargets({
    required this.bmr,
    required this.tdee,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double bmr;
  final double tdee;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// What the macro grams actually add up to. Within a few kcal of [calories]
  /// by construction (gram rounding is the only gap).
  double get kcalFromMacros => proteinG * 4 + carbsG * 4 + fatG * 9;
}

class SetupEngineService {
  /// No-op, kept so callers need not change.
  ///
  /// This used to parse assets/data/setup_engine_spec.yaml into a field that
  /// nothing ever read -- every formula below is hardcoded in Dart. Loading
  /// it implied the spec drove the engine, which it did not.
  Future<void> initialize() async {}

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

  /// Lowest daily intake the app will ever prescribe, by sex. Standard
  /// clinical floors for unsupervised dieting (1200 / 1500 kcal).
  static double minimumSafeCalories(String sex) => sex == 'male' ? 1500 : 1200;

  /// Daily calorie target for [goal].
  ///
  /// The deficit/surplus is a **fraction of TDEE**, not the flat -400/+250 this
  /// used to apply. A flat 400 kcal cut is ~13% for a 3000 kcal athlete and
  /// ~30% for a 1350 kcal sedentary user -- the same number meaning two very
  /// different things. 20% down / 10% up keeps the rate of change proportional
  /// to body size, and the result is floored at [minimumSafeCalories] so a
  /// small sedentary profile can no longer be handed a ~950 kcal target.
  double calculateCalorieTarget(double tdee, String goal, {String sex = 'male'}) {
    final double raw;
    switch (goal) {
      case 'fat_loss':
        // Capped in absolute terms too: past ~750 kcal/day the deficit costs
        // lean mass rather than fat, however big the person is.
        raw = tdee - (tdee * 0.20).clamp(0, 750);
      case 'muscle_gain':
        // A surplus bigger than this is mostly fat gain, and below ~150 kcal
        // it is inside the noise of daily intake.
        raw = tdee + (tdee * 0.10).clamp(150, 400);
      case 'maintenance':
      case 'mobility_rehab':
        raw = tdee;
      default:
        raw = tdee;
    }
    // The floor only ever raises a target, and never above TDEE itself -- a
    // profile whose maintenance is genuinely under 1200 kcal should not be
    // told to eat at a surplus in the name of safety.
    final floor = minimumSafeCalories(sex);
    final effectiveFloor = floor < tdee ? floor : tdee;
    return raw < effectiveFloor ? effectiveFloor : raw;
  }

  /// Grams of protein per kg of [referenceWeight], by goal.
  static double proteinPerKgForGoal(String goal) => const {
        'fat_loss': 2.2,
        'muscle_gain': 2.0,
        'maintenance': 1.8,
        'mobility_rehab': 1.8,
      }[goal] ??
      1.8;

  /// The weight the protein target is scaled against.
  ///
  /// Protein needs track lean mass, not scale weight. Applying 2.2 g/kg to
  /// total weight at a high BMI prescribed absurd amounts -- 264 g/day for a
  /// 120 kg user, over half their calorie target. Above BMI 27.5 only a
  /// quarter of the excess weight counts, the usual adjusted-body-weight
  /// approach.
  static double proteinReferenceWeight(double weightKg, int heightCm) {
    if (heightCm <= 0) return weightKg;
    final heightM = heightCm / 100;
    final upperHealthy = 27.5 * heightM * heightM;
    if (weightKg <= upperHealthy) return weightKg;
    return upperHealthy + 0.25 * (weightKg - upperHealthy);
  }

  /// Daily protein target in grams.
  ///
  /// Capped at 40% of the calorie target when one is given: on an aggressive
  /// cut the g/kg ratio alone can claim so much of the budget that nothing
  /// sane is left for carbs and fat.
  double calculateProteinTarget(
    double weightKg,
    String goal, {
    int heightCm = 0,
    double? calorieTarget,
  }) {
    final grams =
        proteinReferenceWeight(weightKg, heightCm) * proteinPerKgForGoal(goal);
    if (calorieTarget == null) return grams;
    final cap = calorieTarget * 0.40 / 4;
    return grams > cap ? cap : grams;
  }

  /// Share of calories that comes from fat, by goal.
  static double fatFractionForGoal(String goal) => const {
        'fat_loss': 0.28,
        'muscle_gain': 0.25,
        'maintenance': 0.28,
        'mobility_rehab': 0.30,
      }[goal] ??
      0.28;

  /// Absolute minimum fat, for hormone production and fat-soluble vitamins.
  static double minimumFatGrams(double weightKg) => weightKg * 0.6;

  /// Daily fat target in grams: a **share of the calorie budget**, floored at
  /// the essential-fat minimum.
  ///
  /// This used to return the 0.6 g/kg minimum and nothing else, whatever the
  /// calorie target was, so fat came out at 13-16% of intake and every calorie
  /// it did not claim was dumped into carbs. An 80 kg maintenance profile got
  /// 48 g of fat and ~370 g of carbs -- a plan nobody would write.
  double calculateFatTarget(double weightKg, double calorieTarget, String goal) {
    final fromCalories = calorieTarget * fatFractionForGoal(goal) / 9;
    final floor = minimumFatGrams(weightKg);
    return fromCalories < floor ? floor : fromCalories;
  }

  // Calculate carbs target in grams (fills remaining calories)
  double calculateCarbsTarget(double calorieTarget, double proteinG, double fatG) {
    final caloriesFromProtein = proteinG * 4;
    final caloriesFromFat = fatG * 9;
    final remainingCalories = calorieTarget - caloriesFromProtein - caloriesFromFat;
    final carbsG = remainingCalories / 4;
    return carbsG > 0 ? carbsG : 0;
  }

  /// The whole target set, solved together so the four numbers agree.
  ///
  /// Order matters: calories first, then protein (the hardest constraint),
  /// then fat as a share of what is left, then carbs to fill the remainder.
  /// If protein and fat between them overrun the budget, fat is walked back to
  /// its floor and protein after it, rather than silently clamping carbs to 0
  /// and leaving a target set that does not add up to its own calorie number.
  NutritionTargets calculateTargets({
    required String sex,
    required double weightKg,
    required int heightCm,
    required int ageYears,
    required String goal,
    required String activityLevel,
  }) {
    final bmr = calculateBMR(
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
    );
    final tdee = calculateTDEE(bmr, activityLevel);
    final calories = calculateCalorieTarget(tdee, goal, sex: sex);

    var protein = calculateProteinTarget(
      weightKg,
      goal,
      heightCm: heightCm,
      calorieTarget: calories,
    );
    var fat = calculateFatTarget(weightKg, calories, goal);

    // Reconcile: leave room for at least a minimal carb allowance.
    const minCarbsG = 50.0;
    final fatFloor = minimumFatGrams(weightKg);
    final proteinFloor = proteinReferenceWeight(weightKg, heightCm) * 1.6;
    var budget = calories - minCarbsG * 4;
    if (protein * 4 + fat * 9 > budget) {
      fat = ((budget - protein * 4) / 9).clamp(fatFloor, fat);
    }
    if (protein * 4 + fat * 9 > budget) {
      protein = ((budget - fat * 9) / 4).clamp(proteinFloor, protein);
    }

    // Round to numbers a person can act on, then let carbs absorb the rounding
    // so the grams still reconcile with the calorie target.
    final roundedCalories = (calories / 10).round() * 10.0;
    final roundedProtein = protein.roundToDouble();
    final roundedFat = fat.roundToDouble();
    final carbs = calculateCarbsTarget(
      roundedCalories,
      roundedProtein,
      roundedFat,
    ).roundToDouble();

    return NutritionTargets(
      bmr: bmr,
      tdee: tdee,
      calories: roundedCalories,
      proteinG: roundedProtein,
      carbsG: carbs,
      fatG: roundedFat,
    );
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
    String trainingExperience = 'beginner',
    required List<String> equipment,
    required String dietType,
    required String mealCountPerDay,
    required List<String> exclusions,
    required List<String> injuries,
    String energyUnit = 'kcal',
    String weightUnit = 'g',
  }) {
    final targets = calculateTargets(
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
      goal: goal,
      activityLevel: activityLevel,
    );

    debugPrint('[SETUP-ENGINE] 📊 Calculated targets:');
    debugPrint('  BMR: ${targets.bmr.toStringAsFixed(0)} kcal');
    debugPrint('  TDEE: ${targets.tdee.toStringAsFixed(0)} kcal');
    debugPrint('  Target: ${targets.calories.toStringAsFixed(0)} kcal');
    debugPrint('  Protein: ${targets.proteinG.toStringAsFixed(0)}g');
    debugPrint('  Fat: ${targets.fatG.toStringAsFixed(0)}g');
    debugPrint('  Carbs: ${targets.carbsG.toStringAsFixed(0)}g');

    return UserProfile(
      sex: sex,
      ageYears: ageYears,
      heightCm: heightCm,
      weightKg: weightKg,
      goal: goal,
      activityLevel: activityLevel,
      trainingDaysPerWeek: trainingDaysPerWeek,
      trainingExperience: trainingExperience,
      equipment: equipment,
      dietType: dietType,
      mealCountPerDay: mealCountPerDay,
      exclusions: exclusions,
      injuries: injuries,
      energyUnit: energyUnit,
      weightUnit: weightUnit,
      bmr: targets.bmr,
      tdee: targets.tdee,
      calorieTarget: targets.calories,
      proteinTargetG: targets.proteinG,
      fatTargetG: targets.fatG,
      carbsTargetG: targets.carbsG,
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
  
  // Rehab exercises used to be hardcoded here, as name strings with sets and
  // reps, covering three of the seven body parts. Nothing ever called it. The
  // real physiotherapy path is `rehabFor` on the exercise library, which
  // WorkoutTemplateGenerator filters by the user's equipment -- and which
  // covers all seven. Keeping a second, wronger answer next to it was an
  // invitation to wire up the wrong one.


  
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

