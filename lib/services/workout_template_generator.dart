import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/db/drift_database.dart';
import 'user_profile_service.dart';

class WorkoutTemplateGenerator {
  final AppDatabase _database;
  final UserProfile _profile;
  final _uuid = const Uuid();

  WorkoutTemplateGenerator(this._database, this._profile);

  Future<void> generateTemplates() async {
    debugPrint('[WORKOUT-GEN] 🏋️ Generating workout templates for ${_profile.trainingDaysPerWeek} days/week');
    
    // Generate exercises based on equipment
    await _generateExercises();
    
    // Generate templates based on training split
    final split = _getWorkoutSplit();
    if (split == 'full_body_3d') {
      await _generateFullBody3Day();
    } else if (split == 'ppl_5d') {
      await _generatePPL5Day();
    }
    
    // Generate mobility pack
    await _generateMobilityPack();
    
    // Generate rehab addons if user has injuries
    await _generateRehabAddons();
    
    debugPrint('[WORKOUT-GEN] ✅ Workout templates generated successfully');
  }

  String _getWorkoutSplit() {
    if (_profile.trainingDaysPerWeek >= 5) {
      return 'ppl_5d';
    } else {
      return 'full_body_3d';
    }
  }

  Future<void> _generateExercises() async {
    // Check if exercises already exist
    final existing = await _database.getAllExercises();
    if (existing.length > 2) {
      debugPrint('[WORKOUT-GEN] Exercises already exist, skipping generation');
      return;
    }

    final exercises = <ExerciseData>[];
    final hasDumbbells = _profile.equipment.contains('dumbbells');
    final hasBarbell = _profile.equipment.contains('barbell_rack');
    final hasMachines = _profile.equipment.contains('machines');
    final hasCable = _profile.equipment.contains('cable');
    final hasBands = _profile.equipment.contains('bands');
    final hasPullupBar = _profile.equipment.contains('pullup_bar');

    // Chest exercises
    exercises.add(_createExercise('Push-ups', 'Chest', 'Bodyweight chest exercise'));
    if (hasDumbbells) {
      exercises.add(_createExercise('Dumbbell Bench Press', 'Chest', 'Use dumbbells on bench'));
      exercises.add(_createExercise('Incline DB Press', 'Chest', 'Upper chest focus'));
    }
    if (hasBarbell) {
      exercises.add(_createExercise('Barbell Bench Press', 'Chest', 'Heavy compound press'));
    }
    if (hasCable) {
      exercises.add(_createExercise('Cable Fly', 'Chest', 'Chest isolation'));
    }

    // Back exercises
    if (hasPullupBar || hasBands) {
      exercises.add(_createExercise('Pull-ups', 'Back', 'Vertical pull'));
    }
    if (hasBarbell) {
      exercises.add(_createExercise('Barbell Row', 'Back', 'Horizontal pull'));
    }
    if (hasDumbbells) {
      exercises.add(_createExercise('One-Arm DB Row', 'Back', 'Unilateral back work'));
      exercises.add(_createExercise('Dumbbell Row', 'Back', 'Bilateral rowing'));
    }
    if (hasCable || hasMachines) {
      exercises.add(_createExercise('Lat Pulldown', 'Back', 'Machine vertical pull'));
      exercises.add(_createExercise('Seated Cable Row', 'Back', 'Machine horizontal pull'));
    }

    // Legs exercises
    exercises.add(_createExercise('Bodyweight Squats', 'Quadriceps', 'No equipment needed'));
    exercises.add(_createExercise('Lunges', 'Quadriceps', 'Bodyweight or weighted'));
    if (hasBarbell) {
      exercises.add(_createExercise('Barbell Squat', 'Quadriceps', 'Heavy compound'));
      exercises.add(_createExercise('Romanian Deadlift', 'Hamstrings', 'Hip hinge pattern'));
      exercises.add(_createExercise('Deadlift', 'Back', 'Full body compound'));
    }
    if (hasDumbbells) {
      exercises.add(_createExercise('Goblet Squat', 'Quadriceps', 'DB front squat'));
      exercises.add(_createExercise('Bulgarian Split Squat', 'Quadriceps', 'Single leg'));
      exercises.add(_createExercise('DB Romanian Deadlift', 'Hamstrings', 'Hip hinge'));
    }
    if (hasMachines) {
      exercises.add(_createExercise('Leg Press', 'Quadriceps', 'Machine squat'));
      exercises.add(_createExercise('Leg Curl', 'Hamstrings', 'Hamstring isolation'));
    }

    // Shoulder exercises
    if (hasDumbbells) {
      exercises.add(_createExercise('Dumbbell Shoulder Press', 'Shoulders', 'Overhead press'));
      exercises.add(_createExercise('Lateral Raise', 'Shoulders', 'Side delt isolation'));
    }
    if (hasBarbell) {
      exercises.add(_createExercise('Overhead Press', 'Shoulders', 'Barbell OHP'));
    }
    if (hasCable || hasBands) {
      exercises.add(_createExercise('Face Pull', 'Shoulders', 'Rear delt and upper back'));
    }

    // Arms exercises
    if (hasDumbbells) {
      exercises.add(_createExercise('Dumbbell Curl', 'Biceps', 'Bicep isolation'));
      exercises.add(_createExercise('Hammer Curl', 'Biceps', 'Brachialis focus'));
      exercises.add(_createExercise('Triceps Kickback', 'Triceps', 'Tricep isolation'));
    }
    if (hasCable || hasMachines) {
      exercises.add(_createExercise('Cable Pushdown', 'Triceps', 'Tricep extension'));
      exercises.add(_createExercise('Cable Curl', 'Biceps', 'Constant tension curls'));
    }

    // Core exercises
    exercises.add(_createExercise('Plank', 'Core', 'Core stabilization'));
    exercises.add(_createExercise('Side Plank', 'Core', 'Obliques'));
    exercises.add(_createExercise('Dead Bug', 'Core', 'Anti-extension'));
    exercises.add(_createExercise('Bird Dog', 'Core', 'Coordination and stability'));
    if (hasPullupBar) {
      exercises.add(_createExercise('Hanging Knee Raise', 'Core', 'Lower abs'));
    }

    // Insert exercises
    for (final exercise in exercises) {
      await _database.insertExercise(exercise);
    }

    debugPrint('[WORKOUT-GEN] ✅ Generated ${exercises.length} exercises');
  }

