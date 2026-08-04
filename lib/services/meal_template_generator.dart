import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/db/drift_database.dart';
import 'user_profile_service.dart';

class MealTemplateGenerator {
  final AppDatabase _database;
  final UserProfile _profile;
  final _uuid = const Uuid();

  MealTemplateGenerator(this._database, this._profile);

  Future<void> generateTemplates() async {
    debugPrint('[MEAL-GEN] 🍽️ Generating meal templates for ${_profile.dietType} diet');
    
    // Generate food items based on diet type
    await _generateFoods();
    
    // Generate meal templates based on diet and meal count
    await _generateMealTemplates();
    
    debugPrint('[MEAL-GEN] ✅ Meal templates generated successfully');
  }

  Future<void> _generateFoods() async {
    // Check if foods already exist (beyond starter foods)
    final existing = await _database.getAllFoods();
    if (existing.length > 10) {
      debugPrint('[MEAL-GEN] Foods already exist, skipping generation');
      return;
    }

    final foods = <FoodItemData>[];
    final now = DateTime.now();

    // Generate based on diet type
    if (_profile.dietType == 'omnivore') {
      foods.addAll(_getOmnivoreFoods(now));
    } else if (_profile.dietType == 'carnivore') {
      foods.addAll(_getCarnivoreFoods(now));
    } else if (_profile.dietType == 'herbivore') {
      foods.addAll(_getHerbivoreFoods(now));
    }

    // Filter by exclusions
    final filteredFoods = foods.where((food) {
      if (_profile.exclusions.contains('dairy') && 
          ['Greek Yogurt', 'Cottage Cheese', 'Milk', 'Butter'].contains(food.name)) {
        return false;
      }
      if (_profile.exclusions.contains('eggs') && food.name == 'Eggs') {
        return false;
      }
      if (_profile.exclusions.contains('gluten') && 
          ['Bread', 'Pasta', 'Oats'].contains(food.name)) {
        return false;
      }
      if (_profile.exclusions.contains('nuts') && 
          ['Almonds', 'Peanut Butter', 'Cashews'].contains(food.name)) {
        return false;
      }
      if (_profile.exclusions.contains('soy') && 
          ['Tofu', 'Tempeh', 'Soy Milk'].contains(food.name)) {
        return false;
      }
      return true;
    }).toList();

    // Insert foods
    for (final food in filteredFoods) {
      await _database.insertFood(food);
    }

    debugPrint('[MEAL-GEN] ✅ Generated ${filteredFoods.length} foods');
  }

