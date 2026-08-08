import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/date_utils.dart';
import '../../../data/db/drift_database.dart';

const _uuid = Uuid();

final bodyWeightRepositoryProvider = Provider<BodyWeightRepository>((ref) {
  return BodyWeightRepository(ref.read(databaseProvider));
});

/// Cached stream of recent weigh-ins, newest first.
///
/// A provider rather than a `watchRecent()` call inside `build()` -- see
/// `exercisesStreamProvider` for why that pattern resets a `StreamBuilder` to
/// its waiting state on every rebuild.
final recentWeighInsStreamProvider =
    Provider<Stream<List<BodyWeightEntryData>>>((ref) {
  return ref.read(bodyWeightRepositoryProvider).watchRecent();
});

class BodyWeightRepository {
  final AppDatabase _database;

  BodyWeightRepository(this._database);

  Stream<List<BodyWeightEntryData>> watchRecent({int limit = 180}) {
    return _database.watchBodyWeightStream().asyncMap(
          (_) => _database.getRecentBodyWeightEntries(limit: limit),
        );
  }

  Future<BodyWeightEntryData?> latest() async {
    final entries = await _database.getRecentBodyWeightEntries(limit: 1);
    return entries.isEmpty ? null : entries.first;
  }

  /// Records [kg] for the calendar day of [at], replacing that day's entry if
  /// one exists.
  ///
  /// Upsert rather than append: body weight swings a kilo across a day on
  /// water alone, so two readings on one day are a correction, not two data
  /// points. Appending would put two dots on one day and force the daily
  /// series to pick between them arbitrarily.
  Future<void> log(double kg, {DateTime? at, String? note}) async {
    final recordedAt = at ?? DateTime.now();
    final existing = await _database.getBodyWeightEntryOnDay(recordedAt);

    if (existing != null) {
      await _database.updateBodyWeightEntry(
        existing.copyWith(kg: kg, recordedAt: recordedAt, note: note),
      );
      return;
    }

    await _database.insertBodyWeightEntry(BodyWeightEntryData(
      id: _uuid.v4(),
      recordedAt: recordedAt,
      kg: kg,
      note: note,
    ));
  }

  Future<void> delete(String id) => _database.deleteBodyWeightEntry(id);

  /// The most recent weigh-in on or before [day], for showing "today's weight"
  /// without demanding one was taken today.
  Future<BodyWeightEntryData?> asOf(DateTime day) async {
    final target = AppDateUtils.startOfDay(day);
    final entries = await _database.getRecentBodyWeightEntries(limit: 400);
    for (final entry in entries) {
      if (!AppDateUtils.startOfDay(entry.recordedAt).isAfter(target)) {
        return entry;
      }
    }
    return null;
  }
}