  ExerciseData _createExercise(String name, String muscle, String notes) {
    return ExerciseData(
      id: _uuid.v4(),
      name: name,
      primaryMuscle: muscle,
      unit: 'reps',
      notes: notes,
    );
  }

  Future<void> _generateFullBody3Day() async {
    final exercises = await _database.getAllExercises();
    
    // Create 3 full body templates
    final templates = [
      'Full Body A',
      'Full Body B',
      'Full Body C',
    ];

    for (final templateName in templates) {
      final templateId = _uuid.v4();
      await _database.insertWorkoutTemplate(
        WorkoutTemplateData(
          id: templateId,
          name: templateName,
          notes: 'Generated by setup wizard',
        ),
      );

      // Add exercises to template
      final selectedExercises = _selectExercisesForFullBody(exercises, templateName);
      for (var i = 0; i < selectedExercises.length; i++) {
        await _database.insertTemplateExercise(
          TemplateExerciseData(
            id: _uuid.v4(),
            templateId: templateId,
            exerciseId: selectedExercises[i].id,
            orderIndex: i,
            defaultSets: 3,
            defaultReps: 10,
            defaultWeight: null,
          ),
        );
      }
    }

    debugPrint('[WORKOUT-GEN] ✅ Generated 3-day full body split');
  }

  List<ExerciseData> _selectExercisesForFullBody(List<ExerciseData> allExercises, String day) {
    final selected = <ExerciseData>[];

    // Each day hits major muscle groups
    // Day A: Push focus
    selected.addAll(_findExercises(allExercises, ['Chest'], 2));
    selected.addAll(_findExercises(allExercises, ['Quadriceps'], 1));
    selected.addAll(_findExercises(allExercises, ['Shoulders'], 1));
    selected.addAll(_findExercises(allExercises, ['Triceps'], 1));
    selected.addAll(_findExercises(allExercises, ['Core'], 1));

    return selected.take(6).toList();
  }

  List<ExerciseData> _findExercises(List<ExerciseData> allExercises, List<String> muscles, int count) {
    final found = <ExerciseData>[];
    for (final muscle in muscles) {
      found.addAll(
        allExercises.where((e) => e.primaryMuscle == muscle).take(count),
      );
    }
    return found;
  }

  Future<void> _generatePPL5Day() async {
    final exercises = await _database.getAllExercises();
    
    // Create PPL templates
    final templates = [
      ('Push A', ['Chest', 'Shoulders', 'Triceps']),
      ('Pull A', ['Back', 'Biceps']),
      ('Legs A', ['Quadriceps', 'Hamstrings']),
      ('Push B', ['Chest', 'Shoulders', 'Triceps']),
      ('Pull B', ['Back', 'Biceps']),
    ];

    for (var i = 0; i < templates.length; i++) {
      final (name, muscles) = templates[i];
      final templateId = _uuid.v4();
      
      await _database.insertWorkoutTemplate(
        WorkoutTemplateData(
          id: templateId,
          name: name,
          notes: 'Generated by setup wizard - PPL split',
        ),
      );

      // Add exercises targeting specified muscles
      final selectedExercises = <ExerciseData>[];
      for (final muscle in muscles) {
        selectedExercises.addAll(
          exercises.where((e) => e.primaryMuscle == muscle).take(2),
        );
      }
      // Add core
      selectedExercises.addAll(_findExercises(exercises, ['Core'], 1));

      for (var j = 0; j < selectedExercises.length; j++) {
        await _database.insertTemplateExercise(
          TemplateExerciseData(
            id: _uuid.v4(),
            templateId: templateId,
            exerciseId: selectedExercises[j].id,
            orderIndex: j,
            defaultSets: 3,
            defaultReps: 10,
            defaultWeight: null,
          ),
        );
      }
    }

    debugPrint('[WORKOUT-GEN] ✅ Generated 5-day PPL split');
  }

