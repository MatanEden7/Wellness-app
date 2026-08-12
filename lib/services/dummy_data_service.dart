import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/date_utils.dart';
import '../features/meals/data/repositories.dart';
import '../features/meals/domain/models.dart';
import '../features/workouts/data/repositories.dart';
import '../features/workouts/domain/models.dart';
import '../features/sleep/data/repositories.dart';
import '../features/sleep/domain/models.dart';
import '../features/calendar/data/calendar_service.dart';
import '../features/calendar/domain/models.dart';
import 'workout_profiles_service.dart';

final dummyDataServiceProvider = Provider<DummyDataService>((ref) {
  final mealsRepo = ref.read(mealsRepositoryProvider);
  final exercisesRepo = ref.read(exercisesRepositoryProvider);
  final workoutTemplatesRepo = ref.read(workoutTemplatesRepositoryProvider);
  final workoutSessionsRepo = ref.read(workoutSessionsRepositoryProvider);
  final sleepRepo = ref.read(sleepRepositoryProvider);
  final calendarService = ref.read(calendarServiceProvider);

  return DummyDataService(
    mealsRepository: mealsRepo,
    exercisesRepository: exercisesRepo,
    workoutTemplatesRepository: workoutTemplatesRepo,
    workoutSessionsRepository: workoutSessionsRepo,
    sleepRepository: sleepRepo,
    calendarService: calendarService,
  );
});

class DummyDataService {
  final MealsRepository mealsRepository;
  final ExercisesRepository exercisesRepository;
  final WorkoutTemplatesRepository workoutTemplatesRepository;
  final WorkoutSessionsRepository workoutSessionsRepository;
  final SleepRepository sleepRepository;
  final CalendarService calendarService;

  final _random = Random();

  DummyDataService({
    required this.mealsRepository,
    required this.exercisesRepository,
    required this.workoutTemplatesRepository,
    required this.workoutSessionsRepository,
    required this.sleepRepository,
    required this.calendarService,
  });

  Future<void> generateAllDummyData() async {
    debugPrint('[DUMMY] 🎬 Starting dummy data generation...');

    // Step 1: Create food items first
    debugPrint('[DUMMY] 🍎 Creating food items...');
    final foods = await _createFoodItems();

    // Step 2: Create meal templates
    debugPrint('[DUMMY] 📋 Creating meal templates...');
    await _createMealTemplates(foods);

    // Step 3: Create meals for past 14 days (3 meals + snacks daily)
    debugPrint(
        '[DUMMY] 🍽️ Creating realistic meal patterns for past 14 days...');
    await _createMeals(foods);

    // Step 4: Create exercises
    debugPrint('[DUMMY] 💪 Creating exercises...');
    final exercises = await _createExercises();

    // Step 5: Create workout templates
    debugPrint('[DUMMY] 📝 Creating workout templates...');
    final templates = await _createWorkoutTemplates(exercises);

    // Step 6: Create workout sessions (3 per week for 2 weeks)
    debugPrint('[DUMMY] 🏋️ Creating workout sessions (3 per week)...');
    await _createWorkoutSessions(templates, exercises);

    // Step 7: Create sleep entries for past 14 nights
    debugPrint('[DUMMY] 😴 Creating sleep entries for past 14 nights...');
    await _createSleepEntries();

    // Step 8: Create recurring scheduled events for future
    debugPrint('[DUMMY] 📅 Creating recurring scheduled events...');
    await _createRecurringScheduledEvents(templates);

    debugPrint('[DUMMY] ✅ Dummy data generation complete!');
  }

