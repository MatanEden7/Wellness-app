import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/template_origin.dart';
import '../data/db/drift_database.dart';
import '../features/workouts/domain/exercise_tags.dart';
import '../features/workouts/domain/models.dart';
import 'profile_fit.dart';
import 'user_profile_service.dart';
import 'workout_programming.dart';
import 'package:wellness_app/services/language_service.dart';

/// Builds workout templates for a profile by **selecting from the seeded
/// exercise library**, not by inventing exercises.
///
/// The previous version minted its own `ExerciseData` rows with the
/// equipment baked into their names ('Barbell Bench Press', 'Dumbbell Bench
/// Press', 'Push-ups') and inserted them alongside the 16 already in the
/// library. That produced near-duplicate entries after onboarding, and left
/// the library itself unfilterable, because "needs a barbell" only existed
/// inside a string. Equipment and injury contraindications are now real
/// fields on [Exercise] and every choice goes through [ProfileFit], so the
/// generator and the browsing UI agree by construction.
class WorkoutTemplateGenerator {
  WorkoutTemplateGenerator(this._database, this._profile, this._language);

  final AppDatabase _database;
  final UserProfile _profile;

  /// The language every template this generator writes is named in.
  ///
  /// Resolved here, once, and written into the row. The template does not
  /// carry a second name to be re-picked later: a plan the user has been
  /// following does not rename itself because they changed the app language,
  /// and the calendar entry pinned to it still says what it said yesterday.
  final AppLanguage _language;

  final _uuid = const Uuid();

  /// Picks the [_language] side of a pair of authored strings.
  String _text(String english, String hebrew) =>
      _language == AppLanguage.hebrew ? hebrew : english;

  /// Muscle groups a session should cover, matched against
  /// `Exercise.primaryMuscle`. Still used for *coverage* accounting, which is
  /// naturally expressed per muscle.
  static const _push = ['Chest', 'Shoulders', 'Triceps'];
  static const _pull = ['Back', 'Biceps'];
  static const _legs = ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves'];
  static const _core = ['Core'];

  /// Every muscle a balanced week should touch.
  static const _allTrained = [..._push, ..._pull, ..._legs, ..._core];

  /// Movement patterns a session is *selected* by.
  ///
  /// Selection by muscle name alone cannot program a session: Bench Press and
  /// Dumbbell Fly are both "Chest" and are not interchangeable -- one opens
  /// the session, the other finishes it. Patterns are what make a plan
  /// balanced, and `mechanic` is what makes the order and the rest correct.
  static const _pushPatterns = [
    MovementPattern.horizontalPush,
    MovementPattern.verticalPush,
  ];
  static const _pullPatterns = [
    MovementPattern.horizontalPull,
    MovementPattern.verticalPull,
  ];
  static const _legPatterns = [
    MovementPattern.squat,
    MovementPattern.hinge,
    MovementPattern.lunge,
  ];
  static const _corePatterns = [MovementPattern.coreBrace];
  static const _allPatterns = [
    ..._legPatterns,
    ..._pushPatterns,
    ..._pullPatterns,
    ..._corePatterns,
  ];

  Future<List<WorkoutTemplateData>> generateTemplates() async {
    final all = await _database.getAllExercises();
    final available = all.where(_fits).toList();
    if (available.isEmpty) {
      debugPrint('[WORKOUT-GEN] No exercises fit this profile; skipping');
      return const [];
    }

    final created = <WorkoutTemplateData>[];

    // One template per training day the user asked for. Previously this
    // produced a fixed 2-3 templates regardless, so someone who said "I
    // train 6 days a week" got three -- the answer was collected and then
    // ignored.
    // The rep scheme, and therefore how many exercises fit in the session.
    // Exercise count is derived rather than fixed: a 4x8 day with real
    // compound rest holds far fewer lifts than a 3x14 one, and a fixed count
    // pushes the heavier scheme straight past an hour.
    final scheme = WorkoutProgramming.schemeFor(_profile.goal);
    final perSession = WorkoutProgramming.exerciseBudget(scheme);

    final plan = _sessionsFor(_profile.trainingDaysPerWeek);
    for (final day in plan) {
      final picks = _pick(available, day.patterns, day.muscles, perSession);
      if (picks.isEmpty) continue;
      created.add(await _write(
        _text(day.name, day.nameHe),
        _text(day.notes, day.notesHe),
        picks,
        scheme: scheme,
      ));
    }

    // Plus a physiotherapy session per reported injury, built from the
    // rehabFor pool rather than "whatever isn't contraindicated" -- being
    // safe with a bad shoulder is not the same as rehabilitating one.
    for (final injury in _profile.injuries) {
      final part = BodyPart.forProfileId(injury);
      if (part == null) continue; // 'none'
      final rehab =
          all.where((e) => e.rehabFor.contains(part) && _fits(e)).toList();
      if (rehab.isEmpty) continue;
      created.add(await _write(
        _text(
          'Physiotherapy — ${part.label(AppLanguage.english)}',
          'פיזיותרפיה — ${part.label(AppLanguage.hebrew)}',
        ),
        _text(
          'Rehab work for your ${part.label(AppLanguage.english).toLowerCase()}. '
              'Low load; safe on a rest day.',
          'עבודת שיקום ל${part.label(AppLanguage.hebrew)}. עומס נמוך; בטוח ליום מנוחה.',
        ),
        rehab.take(5).toList(),
        // Rehab is always programmed as rehab, whatever the training goal:
        // low load, well short of failure. Tissue tolerance, not volume.
        scheme: WorkoutProgramming.schemeFor('mobility_rehab'),
      ));
    }

    _warnOnUncoveredMuscles(created, available);

    debugPrint('[WORKOUT-GEN] Generated ${created.length} templates '
        '(${plan.length} training + ${created.length - plan.length} rehab)');
    return created;
  }