  Future<void> _generateMobilityPack() async {
    // Daily 10-minute mobility pack
    final mobilityId = _uuid.v4();
    
    await _database.insertWorkoutTemplate(
      WorkoutTemplateData(
        id: mobilityId,
        name: 'Daily 10min Mobility',
        notes: 'Daily mobility routine (hips/thoracic/ankle/shoulder) - 3 rounds',
      ),
    );

    // Mobility exercises
    final mobilityDrills = [
      ('90/90 Hip Switch', '10 reps', 'Hips'),
      ('Couch Stretch', '45s/side', 'Hips'),
      ('Thoracic Open Book', '10 reps', 'Back'),
      ('Ankle Dorsiflexion Lunge', '10 reps', 'Legs'),
      ('Band Shoulder Dislocates', '12 reps', 'Shoulders'),
    ];

    for (var i = 0; i < mobilityDrills.length; i++) {
      final (name, reps, muscle) = mobilityDrills[i];
      
      // Create exercise if it doesn't exist
      final exerciseId = _uuid.v4();
      await _database.insertExercise(
        ExerciseData(
          id: exerciseId,
          name: name,
          primaryMuscle: muscle,
          unit: 'reps',
          notes: 'Mobility drill - perform slowly with control',
        ),
      );

      await _database.insertTemplateExercise(
        TemplateExerciseData(
          id: _uuid.v4(),
          templateId: mobilityId,
          exerciseId: exerciseId,
          orderIndex: i,
          defaultSets: 3,
          defaultReps: 10,
          defaultWeight: null,
        ),
      );
    }

    debugPrint('[WORKOUT-GEN] ✅ Generated mobility pack');
  }

  Future<void> _generateRehabAddons() async {
    if (_profile.injuries.isEmpty || _profile.injuries.contains('none')) {
      debugPrint('[WORKOUT-GEN] No injuries reported, skipping rehab generation');
      return;
    }

    final rehabSpecs = {
      'shoulder': [
        ('External Rotation (band)', 'Shoulders', 'Light band, 15 reps'),
        ('YTWs (light DB)', 'Shoulders', 'Very light weight, 12 reps'),
        ('Face Pull (light)', 'Shoulders', 'Focus on rear delts, 15 reps'),
      ],
      'back': [
        ('Bird Dog', 'Core', 'Slow and controlled, 12 reps/side'),
        ('McGill Curl-Up', 'Core', 'Partial sit-up, 10-15 reps'),
        ('Hip Hinge with PVC', 'Back', 'Practice hip hinge pattern, 12 reps'),
      ],
      'knee': [
        ('Step-up (low box)', 'Quadriceps', 'Low box, control descent, 10 reps'),
        ('Spanish Squat (band)', 'Quadriceps', 'Band around knees, 12 reps'),
        ('Hamstring Curl (band)', 'Hamstrings', 'Light band, 12 reps'),
      ],
      'ankle': [
        ('Ankle Circles', 'Calves', '10 each direction'),
        ('Calf Raises', 'Calves', 'Slow tempo, 15 reps'),
        ('Dorsiflexion Stretch', 'Calves', 'Wall stretch, 30s'),
      ],
      'elbow': [
        ('Wrist Curls', 'Forearms', 'Light weight, 15 reps'),
        ('Reverse Wrist Curls', 'Forearms', 'Light weight, 15 reps'),
        ('Forearm Stretch', 'Forearms', 'Static stretch, 30s'),
      ],
      'hip': [
        ('Hip Flexor Stretch', 'Hips', '45s/side'),
        ('Glute Bridge', 'Glutes', 'Bodyweight, 15 reps'),
        ('90/90 Hip Stretch', 'Hips', '30s/side'),
      ],
    };

    for (final injury in _profile.injuries) {
      if (injury == 'none' || !rehabSpecs.containsKey(injury)) continue;

      final rehabId = _uuid.v4();
      final injuryName = injury[0].toUpperCase() + injury.substring(1);
      
      await _database.insertWorkoutTemplate(
        WorkoutTemplateData(
          id: rehabId,
          name: 'Rehab: $injuryName',
          notes: 'Injury rehab protocol for $injury - perform 2-3x/week',
        ),
      );

      final drills = rehabSpecs[injury]!;
      for (var i = 0; i < drills.length; i++) {
        final (name, muscle, notes) = drills[i];
        
        // Create exercise
        final exerciseId = _uuid.v4();
        await _database.insertExercise(
          ExerciseData(
            id: exerciseId,
            name: name,
            primaryMuscle: muscle,
            unit: 'reps',
            notes: notes,
          ),
        );

        await _database.insertTemplateExercise(
          TemplateExerciseData(
            id: _uuid.v4(),
            templateId: rehabId,
            exerciseId: exerciseId,
            orderIndex: i,
            defaultSets: 3,
            defaultReps: 12,
            defaultWeight: null,
          ),
        );
      }

      debugPrint('[WORKOUT-GEN] ✅ Generated rehab template for $injury');
    }
  }
}