  Future<List<FoodItem>> _createFoodItems() async {
    final foods = [
      FoodItem.create(
        name: 'Oatmeal',
        unit: '100g',
        kcalPerUnit: 389,
        proteinPerUnit: 13.2,
        carbsPerUnit: 66.3,
        fatPerUnit: 6.9,
      ),
      FoodItem.create(
        name: 'Greek Yogurt',
        unit: '100g',
        kcalPerUnit: 97,
        proteinPerUnit: 10.3,
        carbsPerUnit: 3.6,
        fatPerUnit: 5.0,
      ),
      FoodItem.create(
        name: 'Eggs',
        unit: 'large',
        kcalPerUnit: 72,
        proteinPerUnit: 6.3,
        carbsPerUnit: 0.4,
        fatPerUnit: 4.8,
      ),
      FoodItem.create(
        name: 'Avocado',
        unit: 'half',
        kcalPerUnit: 120,
        proteinPerUnit: 1.5,
        carbsPerUnit: 6.0,
        fatPerUnit: 11.0,
      ),
      FoodItem.create(
        name: 'Salmon',
        unit: '100g',
        kcalPerUnit: 206,
        proteinPerUnit: 22.0,
        carbsPerUnit: 0.0,
        fatPerUnit: 13.0,
      ),
      FoodItem.create(
        name: 'Sweet Potato',
        unit: '100g',
        kcalPerUnit: 86,
        proteinPerUnit: 1.6,
        carbsPerUnit: 20.1,
        fatPerUnit: 0.1,
      ),
      FoodItem.create(
        name: 'Broccoli',
        unit: '100g',
        kcalPerUnit: 34,
        proteinPerUnit: 2.8,
        carbsPerUnit: 7.0,
        fatPerUnit: 0.4,
      ),
      FoodItem.create(
        name: 'Almonds',
        unit: '30g',
        kcalPerUnit: 170,
        proteinPerUnit: 6.0,
        carbsPerUnit: 6.0,
        fatPerUnit: 15.0,
      ),
      FoodItem.create(
        name: 'Quinoa',
        unit: '100g',
        kcalPerUnit: 120,
        proteinPerUnit: 4.4,
        carbsPerUnit: 21.3,
        fatPerUnit: 1.9,
      ),
      FoodItem.create(
        name: 'Blueberries',
        unit: '100g',
        kcalPerUnit: 57,
        proteinPerUnit: 0.7,
        carbsPerUnit: 14.5,
        fatPerUnit: 0.3,
      ),
    ];

    for (final food in foods) {
      await mealsRepository.createFood(food);
    }

    return foods;
  }

  Future<void> _createMealTemplates(List<FoodItem> foods) async {
    // Template 1: Protein Breakfast
    final breakfast = MealTemplate.create(
      name: 'Protein Breakfast',
      description: 'High protein breakfast to start the day',
    );
    final breakfastItems = [
      MealTemplateItem.create(
        templateId: breakfast.id,
        foodId: foods[2].id, // Eggs
        amount: 3,
      ),
      MealTemplateItem.create(
        templateId: breakfast.id,
        foodId: foods[3].id, // Avocado
        amount: 1,
      ),
      MealTemplateItem.create(
        templateId: breakfast.id,
        foodId: foods[0].id, // Oatmeal
        amount: 0.5,
      ),
    ];
    await mealsRepository
        .createMealTemplate(breakfast.copyWith(items: breakfastItems));

    // Template 2: Healthy Lunch
    final lunch = MealTemplate.create(
      name: 'Healthy Lunch',
      description: 'Balanced lunch with protein and veggies',
    );
    final lunchItems = [
      MealTemplateItem.create(
        templateId: lunch.id,
        foodId: foods[4].id, // Salmon
        amount: 1.5,
      ),
      MealTemplateItem.create(
        templateId: lunch.id,
        foodId: foods[8].id, // Quinoa
        amount: 1,
      ),
      MealTemplateItem.create(
        templateId: lunch.id,
        foodId: foods[6].id, // Broccoli
        amount: 1.5,
      ),
    ];
    await mealsRepository.createMealTemplate(lunch.copyWith(items: lunchItems));

    // Template 3: Post-Workout Snack
    final snack = MealTemplate.create(
      name: 'Post-Workout Snack',
      description: 'Quick protein and carbs after workout',
    );
    final snackItems = [
      MealTemplateItem.create(
        templateId: snack.id,
        foodId: foods[1].id, // Greek Yogurt
        amount: 2,
      ),
      MealTemplateItem.create(
        templateId: snack.id,
        foodId: foods[9].id, // Blueberries
        amount: 1,
      ),
      MealTemplateItem.create(
        templateId: snack.id,
        foodId: foods[7].id, // Almonds
        amount: 1,
      ),
    ];
    await mealsRepository.createMealTemplate(snack.copyWith(items: snackItems));
  }

