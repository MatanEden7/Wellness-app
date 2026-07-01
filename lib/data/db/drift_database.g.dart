// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// Stub data classes for compilation
class FoodItemData {
  final String id;
  final String name;
  final String? brand;
  final String unit;
  final double kcalPerUnit;
  final double proteinPerUnit;
  final double carbsPerUnit;
  final double fatPerUnit;
  final bool isStarter;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const FoodItemData({
    required this.id,
    required this.name,
    this.brand,
    required this.unit,
    required this.kcalPerUnit,
    required this.proteinPerUnit,
    required this.carbsPerUnit,
    required this.fatPerUnit,
    required this.isStarter,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodItemData.fromJson(Map<String, dynamic> json) {
    return FoodItemData(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      unit: json['unit'] as String,
      kcalPerUnit: (json['kcalPerUnit'] as num).toDouble(),
      proteinPerUnit: (json['proteinPerUnit'] as num).toDouble(),
      carbsPerUnit: (json['carbsPerUnit'] as num).toDouble(),
      fatPerUnit: (json['fatPerUnit'] as num).toDouble(),
      isStarter: json['isStarter'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'unit': unit,
      'kcalPerUnit': kcalPerUnit,
      'proteinPerUnit': proteinPerUnit,
      'carbsPerUnit': carbsPerUnit,
      'fatPerUnit': fatPerUnit,
      'isStarter': isStarter,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class MealData {
  final String id;
  final int date;
  final String name;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const MealData({
    required this.id,
    required this.date,
    required this.name,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MealData.fromJson(Map<String, dynamic> json) {
    return MealData(
      id: json['id'] as String,
      date: json['date'] as int,
      name: json['name'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'name': name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class MealItemData {
  final String id;
  final String mealId;
  final String foodId;
  final double amount;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  
  const MealItemData({
    required this.id,
    required this.mealId,
    required this.foodId,
    required this.amount,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory MealItemData.fromJson(Map<String, dynamic> json) {
    return MealItemData(
      id: json['id'] as String,
      mealId: json['mealId'] as String,
      foodId: json['foodId'] as String,
      amount: (json['amount'] as num).toDouble(),
      kcal: (json['kcal'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealId': mealId,
      'foodId': foodId,
      'amount': amount,
      'kcal': kcal,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class ExerciseData {
  final String id;
  final String name;
  final String? primaryMuscle;
  final String unit;
  final String? notes;
  
  const ExerciseData({
    required this.id,
    required this.name,
    this.primaryMuscle,
    required this.unit,
    this.notes,
  });

  factory ExerciseData.fromJson(Map<String, dynamic> json) {
    return ExerciseData(
      id: json['id'] as String,
      name: json['name'] as String,
      primaryMuscle: json['primaryMuscle'] as String?,
      unit: json['unit'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryMuscle': primaryMuscle,
      'unit': unit,
      'notes': notes,
    };
  }
}

class WorkoutTemplateData {
  final String id;
  final String name;
  final String? notes;
  
  const WorkoutTemplateData({
    required this.id,
    required this.name,
    this.notes,
  });

  factory WorkoutTemplateData.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplateData(
      id: json['id'] as String,
      name: json['name'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
    };
  }
}

class TemplateExerciseData {
  final String id;
  final String templateId;
  final String exerciseId;
  final int orderIndex;
  final int defaultSets;
  final int? defaultReps;
  final double? defaultWeight;
  
  const TemplateExerciseData({
    required this.id,
    required this.templateId,
    required this.exerciseId,
    required this.orderIndex,
    required this.defaultSets,
    this.defaultReps,
    this.defaultWeight,
  });

  factory TemplateExerciseData.fromJson(Map<String, dynamic> json) {
    return TemplateExerciseData(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      exerciseId: json['exerciseId'] as String,
      orderIndex: json['orderIndex'] as int,
      defaultSets: json['defaultSets'] as int,
      defaultReps: json['defaultReps'] as int?,
      defaultWeight: (json['defaultWeight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'exerciseId': exerciseId,
      'orderIndex': orderIndex,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'defaultWeight': defaultWeight,
    };
  }
}

class WorkoutSessionData {
  final String id;
  final String? templateId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? note;
  
  const WorkoutSessionData({
    required this.id,
    this.templateId,
    required this.startedAt,
    this.endedAt,
    this.note,
  });

  factory WorkoutSessionData.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionData(
      id: json['id'] as String,
      templateId: json['templateId'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'note': note,
    };
  }
}

class SetEntryData {
  final String id;
  final String sessionId;
  final String exerciseId;
  final int orderIndex;
  final int reps;
  final double? weight;
  final int? restSeconds;
  
  const SetEntryData({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.orderIndex,
    required this.reps,
    this.weight,
    this.restSeconds,
  });

  factory SetEntryData.fromJson(Map<String, dynamic> json) {
    return SetEntryData(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      exerciseId: json['exerciseId'] as String,
      orderIndex: json['orderIndex'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num?)?.toDouble(),
      restSeconds: json['restSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'exerciseId': exerciseId,
      'orderIndex': orderIndex,
      'reps': reps,
      'weight': weight,
      'restSeconds': restSeconds,
    };
  }
}

class SleepEntryData {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? quality;
  final String? note;
  
  const SleepEntryData({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.quality,
    this.note,
  });

  factory SleepEntryData.fromJson(Map<String, dynamic> json) {
    return SleepEntryData(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
      quality: json['quality'] as int?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'quality': quality,
      'note': note,
    };
  }
}