  bool _fits(ExerciseData data) => ProfileFit.exerciseFits(
        Exercise(
          id: data.id,
          name: data.name,
          unit: data.unit,
          primaryMuscle: data.primaryMuscle,
          equipment: data.equipment,
          contraindicatedFor: data.contraindicatedFor,
          rehabFor: data.rehabFor,
        ),
        _profile,
      );

  Future<WorkoutTemplateData> _write(
    String name,
    String notes,
    List<ExerciseData> picks, {
    required RepScheme scheme,
  }) async {
    final template = WorkoutTemplateData(
      id: _uuid.v4(),
      name: name,
      notes: '$notes\n\n${_progressionNote(scheme)}',
      // Marked generated so a later profile change can replace it without
      // touching anything the user built. See ProfileFit.isReplaceable.
      origin: TemplateOrigin.generated,
    );
    await _database.insertWorkoutTemplate(template);

    for (var i = 0; i < picks.length; i++) {
      final exercise = picks[i];
      final mechanic = exercise.mechanicOrDefault;
      final muscle = exercise.primaryMuscle;
      if (muscle != null) _lastPickedMuscles.add(muscle);
      await _database.insertTemplateExercise(TemplateExerciseData(
        id: _uuid.v4(),
        templateId: template.id,
        exerciseId: exercise.id,
        orderIndex: i,
        defaultSets: scheme.sets,
        defaultReps: scheme.reps,
        // Null for anything without an external load -- bodyweight, bands,
        // timed work, or an exercise whose load class is unknown. A missing
        // tag can therefore never produce a dangerous number.
        defaultWeight: WorkoutProgramming.startingWeightKg(
          loadClass: exercise.loadClassOrDefault,
          unit: exercise.unit,
          bodyweightKg: _profile.weightKg,
          sex: _profile.sex,
          experience: _profile.trainingExperience,
          ageYears: _profile.ageYears,
          reps: scheme.reps,
        ),
        defaultRestSeconds: scheme.restFor(mechanic).inSeconds,
      ));
    }
    return template;
  }

  /// Reports any muscle the week never touches, when the catalog had
  /// something to offer for it.
  ///
  /// Coverage is a *weekly* property, not a per-session one -- a push day is
  /// supposed to skip legs. Checking it per session would be meaningless and
  /// checking it not at all is how a plan quietly stops training calves.
  ///
  /// Deliberately a warning rather than a repair: the honest fix for a gap is
  /// more content in the catalog, and silently stuffing an unrelated exercise
  /// into a session to tick a box makes the plan worse, not better.
  void _warnOnUncoveredMuscles(
    List<WorkoutTemplateData> created,
    List<ExerciseData> available,
  ) {
    final offered =
        available.map((e) => e.primaryMuscle).whereType<String>().toSet();

    final trained = <String>{};
    for (final exercise in _lastPickedMuscles) {
      trained.add(exercise);
    }

    for (final muscle in _allTrained) {
      if (!offered.contains(muscle)) continue; // catalog has nothing to pick
      if (trained.contains(muscle)) continue;
      debugPrint('[WORKOUT-GEN] ⚠️  $muscle is never trained this week');
    }
  }

  /// Muscles touched by the sessions written in this run.
  final Set<String> _lastPickedMuscles = <String>{};