  Future<void> _createMeals(List<FoodItem> foods) async {
    final now = DateTime.now();

    // Create realistic meal patterns for past 14 days
    for (int dayOffset = 0; dayOffset < 14; dayOffset++) {
      final date = now.subtract(Duration(days: dayOffset));
      final dateInt = AppDateUtils.dateToInt(date);

      // Breakfast (7:30-8:30 AM) - Always present
      final breakfast = Meal.create(
        date: dateInt,
        name: 'Breakfast',
      );
      final breakfastItems = [
        MealItem.create(
          mealId: breakfast.id,
          foodId: foods[0].id, // Oatmeal
          amount: 1.0,
          food: foods[0],
        ),
        MealItem.create(
          mealId: breakfast.id,
          foodId: foods[2].id, // Eggs
          amount: 2.0,
          food: foods[2],
        ),
        MealItem.create(
          mealId: breakfast.id,
          foodId: foods[9].id, // Blueberries
          amount: 0.5,
          food: foods[9],
        ),
      ];
      await mealsRepository
          .createMeal(breakfast.copyWith(items: breakfastItems));

      // Morning Snack (10:30-11:00 AM) - Sometimes
      if (dayOffset % 3 == 0) {
        final morningSnack = Meal.create(
          date: dateInt,
          name: 'Morning Snack',
        );
        final snackItems = [
          MealItem.create(
            mealId: morningSnack.id,
            foodId: foods[1].id, // Greek Yogurt
            amount: 1.0,
            food: foods[1],
          ),
          MealItem.create(
            mealId: morningSnack.id,
            foodId: foods[7].id, // Almonds
            amount: 0.5,
            food: foods[7],
          ),
        ];
        await mealsRepository
            .createMeal(morningSnack.copyWith(items: snackItems));
      }

      // Lunch (12:30-1:30 PM) - Always present
      final lunch = Meal.create(
        date: dateInt,
        name: 'Lunch',
      );
      final lunchItems = [
        MealItem.create(
          mealId: lunch.id,
          foodId: foods[4].id, // Salmon
          amount: 1.5,
          food: foods[4],
        ),
        MealItem.create(
          mealId: lunch.id,
          foodId: foods[5].id, // Sweet Potato
          amount: 1.0,
          food: foods[5],
        ),
        MealItem.create(
          mealId: lunch.id,
          foodId: foods[6].id, // Broccoli
          amount: 1.5,
          food: foods[6],
        ),
      ];
      await mealsRepository.createMeal(lunch.copyWith(items: lunchItems));

      // Afternoon Snack (3:30-4:00 PM) - Often
      if (dayOffset % 2 == 0) {
        final afternoonSnack = Meal.create(
          date: dateInt,
          name: 'Afternoon Snack',
        );
        final snackItems = [
          MealItem.create(
            mealId: afternoonSnack.id,
            foodId: foods[7].id, // Almonds
            amount: 1.0,
            food: foods[7],
          ),
          MealItem.create(
            mealId: afternoonSnack.id,
            foodId: foods[3].id, // Avocado
            amount: 0.5,
            food: foods[3],
          ),
        ];
        await mealsRepository
            .createMeal(afternoonSnack.copyWith(items: snackItems));
      }

      // Dinner (7:00-8:00 PM) - Always present
      final dinner = Meal.create(
        date: dateInt,
        name: 'Dinner',
      );
      final dinnerItems = [
        MealItem.create(
          mealId: dinner.id,
          foodId: foods[4].id, // Salmon
          amount: 1.5,
          food: foods[4],
        ),
        MealItem.create(
          mealId: dinner.id,
          foodId: foods[8].id, // Quinoa
          amount: 1.0,
          food: foods[8],
        ),
        MealItem.create(
          mealId: dinner.id,
          foodId: foods[6].id, // Broccoli
          amount: 1.0,
          food: foods[6],
        ),
      ];
      await mealsRepository.createMeal(dinner.copyWith(items: dinnerItems));

      // Evening Snack (9:00-9:30 PM) - Sometimes
      if (dayOffset % 4 == 0) {
        final eveningSnack = Meal.create(
          date: dateInt,
          name: 'Evening Snack',
        );
        final snackItems = [
          MealItem.create(
            mealId: eveningSnack.id,
            foodId: foods[1].id, // Greek Yogurt
            amount: 1.0,
            food: foods[1],
          ),
        ];
        await mealsRepository
            .createMeal(eveningSnack.copyWith(items: snackItems));
      }
    }
  }