  /// All foods VERIFIED with USDA database - normalized to PER 100G
  /// Source: USDA FoodData Central (fdc.nal.usda.gov)
  List<FoodItemData> _getOmnivoreFoods(DateTime now) {
    return [
      // PROTEINS - VERIFIED USDA DATA
      // Chicken breast, raw: 165kcal, 31g protein per 100g
      _createFood('Chicken Breast', '100g', 165, 31, 0, 3.6, now),
      // Turkey breast, raw: 135kcal, 30g protein per 100g
      _createFood('Turkey', '100g', 135, 30, 0, 1.0, now),
      // Eggs, whole, raw: 143kcal, 12.6g protein, 0.72g carbs, 9.51g fat per 100g
      _createFood('Eggs', '100g', 143, 12.6, 0.72, 9.51, now),
      // Yogurt, Greek, nonfat: 59kcal, 10.19g protein, 3.6g carbs, 0.39g fat per 100g
      _createFood('Greek Yogurt', '100g', 59, 10.19, 3.6, 0.39, now),
      // Salmon, Atlantic, raw: 208kcal, 20.42g protein, 0g carbs, 13.42g fat per 100g
      _createFood('Salmon', '100g', 208, 20.42, 0, 13.42, now),
      // Tuna, yellowfin, raw: 108kcal, 23.38g protein, 0g carbs, 0.95g fat per 100g
      _createFood('Tuna', '100g', 108, 23.38, 0, 0.95, now),
      // Cottage cheese, lowfat: 82kcal, 11g protein, 4.3g carbs, 1.4g fat per 100g
      _createFood('Cottage Cheese', '100g', 82, 11, 4.3, 1.4, now),
      
      // CARBS - VERIFIED USDA DATA
      // Rice, white, cooked: 130kcal, 2.69g protein, 28.17g carbs, 0.28g fat per 100g
      _createFood('Rice', '100g', 130, 2.69, 28.17, 0.28, now),
      // Oats, dry: 389kcal, 16.89g protein, 66.27g carbs, 6.9g fat per 100g
      _createFood('Oats', '100g', 389, 16.89, 66.27, 6.9, now),
      // Pasta, cooked: 131kcal, 5.8g protein, 25.1g carbs, 1.1g fat per 100g
      _createFood('Pasta', '100g', 131, 5.8, 25.1, 1.1, now),
      // Bread, whole wheat: 247kcal, 13g protein, 41g carbs, 3.4g fat per 100g
      _createFood('Bread', '100g', 247, 13, 41, 3.4, now),
      // Potato, baked: 93kcal, 2.5g protein, 21g carbs, 0.13g fat per 100g
      _createFood('Potato', '100g', 93, 2.5, 21, 0.13, now),
      // Sweet potato, baked: 90kcal, 2g protein, 20.7g carbs, 0.15g fat per 100g
      _createFood('Sweet Potato', '100g', 90, 2, 20.7, 0.15, now),
      // Quinoa, cooked: 120kcal, 4.4g protein, 21.3g carbs, 1.92g fat per 100g
      _createFood('Quinoa', '100g', 120, 4.4, 21.3, 1.92, now),
      
      // FATS - VERIFIED USDA DATA
      // Olive oil: 884kcal, 0g protein, 0g carbs, 100g fat per 100g
      _createFood('Olive Oil', '100g', 884, 0, 0, 100, now),
      // Avocado, raw: 160kcal, 2g protein, 8.53g carbs, 14.66g fat per 100g
      _createFood('Avocado', '100g', 160, 2, 8.53, 14.66, now),
      // Almonds: 579kcal, 21.15g protein, 21.55g carbs, 49.93g fat per 100g
      _createFood('Almonds', '100g', 579, 21.15, 21.55, 49.93, now),
      // Peanut butter, smooth: 588kcal, 25g protein, 20g carbs, 50g fat per 100g
      _createFood('Peanut Butter', '100g', 588, 25, 20, 50, now),
      // Butter, salted: 717kcal, 0.85g protein, 0.06g carbs, 81.11g fat per 100g
      _createFood('Butter', '100g', 717, 0.85, 0.06, 81.11, now),
      // Tahini: 595kcal, 17g protein, 21g carbs, 54g fat per 100g
      _createFood('Tahini', '100g', 595, 17, 21, 54, now),
      
      // VEGETABLES/FRUITS - VERIFIED USDA DATA
      // Broccoli, raw: 34kcal, 2.82g protein, 6.64g carbs, 0.37g fat per 100g
      _createFood('Broccoli', '100g', 34, 2.82, 6.64, 0.37, now),
      // Spinach, raw: 23kcal, 2.86g protein, 3.63g carbs, 0.39g fat per 100g
      _createFood('Spinach', '100g', 23, 2.86, 3.63, 0.39, now),
      // Banana, raw: 89kcal, 1.09g protein, 22.84g carbs, 0.33g fat per 100g
      _createFood('Banana', '100g', 89, 1.09, 22.84, 0.33, now),
      // Strawberries, raw: 32kcal, 0.67g protein, 7.68g carbs, 0.3g fat per 100g
      _createFood('Berries', '100g', 32, 0.67, 7.68, 0.3, now),
      // Mixed vegetables, frozen: 65kcal, 3.6g protein, 12g carbs, 0.3g fat per 100g
      _createFood('Mixed Veg', '100g', 65, 3.6, 12, 0.3, now),
      // Tomato, raw: 18kcal, 0.88g protein, 3.89g carbs, 0.2g fat per 100g
      _createFood('Tomato', '100g', 18, 0.88, 3.89, 0.2, now),
      // Cucumber, raw: 15kcal, 0.65g protein, 3.63g carbs, 0.11g fat per 100g
      _createFood('Cucumber', '100g', 15, 0.65, 3.63, 0.11, now),
    ];
  }

