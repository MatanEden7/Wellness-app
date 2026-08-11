@Tags(['analytics'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellness_app/core/date_utils.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/services/demo_seed_service.dart';
import 'package:wellness_app/services/user_profile_service.dart';

/// The hand-testing dataset, checked for the thing it exists to provide:
/// screens with something on them.
///
/// This was written after the demo data shipped with every calorie goal
/// unmet for six months -- portions were the template amount ±15%, which
/// summed to roughly half the target, so the hero chart had no orange in it
/// and the rings read 0/0/0/100. That is invisible to a smoke test and
/// invisible to the analyser; the only way to catch it is to add up what was
/// actually seeded.
void main() {
  setUp(AppDatabase.resetForTesting);

  /// Returns the store as well as the database: the seeder writes the profile
  /// into preferences, and the goal targets have to be read back from the
  /// *same* store. Re-mocking it first silently substitutes a default target
  /// and makes every assertion about "met" meaningless.
  Future<({AppDatabase database, SharedPreferences prefs})> seed() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final database = AppDatabase();
    await DemoSeedService(database, prefs, CalendarService(prefs, database))
        .seed();
    return (database: database, prefs: prefs);
  }

  test('seeds six months of history across every area', () async {
    final database = (await seed()).database;

    expect((await database.getAllMeals()).length, greaterThan(400),
        reason: 'meals for most of six months');
    expect((await database.getRecentWorkoutSessions(limit: 10000)).length,
        greaterThan(80),
        reason: 'roughly four sessions a week');
    expect((await database.getRecentSleepEntries(limit: 10000)).length,
        greaterThan(150));
    expect((await database.getRecentBodyWeightEntries(limit: 10000)).length,
        greaterThan(20),
        reason: 'a weekly weigh-in');
    expect((await database.getAllWorkoutTemplates()).length, greaterThan(3));
    expect((await database.getAllMealTemplates()).length, greaterThan(3));
  });

  test('most days actually reach the calorie and protein goals', () async {
    final seeded = await seed();
    final database = seeded.database;
    final profile = UserProfileService(seeded.prefs).loadProfile();
    expect(profile, isNotNull, reason: 'the seeder saves a profile');

    // The targets the app itself will score against.
    final calorieTarget = profile!.calorieTarget;
    final proteinTarget = profile.proteinTargetG;

    final meals = await database.getAllMeals();
    final kcalByDate = <int, double>{};
    final proteinByDate = <int, double>{};
    for (final meal in meals) {
      final items = await database.getMealItemsByMealId(meal.id);
      for (final item in items) {
        kcalByDate[meal.date] = (kcalByDate[meal.date] ?? 0) + item.kcal;
        proteinByDate[meal.date] =
            (proteinByDate[meal.date] ?? 0) + item.protein;
      }
    }

    final days = kcalByDate.keys.length;
    // muscle_gain counts >=95% of target as a hit -- the same rule the hero
    // chart uses.
    final kcalMet =
        kcalByDate.values.where((k) => k >= calorieTarget * 0.95).length;
    final proteinMet =
        proteinByDate.values.where((p) => p >= proteinTarget * 0.95).length;

    expect(kcalMet / days, greaterThan(0.5),
        reason: 'the calorie goal should be met on most logged days, '
            'or the hero chart has no orange in it');
    expect(kcalMet / days, lessThan(0.95),
        reason: 'and missed on some, or a missed day cannot be demonstrated');
    expect(proteinMet / days, greaterThan(0.4),
        reason: 'protein should be reachable too');
  });

  test('today is a complete day, so the goal rings are not all empty',
      () async {
    final database = (await seed()).database;
    final todayInt = AppDateUtils.dateToInt(DateTime.now());
    final today = AppDateUtils.startOfDay(DateTime.now());

    final meals =
        (await database.getAllMeals()).where((m) => m.date == todayInt);
    expect(meals, isNotEmpty, reason: 'today needs meals');

    final sessions = (await database.getRecentWorkoutSessions(limit: 50))
        .where((s) => AppDateUtils.startOfDay(s.startedAt) == today);
    expect(sessions, isNotEmpty,
        reason: 'today needs a session, or the training ring reads 0 '
            'whatever the weekday happens to be');

    final nights = (await database.getRecentSleepEntries(limit: 50)).where(
        (n) => AppDateUtils.startOfDay(n.endedAt ?? n.startedAt) == today);
    expect(nights, isNotEmpty, reason: 'today needs a night');
    expect(nights.first.endedAt!.difference(nights.first.startedAt).inMinutes,
        greaterThanOrEqualTo(450),
        reason: 'and it has to clear the 8h goal minus its half-hour slack');
  });

  test('the deliberate edits are present', () async {
    final database = (await seed()).database;

    final templates = await database.getAllWorkoutTemplates();
    final withCustomRest = templates.where((t) => t.customRest);
    expect(withCustomRest, isNotEmpty,
        reason: 'one template demonstrates custom breaks');

    final rows = await database
        .getTemplateExercisesByTemplateId(withCustomRest.first.id);
    expect(rows.where((r) => r.isRest).length, 2,
        reason: 'two breaks, placed mid-workout');
    expect(rows.first.isRest, isFalse,
        reason: 'a workout does not open with a break');

    // User-owned content, which regeneration must never replace.
    expect((await database.getAllFoods()).any((f) => !f.isStarter), isTrue);
    expect((await database.getAllExercises()).any((e) => e.id.startsWith('demo-')),
        isTrue);
  });
}