  Future<List<Exercise>> _createExercises() async {
    final exercises = [
      Exercise.create(
        name: 'Bench Press',
        primaryMuscle: 'Chest',
        unit: 'kg',
        notes: 'Compound chest exercise',
      ),
      Exercise.create(
        name: 'Squats',
        primaryMuscle: 'Quadriceps',
        unit: 'kg',
        notes: 'King of leg exercises',
      ),
      Exercise.create(
        name: 'Deadlift',
        primaryMuscle: 'Back',
        unit: 'kg',
        notes: 'Full body compound movement',
      ),
      Exercise.create(
        name: 'Overhead Press',
        primaryMuscle: 'Shoulders',
        unit: 'kg',
        notes: 'Standing shoulder press',
      ),
      Exercise.create(
        name: 'Bent Over Rows',
        primaryMuscle: 'Back',
        unit: 'kg',
        notes: 'Build a thick back',
      ),
      Exercise.create(
        name: 'Pull-ups',
        primaryMuscle: 'Back',
        unit: 'reps',
        notes: 'Bodyweight back exercise',
      ),
      Exercise.create(
        name: 'Lunges',
        primaryMuscle: 'Quadriceps',
        unit: 'reps',
        notes: 'Single leg work',
      ),
      Exercise.create(
        name: 'Dumbbell Curls',
        primaryMuscle: 'Biceps',
        unit: 'kg',
        notes: 'Isolate the biceps',
      ),
    ];

    for (final exercise in exercises) {
      await exercisesRepository.createExercise(exercise);
    }

    return exercises;
  }

  Future<List<WorkoutTemplate>> _createWorkoutTemplates(
      List<Exercise> exercises) async {
    // Template 1: Upper Body Push
    final upperPush = WorkoutTemplate.create(
      name: 'Upper Body Push',
      notes: 'Chest, shoulders, and triceps',
    );
    final upperPushExercises = [
      TemplateExercise.create(
        templateId: upperPush.id,
        exerciseId: exercises[0].id, // Bench Press
        orderIndex: 0,
        defaultSets: 4,
        defaultReps: 8,
        defaultWeight: 60.0,
      ),
      TemplateExercise.create(
        templateId: upperPush.id,
        exerciseId: exercises[3].id, // Overhead Press
        orderIndex: 1,
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 40.0,
      ),
    ];
    await workoutTemplatesRepository.createTemplate(
      upperPush.copyWith(exercises: upperPushExercises),
    );

    // Template 2: Lower Body
    final lowerBody = WorkoutTemplate.create(
      name: 'Lower Body',
      notes: 'Legs and glutes',
    );
    final lowerBodyExercises = [
      TemplateExercise.create(
        templateId: lowerBody.id,
        exerciseId: exercises[1].id, // Squats
        orderIndex: 0,
        defaultSets: 4,
        defaultReps: 10,
        defaultWeight: 80.0,
      ),
      TemplateExercise.create(
        templateId: lowerBody.id,
        exerciseId: exercises[6].id, // Lunges
        orderIndex: 1,
        defaultSets: 3,
        defaultReps: 12,
      ),
    ];
    await workoutTemplatesRepository.createTemplate(
      lowerBody.copyWith(exercises: lowerBodyExercises),
    );

    // Template 3: Upper Body Pull
    final upperPull = WorkoutTemplate.create(
      name: 'Upper Body Pull',
      notes: 'Back and biceps',
    );
    final upperPullExercises = [
      TemplateExercise.create(
        templateId: upperPull.id,
        exerciseId: exercises[2].id, // Deadlift
        orderIndex: 0,
        defaultSets: 3,
        defaultReps: 6,
        defaultWeight: 100.0,
      ),
      TemplateExercise.create(
        templateId: upperPull.id,
        exerciseId: exercises[4].id, // Rows
        orderIndex: 1,
        defaultSets: 4,
        defaultReps: 10,
        defaultWeight: 50.0,
      ),
      TemplateExercise.create(
        templateId: upperPull.id,
        exerciseId: exercises[5].id, // Pull-ups
        orderIndex: 2,
        defaultSets: 3,
        defaultReps: 8,
      ),
    ];
    await workoutTemplatesRepository.createTemplate(
      upperPull.copyWith(exercises: upperPullExercises),
    );

    return [upperPush, lowerBody, upperPull];
  }