  List<FoodItemData> _getCarnivoreFoods(DateTime now) {
    return [
      // CARNIVORE - VERIFIED USDA DATA
      // Beef, ribeye, raw: 291kcal, 24g protein, 0g carbs, 22g fat per 100g
      _createFood('Ribeye Steak', '100g', 291, 24, 0, 22, now),
      // Beef, ground, 80/20, raw: 254kcal, 17.2g protein, 0g carbs, 20g fat per 100g
      _createFood('Ground Beef 80/20', '100g', 254, 17.2, 0, 20, now),
      // Pork chop, raw: 231kcal, 24.8g protein, 0g carbs, 14g fat per 100g
      _createFood('Pork Chop', '100g', 231, 24.8, 0, 14, now),
      // Beef liver, raw: 135kcal, 20.4g protein, 3.9g carbs, 3.6g fat per 100g
      _createFood('Beef Liver', '100g', 135, 20.4, 3.9, 3.6, now),
      // Bacon, cooked: 541kcal, 37.04g protein, 1.43g carbs, 41.78g fat per 100g
      _createFood('Bacon', '100g', 541, 37.04, 1.43, 41.78, now),
      // Salmon (same as omnivore)
      _createFood('Salmon', '100g', 208, 20.42, 0, 13.42, now),
      // Eggs (same as omnivore)
      _createFood('Eggs', '100g', 143, 12.6, 0.72, 9.51, now),
      // Butter (same as omnivore)
      _createFood('Butter', '100g', 717, 0.85, 0.06, 81.11, now),
      // Ghee: 876kcal, 0.28g protein, 0g carbs, 99.48g fat per 100g
      _createFood('Ghee', '100g', 876, 0.28, 0, 99.48, now),
    ];
  }

  List<FoodItemData> _getHerbivoreFoods(DateTime now) {
    return [
      // PLANT-BASED PROTEINS - VERIFIED USDA DATA
      // Tofu, firm: 145kcal, 15.78g protein, 4.27g carbs, 8.72g fat per 100g
      _createFood('Firm Tofu', '100g', 145, 15.78, 4.27, 8.72, now),
      // Tempeh: 193kcal, 20.29g protein, 7.64g carbs, 10.8g fat per 100g
      _createFood('Tempeh', '100g', 193, 20.29, 7.64, 10.8, now),
      // Lentils, cooked: 116kcal, 9.02g protein, 20.13g carbs, 0.38g fat per 100g
      _createFood('Lentils', '100g', 116, 9.02, 20.13, 0.38, now),
      // Chickpeas, cooked: 164kcal, 8.86g protein, 27.42g carbs, 2.59g fat per 100g
      _createFood('Chickpeas', '100g', 164, 8.86, 27.42, 2.59, now),
      // Black beans, cooked: 132kcal, 8.86g protein, 23.71g carbs, 0.54g fat per 100g
      _createFood('Black Beans', '100g', 132, 8.86, 23.71, 0.54, now),
      // Edamame: 122kcal, 11.22g protein, 9.94g carbs, 5.2g fat per 100g
      _createFood('Edamame', '100g', 122, 11.22, 9.94, 5.2, now),
      
      // CARBS (same as omnivore)
      _createFood('Rice', '100g', 130, 2.69, 28.17, 0.28, now),
      // Rice noodles, cooked: 109kcal, 1.79g protein, 24.9g carbs, 0.23g fat per 100g
      _createFood('Rice Noodles', '100g', 109, 1.79, 24.9, 0.23, now),
      _createFood('Quinoa', '100g', 120, 4.4, 21.3, 1.92, now),
      
      // FATS (same as omnivore)
      _createFood('Olive Oil', '100g', 884, 0, 0, 100, now),
      _createFood('Avocado', '100g', 160, 2, 8.53, 14.66, now),
      _createFood('Tahini', '100g', 595, 17, 21, 54, now),
      // Cashews: 553kcal, 18.22g protein, 30.19g carbs, 43.85g fat per 100g
      _createFood('Cashews', '100g', 553, 18.22, 30.19, 43.85, now),
      
      // VEGGIES (same as omnivore)
      _createFood('Mixed Veg', '100g', 65, 3.6, 12, 0.3, now),
      _createFood('Spinach', '100g', 23, 2.86, 3.63, 0.39, now),
      // Kale, raw: 49kcal, 4.28g protein, 8.75g carbs, 0.93g fat per 100g
      _createFood('Kale', '100g', 49, 4.28, 8.75, 0.93, now),
      // Brussels sprouts, raw: 43kcal, 3.38g protein, 8.95g carbs, 0.3g fat per 100g
      _createFood('Brussels Sprouts', '100g', 43, 3.38, 8.95, 0.3, now),
    ];
  }