  /// The overload rule, written onto the template so it travels with the
  /// plan. Static templates cannot progress by themselves; the user is the
  /// one applying this, so it has to be stated rather than assumed.
  String _progressionNote(RepScheme scheme) => _text(
        'Leave ${scheme.repsInReserve} rep(s) in reserve on every set. '
            'When you hit ${scheme.reps} reps on all ${scheme.sets} sets, add '
            '2.5kg upper body / 5kg lower body next time. '
            'Weights shown are a starting estimate -- adjust on your first set.',
        'השאירו ${scheme.repsInReserve} חזרות במלאי בכל סט. '
            'כשתגיעו ל-${scheme.reps} חזרות בכל ${scheme.sets} הסטים, הוסיפו '
            '2.5 ק"ג בפלג הגוף העליון / 5 ק"ג בתחתון בפעם הבאה. '
            'המשקלים המוצגים הם הערכת פתיחה -- התאימו אותם בסט הראשון.',
      );

  /// Exactly [days] sessions, chosen so that every muscle is trained at
  /// least twice a week wherever the frequency allows.
  ///
  /// Twice-weekly beats once-weekly at matched volume, which is why the split
  /// is chosen by frequency rather than by tradition. The old 5-day
  /// push/pull/legs rotation hit each muscle about 1.67 times a week; at 5
  /// days an upper/lower/push/pull/legs arrangement gets everything twice.
  ///
  /// `goal` deliberately does not pick the split -- it sets the rep scheme,
  /// volume and load in [WorkoutProgramming]. Frequency is a recovery
  /// question, not a goal question.
  List<_SessionPlan> _sessionsFor(int days) {
    final count = days.clamp(1, 7);
    switch (count) {
      case 1:
        return const [
          _SessionPlan(
              'Full Body', 'Everything, once a week', _allPatterns, _allTrained,
              nameHe: 'אימון גוף מלא', notesHe: 'הכול, פעם בשבוע'),
        ];
      case 2:
        return const [
          _SessionPlan(
              'Full Body A', 'Every major pattern', _allPatterns, _allTrained,
              nameHe: 'גוף מלא א', notesHe: 'כל דפוסי התנועה המרכזיים'),
          _SessionPlan('Full Body B', 'Same coverage, different lifts',
              _allPatterns, _allTrained,
              nameHe: 'גוף מלא ב', notesHe: 'אותו כיסוי, תרגילים אחרים'),
        ];
      case 3:
        return const [
          _SessionPlan(
              'Full Body A', 'Every major pattern', _allPatterns, _allTrained,
              nameHe: 'גוף מלא א', notesHe: 'כל דפוסי התנועה המרכזיים'),
          _SessionPlan('Full Body B', 'Same coverage, different lifts',
              _allPatterns, _allTrained,
              nameHe: 'גוף מלא ב', notesHe: 'אותו כיסוי, תרגילים אחרים'),
          _SessionPlan('Full Body C', 'Third variation to keep it fresh',
              _allPatterns, _allTrained,
              nameHe: 'גוף מלא ג', notesHe: 'וריאציה שלישית לשמירה על גיוון'),
        ];
      case 4:
        return const [
          _SessionPlan('Upper Body A', 'Chest, back, shoulders and arms',
              [..._pushPatterns, ..._pullPatterns], [..._push, ..._pull],
              nameHe: 'פלג גוף עליון א', notesHe: 'חזה, גב, כתפיים וידיים'),
          _SessionPlan('Lower Body A', 'Legs and trunk',
              [..._legPatterns, ..._corePatterns], [..._legs, ..._core],
              nameHe: 'פלג גוף תחתון א', notesHe: 'רגליים וליבה'),
          _SessionPlan('Upper Body B', 'Upper body, second variation',
              [..._pullPatterns, ..._pushPatterns], [..._pull, ..._push],
              nameHe: 'פלג גוף עליון ב',
              notesHe: 'פלג גוף עליון, וריאציה שנייה'),
          _SessionPlan('Lower Body B', 'Lower body, second variation',
              [..._legPatterns, ..._corePatterns], [..._legs, ..._core],
              nameHe: 'פלג גוף תחתון ב',
              notesHe: 'פלג גוף תחתון, וריאציה שנייה'),
        ];
      case 5:
        return const [
          _SessionPlan('Upper Body', 'Chest, back, shoulders and arms',
              [..._pushPatterns, ..._pullPatterns], [..._push, ..._pull],
              nameHe: 'פלג גוף עליון', notesHe: 'חזה, גב, כתפיים וידיים'),
          _SessionPlan('Lower Body', 'Legs and trunk',
              [..._legPatterns, ..._corePatterns], [..._legs, ..._core],
              nameHe: 'פלג גוף תחתון', notesHe: 'רגליים וליבה'),
          _SessionPlan(
              'Push Day', 'Chest, shoulders and triceps', _pushPatterns, _push,
              nameHe: 'אימון דחיפה', notesHe: 'חזה, כתפיים ותלת-ראשי'),
          _SessionPlan('Pull Day', 'Back and biceps', _pullPatterns, _pull,
              nameHe: 'אימון משיכה', notesHe: 'גב ודו-ראשי'),
          _SessionPlan('Leg Day', 'Quads, hamstrings, glutes and trunk',
              [..._legPatterns, ..._corePatterns], [..._legs, ..._core],
              nameHe: 'אימון רגליים',
              notesHe: 'ארבע-ראשי, ירך אחורית, ישבן וליבה'),
        ];
      case 6:
        return const [
          _SessionPlan('Push Day A', 'Chest, shoulders and triceps',
              _pushPatterns, _push,
              nameHe: 'אימון דחיפה א', notesHe: 'חזה, כתפיים ותלת-ראשי'),
          _SessionPlan('Pull Day A', 'Back and biceps', _pullPatterns, _pull,
              nameHe: 'אימון משיכה א', notesHe: 'גב ודו-ראשי'),
          _SessionPlan('Leg Day A', 'Quads, hamstrings, glutes and trunk',
              [..._legPatterns, ..._corePatterns], [..._legs, ..._core],
              nameHe: 'אימון רגליים א',
              notesHe: 'ארבע-ראשי, ירך אחורית, ישבן וליבה'),
          _SessionPlan(
              'Push Day B', 'Push, second variation', _pushPatterns, _push,
              nameHe: 'אימון דחיפה ב', notesHe: 'דחיפה, וריאציה שנייה'),
          _SessionPlan(
              'Pull Day B', 'Pull, second variation', _pullPatterns, _pull,
              nameHe: 'אימון משיכה ב', notesHe: 'משיכה, וריאציה שנייה'),
          _SessionPlan('Leg Day B', 'Legs, second variation',
              [..._legPatterns, ..._corePatterns], [..._legs, ..._core],
              nameHe: 'אימון רגליים ב', notesHe: 'רגליים, וריאציה שנייה'),
        ];
      default:
        return const [
          _SessionPlan('Push Day A', 'Chest, shoulders and triceps',
              _pushPatterns, _push,
              nameHe: 'אימון דחיפה א', notesHe: 'חזה, כתפיים ותלת-ראשי'),
          _SessionPlan('Pull Day A', 'Back and biceps', _pullPatterns, _pull,
              nameHe: 'אימון משיכה א', notesHe: 'גב ודו-ראשי'),
          _SessionPlan('Leg Day A', 'Quads, hamstrings, glutes and trunk',
              [..._legPatterns, ..._corePatterns], [..._legs, ..._core],
              nameHe: 'אימון רגליים א',
              notesHe: 'ארבע-ראשי, ירך אחורית, ישבן וליבה'),
          _SessionPlan(
              'Push Day B', 'Push, second variation', _pushPatterns, _push,
              nameHe: 'אימון דחיפה ב', notesHe: 'דחיפה, וריאציה שנייה'),
          _SessionPlan(
              'Pull Day B', 'Pull, second variation', _pullPatterns, _pull,
              nameHe: 'אימון משיכה ב', notesHe: 'משיכה, וריאציה שנייה'),
          _SessionPlan('Leg Day B', 'Legs, second variation',
              [..._legPatterns, ..._corePatterns], [..._legs, ..._core],
              nameHe: 'אימון רגליים ב', notesHe: 'רגליים, וריאציה שנייה'),
          _SessionPlan('Mobility & Core', 'Light trunk and mobility work',
              _corePatterns, _core,
              nameHe: 'ניידות וליבה', notesHe: 'עבודת ליבה וניידות קלה'),
        ];
    }
  }