  Future<void> _createWorkoutSessions(
    List<WorkoutTemplate> templates,
    List<Exercise> exercises,
  ) async {
    final now = DateTime.now();

    // Create realistic workout pattern: 3 workouts per week (Mon, Wed, Fri)
    // Generate for past 2 weeks
    final List<int> workoutDays = [];

    // Pattern: day 0 (Mon), 2 (Wed), 4 (Fri), 7 (Mon), 9 (Wed), 11 (Fri)
    for (int week = 0; week < 2; week++) {
      workoutDays.add(week * 7 + 0); // Monday
      workoutDays.add(week * 7 + 2); // Wednesday
      workoutDays.add(week * 7 + 4); // Friday
    }

    for (int i = 0; i < workoutDays.length; i++) {
      final dayOffset = workoutDays[i];
      final template = templates[i % templates.length];

      // Morning workout (6:30-7:30 AM)
      final startTime = DateTime(
        now.year,
        now.month,
        now.day - dayOffset,
        6,
        30 + _random.nextInt(30),
      );

      final duration = Duration(minutes: 50 + _random.nextInt(20));
      final endTime = startTime.add(duration);

      final session = WorkoutSession(
        id: 'session_${i}_${DateTime.now().millisecondsSinceEpoch}',
        templateId: template.id,
        startedAt: startTime,
        endedAt: endTime,
        note: i % 3 == 0
            ? 'Great workout!'
            : (i % 3 == 1 ? 'Solid session' : 'Felt strong today'),
        sets: [],
      );

      // Create sets for the session
      final templateExercises = await _getTemplateExercises(template.id);
      final sets = <SetEntry>[];
      int setIndex = 0;

      for (final templateEx in templateExercises) {
        for (int set = 0; set < templateEx.defaultSets; set++) {
          sets.add(
            SetEntry.create(
              sessionId: session.id,
              exerciseId: templateEx.exerciseId,
              orderIndex: setIndex++,
              reps: (templateEx.defaultReps ?? 10) + _random.nextInt(3) - 1,
              weight: templateEx.defaultWeight != null
                  ? templateEx.defaultWeight! + (_random.nextInt(11) - 5)
                  : null,
              restSeconds: 60 + _random.nextInt(60),
            ),
          );
        }
      }

      await workoutSessionsRepository
          .createSession(session.copyWith(sets: sets));
      for (final set in sets) {
        await workoutSessionsRepository.addSetEntry(set);
      }
    }
  }

  Future<List<TemplateExercise>> _getTemplateExercises(
      String templateId) async {
    final template =
        await workoutTemplatesRepository.getTemplateById(templateId);
    return template?.exercises ?? [];
  }

  Future<void> _createSleepEntries() async {
    final now = DateTime.now();

    // Create realistic sleep pattern for past 14 nights
    for (int dayOffset = 1; dayOffset <= 14; dayOffset++) {
      // Sleep starts around 10:30-11:30 PM previous day
      final sleepStart = DateTime(
        now.year,
        now.month,
        now.day - dayOffset,
        22,
        30 + _random.nextInt(60),
      );

      // Sleep duration 7-8.5 hours (realistic for adults)
      final sleepDuration = Duration(
        hours: 7,
        minutes: _random.nextInt(90),
      );

      final sleepEnd = sleepStart.add(sleepDuration);

      final quality = 3 + _random.nextInt(3); // Quality 3-5

      final entry = SleepEntry.create(
        startedAt: sleepStart,
        endedAt: sleepEnd,
        quality: quality,
        note: quality >= 4
            ? 'Slept well'
            : (quality == 3 ? 'Decent sleep' : 'Could be better'),
      );

      await sleepRepository.createEntry(entry);
    }
  }

