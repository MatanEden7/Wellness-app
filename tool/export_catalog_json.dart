@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/catalog/starter_foods.dart';
import 'package:wellness_app/data/catalog/starter_exercises.dart';

void main() {
  test('export starter foods to JSON', () {
    final foods = StarterFoodCatalog.all.map((f) => {
      'id': f.id,
      'name': f.name,
      'nameHe': f.nameHe,
      if (f.brand != null) 'brand': f.brand,
      'unit': f.unit,
      'kcal': f.kcal,
      'protein': f.protein,
      'carbs': f.carbs,
      'fat': f.fat,
      'category': f.category.name,
      if (f.tags.isNotEmpty) 'tags': f.tags.map((t) => t.name).toList()..sort(),
      if (f.israeli) 'israeli': true,
      if (f.containsAlcohol) 'containsAlcohol': true,
    }).toList();

    final json = const JsonEncoder.withIndent('  ').convert(foods);
    File('Packages/WellnessKit/Sources/WellnessCatalog/Resources/starter_foods.json')
        .writeAsStringSync(json);
    print('Exported ${foods.length} foods');
  });

  test('export starter exercises to JSON', () {
    final exercises = StarterExerciseLibrary.all.map((e) => {
      'id': e.id,
      'name': e.name,
      'nameHe': e.nameHe,
      'primaryMuscle': e.primaryMuscle,
      'primaryMuscleHe': e.primaryMuscleHe,
      'unit': e.unit,
      'notes': e.notes,
      'notesHe': e.notesHe,
      if (e.equipment.isNotEmpty) 'equipment': e.equipment.map((eq) => eq.name).toList()..sort(),
      if (e.contraindicatedFor.isNotEmpty) 'contraindicatedFor': e.contraindicatedFor.map((bp) => bp.name).toList()..sort(),
      if (e.rehabFor.isNotEmpty) 'rehabFor': e.rehabFor.map((bp) => bp.name).toList()..sort(),
      'pattern': e.pattern.name,
      'mechanic': e.mechanic.name,
      'loadClass': e.loadClass.name,
    }).toList();

    final json = const JsonEncoder.withIndent('  ').convert(exercises);
    File('Packages/WellnessKit/Sources/WellnessCatalog/Resources/starter_exercises.json')
        .writeAsStringSync(json);
    print('Exported ${exercises.length} exercises');
  });
}
