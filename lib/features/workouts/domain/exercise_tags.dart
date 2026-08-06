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

/// How an exercise loads the body, as data.
///
/// `primaryMuscle` alone cannot program a session. Bench Press and Dumbbell
/// Fly are both "Chest" and are not interchangeable: one is a compound you
/// open the session with, the other an accessory you finish with. The three
/// enums below are what let the generator order a session, choose a rest
/// interval, and decide whether prescribing a load is even meaningful.
///
/// All three follow the same absent-value contract as [Equipment]: an old
/// snapshot or backup written before these existed decodes to the safest
/// value, never an exception. See the codecs at the bottom of this file.

/// The movement pattern an exercise trains.
///
/// Programming covers *patterns*, not muscle names -- a plan with three
/// horizontal pushes and no hinge is badly balanced however the muscle
/// column reads.
enum MovementPattern {
  squat,
  hinge,
  lunge,
  horizontalPush,
  verticalPush,
  horizontalPull,
  verticalPull,
  carry,
  coreBrace,
  /// Single-joint accessory work, and the safe default for anything
  /// untagged: an isolation movement is never chosen to open a session.
  isolation;

  String get key => name;

  static MovementPattern? fromKey(String key) {
    for (final p in MovementPattern.values) {
      if (p.name == key) return p;
    }
    return null;
  }
}

/// Whether an exercise is multi-joint. Drives rest length and session order.
enum Mechanic {
  compound,
  isolation;

  String get key => name;

  static Mechanic? fromKey(String key) {
    for (final m in Mechanic.values) {
      if (m.name == key) return m;
    }
    return null;
  }
}

/// Which strength standard a starting load is derived from.
///
/// [none] means no load is prescribed at all -- bodyweight, band and
/// time-based work, and anything untagged. Failing to [none] is the reason a
/// missing tag can never produce a dangerous prescription.
enum LoadClass {
  squatPattern,
  deadliftPattern,
  benchPattern,
  pressPattern,
  accessory,
  none;

  String get key => name;

  static LoadClass? fromKey(String key) {
    for (final c in LoadClass.values) {
      if (c.name == key) return c;
    }
    return null;
  }
}

abstract final class MovementPatternCodec {
  static String? encode(MovementPattern? value) => value?.key;

  /// Absent or unrecognised decodes to null, which callers read as
  /// [MovementPattern.isolation]. Never throws on an old payload.
  static MovementPattern? decode(Object? raw) =>
      raw is String ? MovementPattern.fromKey(raw) : null;
}

abstract final class MechanicCodec {
  static String? encode(Mechanic? value) => value?.key;

  static Mechanic? decode(Object? raw) =>
      raw is String ? Mechanic.fromKey(raw) : null;
}

abstract final class LoadClassCodec {
  static String? encode(LoadClass? value) => value?.key;

  static LoadClass? decode(Object? raw) =>
      raw is String ? LoadClass.fromKey(raw) : null;
}