  Future<void> _createRecurringScheduledEvents(
      List<WorkoutTemplate> templates) async {
    final now = DateTime.now();

    // Create recurring workout schedule: Mon, Wed, Fri at 7:00 AM
    // Weekly recurring for next 4 weeks
    for (int i = 0; i < templates.length; i++) {
      final template = templates[i];

      // Workout days: 1 (Mon), 3 (Wed), 5 (Fri)
      final dayOfWeek = i % 3 == 0 ? 1 : (i % 3 == 1 ? 3 : 5);

      // Find next occurrence of this day
      int daysUntilNext = (dayOfWeek - now.weekday + 7) % 7;
      if (daysUntilNext == 0)
        daysUntilNext = 7; // If today, schedule for next week

      final nextOccurrence = DateTime(
        now.year,
        now.month,
        now.day + daysUntilNext,
        7, // 7:00 AM
        0,
      );

      final workoutEvent = ScheduledEvent.create(
        title: template.name,
        description: template.notes ?? 'Scheduled workout',
        type: EventType.workout,
        scheduledAt: nextOccurrence,
        recurrenceType: RecurrenceType.weekly,
        recurrenceDays: [dayOfWeek],
        recurrenceEndDate: now.add(const Duration(days: 28)), // 4 weeks
        templateId: template.id,
      );

      await calendarService.saveEvent(workoutEvent);
      debugPrint(
          '[DUMMY] 📅 Created recurring workout: ${template.name} on ${_getDayName(dayOfWeek)}s at 7:00 AM');
    }

    // Create recurring meal schedule: Breakfast, Lunch, Dinner daily
    final mealTimes = [
      {'name': 'Breakfast', 'hour': 8, 'minute': 0},
      {'name': 'Lunch', 'hour': 12, 'minute': 30},
      {'name': 'Dinner', 'hour': 19, 'minute': 0},
    ];

    for (final mealTime in mealTimes) {
      // Start from tomorrow
      final tomorrow = DateTime(now.year, now.month, now.day + 1,
          mealTime['hour'] as int, mealTime['minute'] as int);

      final mealEvent = ScheduledEvent.create(
        title: mealTime['name'] as String,
        description: 'Daily ${mealTime['name']}',
        type: EventType.meal,
        scheduledAt: tomorrow,
        recurrenceType: RecurrenceType.daily,
        recurrenceEndDate: now.add(const Duration(days: 30)), // 1 month
      );

      await calendarService.saveEvent(mealEvent);
      debugPrint(
          '[DUMMY] 📅 Created daily meal: ${mealTime['name']} at ${mealTime['hour']}:${(mealTime['minute'] as int).toString().padLeft(2, '0')}');
    }

    // Create sleep reminder: Daily at 22:30
    final sleepTime = DateTime(now.year, now.month, now.day + 1, 22, 30);

    final sleepEvent = ScheduledEvent.create(
      title: 'Sleep Time',
      description: 'Time to wind down and prepare for sleep',
      type: EventType.sleep,
      scheduledAt: sleepTime,
      recurrenceType: RecurrenceType.daily,
      recurrenceEndDate: now.add(const Duration(days: 30)), // 1 month
    );

    await calendarService.saveEvent(sleepEvent);
    debugPrint('[DUMMY] 📅 Created daily sleep reminder at 22:30');
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  // Generate profile-based workout data
  Future<void> generateProfileData(String profileKey, bool useHebrew) async {
    final profileService = WorkoutProfilesService();

    debugPrint(
        '[PROFILE] 🎯 Generating data for profile: $profileKey (Hebrew: $useHebrew)');

    List<ExerciseData> exerciseDataList;
    List<WorkoutTemplateData> templateDataList;

    switch (profileKey) {
      case 'seniors':
        exerciseDataList = profileService.getSeniorExercises(useHebrew);
        templateDataList = profileService.getSeniorTemplates(useHebrew);
        break;
      case 'advanced':
        exerciseDataList = profileService.getAdvancedExercises(useHebrew);
        templateDataList = profileService.getAdvancedTemplates(useHebrew);
        break;
      case 'women':
        exerciseDataList = profileService.getWomenExercises(useHebrew);
        templateDataList = profileService.getWomenTemplates(useHebrew);
        break;
      case 'shoulder':
        exerciseDataList =
            profileService.getShoulderTherapyExercises(useHebrew);
        templateDataList =
            profileService.getShoulderTherapyTemplates(useHebrew);
        break;
      case 'back':
        exerciseDataList = profileService.getBackTherapyExercises(useHebrew);
        templateDataList = profileService.getBackTherapyTemplates(useHebrew);
        break;
      case 'knee':
        exerciseDataList = profileService.getKneeTherapyExercises(useHebrew);
        templateDataList = profileService.getKneeTherapyTemplates(useHebrew);
        break;
      default:
        throw Exception('Unknown profile: $profileKey');
    }

    // Create exercises
    final exercises = <Exercise>[];
    for (final data in exerciseDataList) {
      final exercise = Exercise.create(
        name: data.name,
        primaryMuscle: data.primaryMuscle,
        unit: 'reps',
        notes: data.notes,
      );
      await exercisesRepository.createExercise(exercise);
      exercises.add(exercise);
      debugPrint('[PROFILE] ✅ Created exercise: ${exercise.name}');
    }

    // Create workout templates
    for (final templateData in templateDataList) {
      final templateExercises = <TemplateExercise>[];
      for (final exerciseData in templateData.exercises) {
        final exercise = exercises[exerciseData.orderIndex];
        final templateExercise = TemplateExercise.create(
          templateId: '', // Will be set when creating template
          exerciseId: exercise.id,
          orderIndex: exerciseData.orderIndex,
          defaultSets: exerciseData.defaultSets,
          defaultReps: exerciseData.defaultReps,
          defaultWeight: exerciseData.defaultWeight,
        );
        templateExercises.add(templateExercise);
      }

      final template = WorkoutTemplate.create(
        name: templateData.name,
        notes: templateData.notes,
      );

      await workoutTemplatesRepository.createTemplate(
        template.copyWith(exercises: templateExercises),
      );
      debugPrint('[PROFILE] ✅ Created template: ${template.name}');
    }

    // Generate sample workout sessions (last 7 days)
    await _createProfileWorkoutSessions(
        exercises, templateDataList, profileKey);

    // Generate meals and sleep data
    final foods = await _createFoodItems();
    await _createMeals(foods);
    await _createSleepEntries();

    debugPrint('[PROFILE] ✅ Profile data generation complete!');
  }

  Future<void> _createProfileWorkoutSessions(
    List<Exercise> exercises,
    List<WorkoutTemplateData> templateDataList,
    String profileKey,
  ) async {
    final now = DateTime.now();

    // Generate 3-4 workout sessions over the past week
    final sessionDays = profileKey == 'advanced'
        ? [1, 3, 5, 7] // Mon, Wed, Fri, Sun for advanced
        : [2, 4, 6]; // Tue, Thu, Sat for others

    for (int i = 0;
        i < sessionDays.length && i < templateDataList.length;
        i++) {
      final daysAgo = sessionDays[i];
      final sessionStart = now.subtract(Duration(days: daysAgo, hours: 10));
      final sessionEnd =
          sessionStart.add(Duration(minutes: 45 + _random.nextInt(30)));

      final session = WorkoutSession.create()
          .copyWith(startedAt: sessionStart, endedAt: sessionEnd);

      // Add sets for this session based on template
      final templateData = templateDataList[i % templateDataList.length];
      final sets = <SetEntry>[];

      for (final exerciseData in templateData.exercises) {
        final exercise = exercises[exerciseData.orderIndex];

        for (int setNum = 0; setNum < exerciseData.defaultSets; setNum++) {
          final reps = exerciseData.defaultReps +
              _random.nextInt(3) -
              1; // ±1 rep variation
          final weight = exerciseData.defaultWeight != null
              ? exerciseData.defaultWeight! +
                  _random.nextDouble() * 5 // ±2.5kg variation
              : null;

          final set = SetEntry.create(
            sessionId: session.id,
            exerciseId: exercise.id,
            orderIndex: sets.length,
            reps: reps,
            weight: weight,
          );
          sets.add(set);
        }
      }

      await workoutSessionsRepository
          .createSession(session.copyWith(sets: sets));
      debugPrint(
          '[PROFILE] ✅ Created workout session with ${sets.length} sets');
    }
  }
}
