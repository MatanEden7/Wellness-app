import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/date_utils.dart';
import '../../../data/db/drift_database.dart';
import '../domain/models.dart';

final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  final database = ref.read(databaseProvider);
  return SleepRepository(database);
});

/// Cached, limit-keyed stream of recent sleep entries -- see
/// `exercisesStreamProvider` in `workouts/data/repositories.dart` for why
/// `.watchRecentEntries()` should not be called directly inside `build()`.
final recentSleepEntriesStreamProvider =
    Provider.family<Stream<List<SleepEntry>>, int>((ref, limit) {
  return ref.read(sleepRepositoryProvider).watchRecentEntries(limit: limit);
});

/// Recomputes whenever a sleep entry changes, by riding the same stream the
/// entry list already watches -- cheaper than a bespoke invalidation path.
final sleepStreakProvider = StreamProvider.family<int, double>((ref, goalHours) {
  final repo = ref.read(sleepRepositoryProvider);
  return repo
      .watchRecentEntries(limit: 90)
      .asyncMap((_) => repo.getSleepStreak(goalHours));
});

class SleepRepository {
  final AppDatabase _database;

  SleepRepository(this._database);

  Stream<List<SleepEntry>> watchRecentEntries({int limit = 30}) {
    return _database.watchSleepStream().asyncMap((_) async {
      final entries = await _database.getRecentSleepEntries(limit: limit);
      return entries.map(_sleepEntryDataToModel).toList();
    });
  }

  Future<SleepEntry?> getEntryById(String id) async {
    final entry = await _database.getSleepEntryById(id);
    return entry != null ? _sleepEntryDataToModel(entry) : null;
  }

  Future<void> createEntry(SleepEntry entry) async {
    await _database.insertSleepEntry(_sleepEntryModelToData(entry));
  }

  Future<void> updateEntry(SleepEntry entry) async {
    await _database.updateSleepEntry(_sleepEntryModelToData(entry));
  }

  Future<void> deleteEntry(String id) async {
    await _database.deleteSleepEntry(id);
  }

  Future<double?> getLastNightSleepHours() async {
    return await _database.getLastNightSleepHours();
  }

  Future<Map<String, double>> getSleepWeekTotals() async {
    return await _database.getSleepWeekTotals();
  }

  /// Consecutive days, ending today, with a completed entry meeting
  /// [goalHours]. A day with no entry -- or only entries under goal --
  /// breaks the streak. One entry per calendar day is enough; multiple
  /// entries the same day (e.g. a nap) don't stack.
  Future<int> getSleepStreak(double goalHours) async {
    final entries = await _database.getRecentSleepEntries(limit: 90);
    final metByDay = <DateTime, bool>{};
    for (final entry in entries) {
      final endedAt = entry.endedAt;
      if (endedAt == null) continue;
      final day = AppDateUtils.startOfDay(endedAt);
      final hours = endedAt.difference(entry.startedAt).inMinutes / 60.0;
      if (hours >= goalHours) {
        metByDay[day] = true;
      } else {
        metByDay.putIfAbsent(day, () => false);
      }
    }

    var streak = 0;
    var cursor = AppDateUtils.startOfDay(DateTime.now());
    while (metByDay[cursor] == true) {
      streak++;
      // DateTime constructor, not `subtract(Duration(days: 1))` -- DST-safe
      // day stepping, matching the fix in AppDateUtils.startOfWeek.
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }

  SleepEntry _sleepEntryDataToModel(SleepEntryData data) {
    return SleepEntry(
      id: data.id,
      startedAt: data.startedAt,
      endedAt: data.endedAt,
      quality: data.quality,
      note: data.note,
    );
  }

  SleepEntryData _sleepEntryModelToData(SleepEntry model) {
    return SleepEntryData(
      id: model.id,
      startedAt: model.startedAt,
      endedAt: model.endedAt,
      quality: model.quality,
      note: model.note,
    );
  }
}
