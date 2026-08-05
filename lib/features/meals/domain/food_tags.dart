/// What a food *contains*, as data rather than as a guess about its name.
///
/// This exists because the profile collects diet type and exclusions during
/// onboarding, but nothing on [FoodItem] could answer "does this contain
/// dairy?". `MealTemplateGenerator` approximated it with hardcoded English
/// name lists (`['Greek Yogurt', 'Cottage Cheese', 'Milk', 'Butter']`), which
/// missed every food the user added, never matched a Hebrew name, and broke
/// silently whenever the catalog grew.
///
/// One tag set covers both questions the profile asks:
///
///  * **Exclusions** map 1:1 onto the allergen tags ([dairy], [gluten],
///    [nuts], [eggs], [shellfish], [soy]) -- the same six the onboarding
///    chips offer.
///  * **Diet type** is derived from the animal-origin tags: [meat], [fish]
///    and [animalProduct]. A food with none of them is plant-only.
///
/// [animalProduct] is deliberately separate from [meat]/[fish]: eggs, dairy
/// and honey come from an animal without being one, which is exactly the
/// distinction a herbivore diet needs and a carnivore diet does not.
enum FoodTag {
  // Allergens / exclusions -- these mirror the onboarding exclusion chips.
  dairy,
  gluten,
  nuts,
  eggs,
  shellfish,
  soy,

  // Animal origin -- these drive diet-type fitness.
  /// Land-animal flesh (beef, chicken, pork, lamb).
  meat,

  /// Fish and other seafood flesh. Kept apart from [meat] because
  /// pescatarian-style eating is a predictable future addition, and because
  /// [shellfish] is an allergen while "fish" is not.
  fish,

  /// From an animal but not its flesh -- eggs, dairy, honey.
  animalProduct;

  /// The stable string written to JSON. Uses the enum name so the snapshot
  /// and export payloads stay readable, and so an unrecognised value can be
  /// dropped rather than crashing an import.
  String get key => name;

  static FoodTag? fromKey(String key) {
    for (final tag in FoodTag.values) {
      if (tag.name == key) return tag;
    }
    // Unknown tag -- most likely a newer export opened by an older build.
    // Dropping it degrades filtering rather than failing the whole import.
    return null;
  }

  /// The exclusion id (as stored on `UserProfile.exclusions`) this tag
  /// corresponds to, or null for the animal-origin tags, which exclusions
  /// don't cover.
  String? get exclusionId {
    switch (this) {
      case FoodTag.dairy:
        return 'dairy';
      case FoodTag.gluten:
        return 'gluten';
      case FoodTag.nuts:
        return 'nuts';
      case FoodTag.eggs:
        return 'eggs';
      case FoodTag.shellfish:
        return 'shellfish';
      case FoodTag.soy:
        return 'soy';
      case FoodTag.meat:
      case FoodTag.fish:
      case FoodTag.animalProduct:
        return null;
    }
  }

  /// The tag an exclusion id refers to, or null if it isn't an allergen
  /// exclusion (e.g. the 'none' chip).
  static FoodTag? forExclusion(String exclusionId) {
    for (final tag in FoodTag.values) {
      if (tag.exclusionId == exclusionId) return tag;
    }
    return null;
  }
}

/// Encoding helpers shared by the domain model and the DB row, so both sides
/// serialize tags identically.
abstract final class FoodTagCodec {
  static List<String> encode(Set<FoodTag> tags) {
    // Sorted so the JSON snapshot is stable and diffs stay readable.
    final keys = tags.map((t) => t.key).toList()..sort();
    return keys;
  }

  /// Tolerates a missing or malformed value: rows written before tags
  /// existed simply have no key, and must decode to "untagged" rather than
  /// blowing up the whole snapshot load.
  static Set<FoodTag> decode(Object? raw) {
    if (raw is! List) return <FoodTag>{};
    return raw
        .whereType<String>()
        .map(FoodTag.fromKey)
        .whereType<FoodTag>()
        .toSet();
  }
}

/// Human-readable label for a tag.
///
/// English-only for now, matching how the seeded catalog ships: the
/// exclusion chips in onboarding already have Hebrew, but wiring those keys
/// through here needs the l10n lookup, and these six strings are the same
/// words. Left as a single place to localise later rather than scattered
/// through the editors.
extension FoodTagLabel on FoodTag {
  String get label {
    switch (this) {
      case FoodTag.dairy:
        return 'Dairy';
      case FoodTag.gluten:
        return 'Gluten';
      case FoodTag.nuts:
        return 'Nuts';
      case FoodTag.eggs:
        return 'Eggs';
      case FoodTag.shellfish:
        return 'Shellfish';
      case FoodTag.soy:
        return 'Soy';
      case FoodTag.meat:
        return 'Meat';
      case FoodTag.fish:
        return 'Fish';
      case FoodTag.animalProduct:
        return 'Animal product';
    }
  }

  /// Tags that answer "what allergen does this contain?".
  static const allergens = [
    FoodTag.dairy,
    FoodTag.gluten,
    FoodTag.nuts,
    FoodTag.eggs,
    FoodTag.shellfish,
    FoodTag.soy,
  ];

  /// Tags that answer "does this come from an animal?".
  static const animalOrigin = [
    FoodTag.meat,
    FoodTag.fish,
    FoodTag.animalProduct,
  ];
}