  /// Picks up to [count] exercises across [patterns], compounds first and one
  /// pattern at a time before doubling up on any of them.
  ///
  /// Round-robin over patterns is what stops a session becoming four chest
  /// movements simply because chest has the most options. Compounds are taken
  /// in the first pass so that a short session is built from the lifts that
  /// carry the most work, not from whatever happened to sort first.
  List<ExerciseData> _pick(
    List<ExerciseData> available,
    List<MovementPattern> patterns,
    List<String> muscles,
    int count,
  ) {
    /// Exercises matching a pattern and mechanic, progressable ones first.
    ///
    /// A loaded lift beats its bodyweight cousin when the user owns the kit:
    /// the progression rule on every template is "add 2.5kg when you hit the
    /// top of the range", and you cannot add 2.5kg to a push-up. Without this
    /// an intermediate with a barbell rack was prescribed Push-ups purely
    /// because it sorts first in the catalog.
    List<ExerciseData> ofPattern(MovementPattern p, Mechanic m) {
      final matches = available
          .where((e) => e.pattern == p && e.mechanicOrDefault == m)
          .toList();
      matches.sort((a, b) {
        final aLoadable = a.unit == 'kg' ? 0 : 1;
        final bLoadable = b.unit == 'kg' ? 0 : 1;
        return aLoadable.compareTo(bLoadable);
      });
      return matches;
    }

    final picked = <ExerciseData>[];

    List<ExerciseData> isolationFor(String muscle) {
      final matches = available
          .where((e) =>
              e.mechanicOrDefault == Mechanic.isolation &&
              e.primaryMuscle == muscle)
          .toList();
      matches.sort(
          (a, b) => (a.unit == 'kg' ? 0 : 1).compareTo(b.unit == 'kg' ? 0 : 1));
      return matches;
    }

    /// Takes at most one exercise per pattern at depth [round].
    ///
    /// Breadth before depth is the important part. Going deep first fills a
    /// session with near-duplicates -- Bench Press *and* Push-ups, Squats
    /// *and* Bodyweight Squat, Deadlift *and* Romanian Deadlift -- which no
    /// coach would program together and which leaves whole patterns and all
    /// the isolation work untouched.
    void takeCompoundRound(int round) {
      for (final pattern in patterns) {
        if (picked.length >= count) return;
        final options = ofPattern(pattern, Mechanic.compound);
        if (round < options.length && !picked.contains(options[round])) {
          picked.add(options[round]);
        }
      }
    }

    void takeIsolationRound(int round) {
      for (final muscle in muscles) {
        if (picked.length >= count) return;
        final options = isolationFor(muscle);
        if (round < options.length && !picked.contains(options[round])) {
          picked.add(options[round]);
        }
      }
    }

    // One compound per pattern, then one isolation per pattern. That covers
    // the session's patterns broadly and gets accessory work into the plan at
    // all, which a compounds-first-until-full pass never does.
    takeCompoundRound(0);
    takeIsolationRound(0);

    // Only then go deeper, still alternating so depth accrues evenly.
    for (var round = 1; round < 4 && picked.length < count; round++) {
      takeCompoundRound(round);
      takeIsolationRound(round);
    }

    // Backfill. When most of a pattern is contraindicated -- a shoulder
    // injury guts every push -- the loops above return two exercises and call
    // it a session. Top up from anything else available so the user still
    // gets a workout worth doing.
    if (picked.length < count) {
      for (final exercise in available) {
        if (picked.length >= count) break;
        if (!picked.contains(exercise)) picked.add(exercise);
      }
    }

    // Session order: heaviest compounds first, trunk last. Fatigue ruins
    // technique on exactly the lifts where technique matters most.
    picked.sort((a, b) =>
        WorkoutProgramming.orderRank(a.pattern, a.mechanicOrDefault).compareTo(
            WorkoutProgramming.orderRank(b.pattern, b.mechanicOrDefault)));
    return picked;
  }
}

