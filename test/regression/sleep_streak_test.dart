@Tags(['persistence'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/sleep/data/repositories.dart';

/// Coverage for [SleepRepository.getSleepStreak], added this pass with no
/// dedicated test -- only exercised indirectly through the UI. Uses the
/// underlying [AppDatabase] directly (as `data_integrity_test.dart` does)
/// rather than the domain-model repository layer, since it's the entry
/// timestamps that matter here, not conversion.
void main() {
  setUp(AppDatabase.resetForTesting);

  SleepEntryData entry(String id, DateTime started, DateTime ended) =>
      SleepEntryData(id: id, startedAt: started, endedAt: ended);

  test('zero when there are no sleep entries at all', () async {
    final database = AppDatabase();
    final repo = SleepRepository(database);

    expect(await repo.getSleepStreak(8.0), 0);
  });

  test('counts consecutive days ending today that meet the goal', () async {
    final database = AppDatabase();
    final repo = SleepRepository(database);
    final today = DateTime.now();

    for (var i = 0; i < 3; i++) {
      final day = DateTime(today.year, today.month, today.day - i);
      await database.insertSleepEntry(entry(
        'e$i',
        day.subtract(const Duration(hours: 8)),
        day,
      ));
    }

    expect(await repo.getSleepStreak(7.0), 3);
  });

  test('a day under goal breaks the streak', () async {
    final database = AppDatabase();
    final repo = SleepRepository(database);
    final today = DateTime.now();

    // Today and yesterday meet goal; two days ago falls short.
    await database.insertSleepEntry(entry(
      'today',
      DateTime(today.year, today.month, today.day).subtract(const Duration(hours: 8)),
      DateTime(today.year, today.month, today.day),
    ));
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    await database.insertSleepEntry(entry(
      'yesterday',
      yesterday.subtract(const Duration(hours: 8)),
      yesterday,
    ));
    final twoDaysAgo = DateTime(today.year, today.month, today.day - 2);
    await database.insertSleepEntry(entry(
      'two-days-ago',
      twoDaysAgo.subtract(const Duration(hours: 3)), // under goal
      twoDaysAgo,
    ));

    expect(await repo.getSleepStreak(7.0), 2);
  });

  test('a day with no entry breaks the streak', () async {
    final database = AppDatabase();
    final repo = SleepRepository(database);
    final today = DateTime.now();

    await database.insertSleepEntry(entry(
      'today',
      DateTime(today.year, today.month, today.day).subtract(const Duration(hours: 8)),
      DateTime(today.year, today.month, today.day),
    ));
    // Skip yesterday entirely -- no entry.
    final twoDaysAgo = DateTime(today.year, today.month, today.day - 2);
    await database.insertSleepEntry(entry(
      'two-days-ago',
      twoDaysAgo.subtract(const Duration(hours: 8)),
      twoDaysAgo,
    ));

    expect(await repo.getSleepStreak(7.0), 1,
        reason: 'the gap on the missing day must stop the count, not skip over it');
  });

  test('an unfinished entry (endedAt null) does not count toward the streak', () async {
    final database = AppDatabase();
    final repo = SleepRepository(database);
    final today = DateTime.now();

    await database.insertSleepEntry(SleepEntryData(
      id: 'active',
      startedAt: DateTime(today.year, today.month, today.day).subtract(const Duration(hours: 2)),
      endedAt: null,
    ));

    expect(await repo.getSleepStreak(7.0), 0);
  });

  test('a nap on the same day as a goal-meeting entry does not double-count', () async {
    final database = AppDatabase();
    final repo = SleepRepository(database);
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);

    await database.insertSleepEntry(entry('night', day.subtract(const Duration(hours: 8)), day));
    await database.insertSleepEntry(SleepEntryData(
      id: 'nap',
      startedAt: day.add(const Duration(hours: 13)),
      endedAt: day.add(const Duration(hours: 13, minutes: 30)),
    ));

    expect(await repo.getSleepStreak(7.0), 1);
  });
}
