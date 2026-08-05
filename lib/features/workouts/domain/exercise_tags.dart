/// What an exercise *needs* and who it's unsafe for, as data.
///
/// Same reasoning as `FoodTag`: onboarding collects equipment and injuries,
/// but nothing on [Exercise] could answer "can I do this with only bands?"
/// or "is this safe with a bad shoulder?". `WorkoutTemplateGenerator`
/// worked around it by *minting its own* exercises with equipment baked into
/// their names ('Barbell Bench Press', 'Dumbbell Bench Press'), which
/// duplicated the seeded library and left the library itself unfilterable.
library;

/// Equipment an exercise requires. Values mirror the onboarding equipment
/// chips exactly, plus [bodyweight] for the "no equipment" case -- the chip
/// for that is `none`, but an exercise still positively *requires* nothing,
/// which is a different statement from "the user owns nothing".
enum Equipment {
  bodyweight,
  dumbbells,
  barbellRack,
  machines,
  bands,
  kettlebells,
  cable,
  pullupBar;

  String get key => name;

  static Equipment? fromKey(String key) {
    for (final e in Equipment.values) {
      if (e.name == key) return e;
    }
    return null;
  }

  /// The equipment id as stored on `UserProfile.equipment`. Those ids are
  /// snake_case ('barbell_rack', 'pullup_bar') while the enum is lowerCamel,
  /// so the mapping is explicit rather than a name comparison.
  String get profileId {
    switch (this) {
      case Equipment.bodyweight:
        return 'none';
      case Equipment.dumbbells:
        return 'dumbbells';
      case Equipment.barbellRack:
        return 'barbell_rack';
      case Equipment.machines:
        return 'machines';
      case Equipment.bands:
        return 'bands';
      case Equipment.kettlebells:
        return 'kettlebells';
      case Equipment.cable:
        return 'cable';
      case Equipment.pullupBar:
        return 'pullup_bar';
    }
  }

  static Equipment? forProfileId(String id) {
    for (final e in Equipment.values) {
      if (e.profileId == id) return e;
    }
    return null;
  }
}

/// Body parts an injury can affect. Mirrors the onboarding injury chips.
///
/// [neck] was added after the initial set: heavy axial loading and overhead
/// work are a well-documented aggravator of cervical strain, and several
/// seeded exercises (overhead press, back squat, deadlift) fall squarely in
/// that category, so it needed to be expressible.
enum BodyPart {
  shoulder,
  back,
  knee,
  ankle,
  elbow,
  hip,
  neck;

  String get key => name;

  static BodyPart? fromKey(String key) {
    for (final p in BodyPart.values) {
      if (p.name == key) return p;
    }
    return null;
  }

  /// The injury id as stored on `UserProfile.injuries` -- these happen to
  /// match the enum names, but go through an explicit accessor so a future
  /// rename can't silently break profile matching.
  String get profileId => name;

  static BodyPart? forProfileId(String id) => fromKey(id);
}

abstract final class EquipmentCodec {
  static List<String> encode(Set<Equipment> value) {
    final keys = value.map((e) => e.key).toList()..sort();
    return keys;
  }

  static Set<Equipment> decode(Object? raw) {
    if (raw is! List) return <Equipment>{};
    return raw
        .whereType<String>()
        .map(Equipment.fromKey)
        .whereType<Equipment>()
        .toSet();
  }
}

/// Exercises that are *therapeutic* for a body part, as opposed to unsafe
/// for it.
///
/// Deliberately a separate axis from `contraindicatedFor`: a glute bridge is
/// both safe with a bad back *and* actively part of rehabbing one, while a
/// bodyweight squat is merely safe. Only the second kind belongs in a
/// physiotherapy session, and without this distinction the generator would
/// have to guess by exclusion -- "not contraindicated" is a very weak proxy
/// for "will help you recover".
abstract final class BodyPartCodec {
  static List<String> encode(Set<BodyPart> value) {
    final keys = value.map((e) => e.key).toList()..sort();
    return keys;
  }

  static Set<BodyPart> decode(Object? raw) {
    if (raw is! List) return <BodyPart>{};
    return raw
        .whereType<String>()
        .map(BodyPart.fromKey)
        .whereType<BodyPart>()
        .toSet();
  }
}

extension EquipmentLabel on Equipment {
  String get label {
    switch (this) {
      case Equipment.bodyweight:
        return 'Bodyweight';
      case Equipment.dumbbells:
        return 'Dumbbells';
      case Equipment.barbellRack:
        return 'Barbell & rack';
      case Equipment.machines:
        return 'Machines';
      case Equipment.bands:
        return 'Bands';
      case Equipment.kettlebells:
        return 'Kettlebells';
      case Equipment.cable:
        return 'Cable';
      case Equipment.pullupBar:
        return 'Pull-up bar';
    }
  }
}

extension BodyPartLabel on BodyPart {
  String get label {
    switch (this) {
      case BodyPart.shoulder:
        return 'Shoulder';
      case BodyPart.back:
        return 'Back';
      case BodyPart.knee:
        return 'Knee';
      case BodyPart.ankle:
        return 'Ankle';
      case BodyPart.elbow:
        return 'Elbow';
      case BodyPart.hip:
        return 'Hip';
      case BodyPart.neck:
        return 'Neck';
    }
  }
}