class _SessionPlan {
  const _SessionPlan(
    this.name,
    this.notes,
    this.patterns,
    this.muscles, {
    required this.nameHe,
    required this.notesHe,
  });

  final String name;
  final String notes;

  /// The Hebrew side of [name] / [notes].
  ///
  /// Both languages are authored here, next to each other, because that is
  /// the readable place to keep a translation honest. Only one of them is
  /// ever written to a template -- the generator picks at write time and the
  /// row keeps a single name. Required rather than nullable: a session plan
  /// without Hebrew would silently emit an English template into a Hebrew
  /// plan, which is exactly the mixed-language result this refactor removes.
  final String nameHe;
  final String notesHe;

  /// Muscles this session's accessory work may target.
  ///
  /// Compounds are chosen by movement pattern, but isolation work is not a
  /// pattern -- a bicep curl and a lateral raise are both
  /// `MovementPattern.isolation`, and only the muscle says which one belongs
  /// on a pull day. Selecting accessories by pattern put three horizontal
  /// pushes on push day and never reached the arms at all.
  final List<String> muscles;

  /// Movement patterns this session draws from. Exercise *count* is not
  /// stored here -- it is derived from the goal's rep scheme and the time
  /// budget, because a 4x8 session with real compound rest fits far fewer
  /// exercises than a 3x14 one.
  final List<MovementPattern> patterns;
}