  FoodItemData _createFood(String name, String unit, double kcal, double protein, double carbs, double fat, DateTime now) {
    return FoodItemData(
      id: _uuid.v4(),
      name: name,
      brand: null,
      unit: unit,
      kcalPerUnit: kcal,
      proteinPerUnit: protein,
      carbsPerUnit: carbs,
      fatPerUnit: fat,
      isStarter: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _generateMealTemplates() async {
    final foods = await _database.getAllFoods();
    if (foods.isEmpty) {
      debugPrint('[MEAL-GEN] ⚠️ No foods available, skipping template generation');
      return;
    }
    
    // Get meal distribution for the selected meal count
    final distribution = _getMealDistribution();
    debugPrint('[MEAL-GEN] Meal distribution for ${_profile.mealCountPerDay}: ${distribution.map((d) => '${(d * 100).toInt()}%').join(', ')}');
    
    // Create templates based on diet type
    final templates = _getTemplateSuggestions();
    
    for (final template in templates) {
      final templateId = _uuid.v4();
      await _database.insertMealTemplate(
        MealTemplateData(
          id: templateId,
          name: template['name'] as String,
          description: template['description'] as String?,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Add food items to template
      final items = template['items'] as List<Map<String, dynamic>>;
      for (final item in items) {
        final foodName = item['food'] as String;
        final amount = item['amount'] as double;
        
        // Find food by name - exact match required
        final foodMatch = foods.where((f) => f.name == foodName).toList();
        
        if (foodMatch.isEmpty) {
          debugPrint('[MEAL-GEN] ⚠️ WARNING: Food "$foodName" not found in database! Skipping item.');
          continue; // Skip this item instead of using wrong food
        }
        
        final food = foodMatch.first;
        debugPrint('[MEAL-GEN]   Adding ${amount.toStringAsFixed(1)}g ${food.name}');

        await _database.insertMealTemplateItem(
          MealTemplateItemData(
            id: _uuid.v4(),
            templateId: templateId,
            foodId: food.id,
            amount: amount,
          ),
        );
      }
    }

    debugPrint('[MEAL-GEN] ✅ Generated ${templates.length} meal templates');
  }

  List<double> _getMealDistribution() {
    switch (_profile.mealCountPerDay) {
      case '2':
        return [0.45, 0.55];
      case '3':
        return [0.30, 0.40, 0.30];
      case '4':
        return [0.25, 0.30, 0.25, 0.20];
      case 'intermittent_fasting_16_8':
        return [0.40, 0.35, 0.25];
      default:
        return [0.30, 0.40, 0.30];
    }
  }

  List<Map<String, dynamic>> _getTemplateSuggestions() {
    // Get meal distribution to calculate average meal size
    final distribution = _getMealDistribution();
    final avgMealFraction = distribution.reduce((a, b) => a + b) / distribution.length;
    
    // Scale templates to average meal size (typically 30-33% of daily intake)
    final mealProteinTarget = _profile.proteinTargetG * avgMealFraction;
    
    debugPrint('[MEAL-GEN] 📊 Scaling templates: ${(avgMealFraction * 100).toInt()}% of daily targets');
    debugPrint('[MEAL-GEN] 📊 Target protein per template: ${mealProteinTarget.toStringAsFixed(1)}g');
    
    if (_profile.dietType == 'omnivore') {
      return [
        {
          'name': 'Chicken Rice Bowl',
          'description': 'High protein balanced meal',
          'items': [
            {'food': 'Chicken Breast', 'amount': (mealProteinTarget / 0.31).roundToDouble()}, // Target protein
            {'food': 'White Rice', 'amount': 150.0},
            {'food': 'Broccoli', 'amount': 100.0},
            {'food': 'Olive Oil', 'amount': 8.0},
          ],
        },
        {
          'name': 'Salmon & Quinoa',
          'description': 'Omega-3 rich meal',
          'items': [
            {'food': 'Salmon', 'amount': (mealProteinTarget / 0.2042).roundToDouble()},
            {'food': 'Quinoa', 'amount': 120.0},
            {'food': 'Spinach', 'amount': 80.0},
            {'food': 'Olive Oil', 'amount': 8.0},
          ],
        },
        {
          'name': 'Eggs & Oats',
          'description': 'Quick protein breakfast',
          'items': [
            {'food': 'Eggs', 'amount': 150.0}, // ~3 eggs
            {'food': 'Oats', 'amount': 50.0},
            {'food': 'Greek Yogurt', 'amount': 150.0},
            {'food': 'Banana', 'amount': 120.0},
          ],
        },
      ];
    } else if (_profile.dietType == 'carnivore') {
      return [
        {
          'name': 'Beef & Eggs',
          'description': 'High protein, zero carb',
          'items': [
            {'food': 'Ground Beef', 'amount': 200.0},
            {'food': 'Eggs', 'amount': 100.0},
            {'food': 'Butter', 'amount': 10.0},
          ],
        },
        {
          'name': 'Salmon & Shrimp',
          'description': 'Nutrient-dense carnivore',
          'items': [
            {'food': 'Salmon', 'amount': 150.0},
            {'food': 'Shrimp', 'amount': 60.0},
          ],
        },
      ];
    } else {
      // Herbivore
      return [
        {
          'name': 'Tofu Stir Fry',
          'description': 'Plant-based protein bowl',
          'items': [
            {'food': 'Tofu', 'amount': 200.0},
            {'food': 'Brown Rice', 'amount': 100.0},
            {'food': 'Bell Pepper', 'amount': 150.0},
            {'food': 'Peanut Butter', 'amount': 15.0},
          ],
        },
        {
          'name': 'Lentils & Rice',
          'description': 'High fiber and protein',
          'items': [
            {'food': 'Lentils', 'amount': 150.0},
            {'food': 'White Rice', 'amount': 130.0},
            {'food': 'Spinach', 'amount': 100.0},
            {'food': 'Olive Oil', 'amount': 8.0},
          ],
        },
        {
          'name': 'Chickpea Buddha Bowl',
          'description': 'Balanced plant meal',
          'items': [
            {'food': 'Chickpeas', 'amount': 150.0},
            {'food': 'Quinoa', 'amount': 100.0},
            {'food': 'Avocado', 'amount': 50.0},
            {'food': 'Kale', 'amount': 80.0},
          ],
        },
      ];
    }
  }
}
