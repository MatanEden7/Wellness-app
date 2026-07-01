import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/db/drift_database.dart';
import '../domain/models.dart';

final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  final database = ref.read(databaseProvider);
  return SleepRepository(database);
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
