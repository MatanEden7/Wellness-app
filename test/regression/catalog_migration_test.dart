@Tags(['persistence'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/catalog/starter_foods.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/meals/domain/food_category.dart';

/// Coverage for how a **catalog addition reaches someone who already has the
/// app installed**.
///
/// `_applySnapshot` replaces the food list rather than merging it, which is
/// deliberate — merging would duplicate the whole catalog on every boot and
/// resurrect starter foods the user deleted. The cost was that every food
/// added after a user's first launch was invisible to them forever, which
/// makes "we added 56 foods" not a shipped feature for anyone but new
/// installs.
///
/// The fix is a high-water mark of ids the install has ever been *offered*,
/// which is a different thing from the ids it currently holds. These are the
/// two behaviours that have to hold at once, and they pull in opposite
/// directions:
///
///   * a food the build knows about and the snapshot has never seen is added;
///   * a food the user deleted stays deleted.
class FakeSnapshotStore implements SnapshotStore {
  FakeSnapshotStore([this.contents]);

  String? contents;

  @override
  Future<String?> read() async => contents;

  @override
  Future<void> write(String value) async => contents = value;
}

/// A snapshot holding exactly [foodIds] from the catalog, written the way an
/// older build would have: no `introducedFoodIds` key at all.
String _legacySnapshot(Iterable<String> foodIds) {
  final wanted = foodIds.toSet();
  final rows = [
    for (final food in StarterFoodCatalog.all)
      if (wanted.contains(food.id))
        {
          'id': food.id,
          'name': food.name,
          // Legacy rows predate Hebrew names.
          'nameHe': null,
          'brand': food.brand,
          'unit': food.unit,
          'kcalPerUnit': food.kcal,
          'proteinPerUnit': food.protein,
          'carbsPerUnit': food.carbs,
          'fatPerUnit': food.fat,
          'isStarter': true,
          'tags': food.tags.map((t) => t.key).toList()..sort(),
          // Legacy rows predate categories too.
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
        },
  ];
  return jsonEncode({'version': 1, 'foods': rows});
}

/// The ids that existed before the high-water mark was recorded.
final _legacyIds = [for (var i = 1; i <= 53; i++) '$i'];

void main() {
  setUp(AppDatabase.resetForTesting);

  group('an upgrading install', () {
    test('receives the foods added since its snapshot was written', () async {
      final store = FakeSnapshotStore(_legacySnapshot(_legacyIds));
      final db = AppDatabase(store: store);
      await db.load();

      final ids = (await db.getAllFoods()).map((f) => f.id).toSet();
      for (final food in StarterFoodCatalog.all) {
        expect(ids, contains(food.id),
            reason: '${food.name} (${food.id}) never reached the user');
      }
      expect(ids.length, StarterFoodCatalog.all.length);
    });

    test('does not get a starter food it deleted resurrected', () async {
      // The user deleted Salmon (2) and Tofu (8) before upgrading.
      final kept = _legacyIds.where((id) => id != '2' && id != '8');
      final store = FakeSnapshotStore(_legacySnapshot(kept));
      final db = AppDatabase(store: store);
      await db.load();

      final ids = (await db.getAllFoods()).map((f) => f.id).toSet();
      expect(ids, isNot(contains('2')));
      expect(ids, isNot(contains('8')));
      // ...but the new ones still arrived.
      expect(ids, contains('54')); // Hummus
      expect(ids, contains('99')); // Big Mac
    });

    test('gets categories backfilled onto the rows it already had', () async {
      // Without this every pre-existing food lands in `other`, and the
      // category filter -- the whole point of adding categories to a
      // 233-food catalog -- shows one useless bucket for anyone upgrading.
      final store = FakeSnapshotStore(_legacySnapshot(_legacyIds));
      final db = AppDatabase(store: store);
      await db.load();

      final foods = await db.getAllFoods();
      expect(foods.firstWhere((f) => f.id == '1').category,
          FoodCategory.protein);
      expect(foods.firstWhere((f) => f.id == '23').category,
          FoodCategory.vegetables);
      expect(foods.firstWhere((f) => f.id == '32').category,
          FoodCategory.fruit);
      expect(foods.where((f) => f.category == FoodCategory.other), isEmpty,
          reason: 'a seeded row was left unclassified after migration');
    });

    test('leaves a renamed starter row alone rather than mislabelling it',
        () async {
      final store = FakeSnapshotStore(_legacySnapshot(['1']));
      final db = AppDatabase(store: store);
      await db.load();
      final chicken = (await db.getAllFoods()).firstWhere((f) => f.id == '1');
      // The user repurposed the row. The seed's Hebrew name and category no
      // longer describe what is in it.
      await db.updateFood(FoodItemData(
        id: chicken.id,
        name: 'My protein shake',
        brand: chicken.brand,
        unit: chicken.unit,
        kcalPerUnit: chicken.kcalPerUnit,
        proteinPerUnit: chicken.proteinPerUnit,
        carbsPerUnit: chicken.carbsPerUnit,
        fatPerUnit: chicken.fatPerUnit,
        isStarter: chicken.isStarter,
        tags: chicken.tags,
        createdAt: chicken.createdAt,
        updatedAt: DateTime.now(),
      ));
      await db.flush();

      final reloaded = AppDatabase(store: store);
      await reloaded.load();
      final row = (await reloaded.getAllFoods()).firstWhere((f) => f.id == '1');
      expect(row.nameHe, isNull);
      expect(row.category, FoodCategory.other);
    });

    test('gets Hebrew names backfilled onto the rows it already had', () async {
      final store = FakeSnapshotStore(_legacySnapshot(_legacyIds));
      final db = AppDatabase(store: store);
      await db.load();

      final chicken =
          (await db.getAllFoods()).firstWhere((f) => f.id == '1');
      expect(chicken.nameHe, 'חזה עוף');
    });

    test('keeps a Hebrew name the user set rather than overwriting it',
        () async {
      final store = FakeSnapshotStore(_legacySnapshot(['1']));
      final db = AppDatabase(store: store);
      await db.load();

      final chicken = (await db.getAllFoods()).firstWhere((f) => f.id == '1');
      await db.updateFood(FoodItemData(
        id: chicken.id,
        name: chicken.name,
        nameHe: 'העוף שלי',
        brand: chicken.brand,
        unit: chicken.unit,
        kcalPerUnit: chicken.kcalPerUnit,
        proteinPerUnit: chicken.proteinPerUnit,
        carbsPerUnit: chicken.carbsPerUnit,
        fatPerUnit: chicken.fatPerUnit,
        isStarter: chicken.isStarter,
        tags: chicken.tags,
        createdAt: chicken.createdAt,
        updatedAt: DateTime.now(),
      ));
      await db.flush();

      final reloaded = AppDatabase(store: store);
      await reloaded.load();
      expect(
        (await reloaded.getAllFoods()).firstWhere((f) => f.id == '1').nameHe,
        'העוף שלי',
      );
    });

    test('does not duplicate anything when loaded twice', () async {
      final store = FakeSnapshotStore(_legacySnapshot(_legacyIds));

      await AppDatabase(store: store).load();
      final second = AppDatabase(store: store);
      await second.load();

      final ids = (await second.getAllFoods()).map((f) => f.id).toList();
      expect(ids.length, ids.toSet().length, reason: 'duplicate food ids');
      expect(ids.length, StarterFoodCatalog.all.length);
    });
  });

  group('the high-water mark', () {
    test('is persisted, so a delete after upgrading is permanent', () async {
      // Upgrade: the new foods arrive.
      final store = FakeSnapshotStore(_legacySnapshot(_legacyIds));
      final first = AppDatabase(store: store);
      await first.load();
      expect((await first.getAllFoods()).any((f) => f.id == '99'), isTrue);

      // The user does not want McDonald's in their catalog.
      await first.deleteFood('99');
      await first.flush();

      // Next launch: it must not come back.
      final second = AppDatabase(store: store);
      await second.load();
      expect((await second.getAllFoods()).any((f) => f.id == '99'), isFalse);
    });

    test('a fresh install records everything it shipped with', () async {
      final store = FakeSnapshotStore();
      final first = AppDatabase(store: store);
      await first.load();

      await first.deleteFood('54');
      await first.flush();

      final second = AppDatabase(store: store);
      await second.load();
      expect((await second.getAllFoods()).any((f) => f.id == '54'), isFalse,
          reason: 'a food deleted on a fresh install came back on reload');
    });
  });
}
