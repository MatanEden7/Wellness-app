import '../core/template_origin.dart';
import '../features/meals/domain/food_tags.dart';
import '../features/meals/domain/models.dart';
import '../features/workouts/domain/exercise_tags.dart';
import '../features/workouts/domain/models.dart';
import 'user_profile_service.dart';

/// Why a piece of content does not fit the user's profile.
///
/// Carried rather than just a bool so the UI can say *what* is wrong
/// ("contains dairy", "needs a barbell") instead of silently hiding things,
/// which is the difference between the app feeling tailored and feeling
/// broken.
enum FitFailure {
  /// Conflicts with the user's diet type (omnivore / carnivore / herbivore).
  diet,

  /// Contains something on the user's exclusion list.
  exclusion,

  /// Requires equipment the user does not have.
  equipment,

  /// Unsafe for one of the user's injuries.
  injury,
}

/// The result of a fitness check: whether it fits, and if not, why.
class FitResult {
  const FitResult.fits()
      : failure = null,
        detail = null;

  const FitResult.fails(this.failure, this.detail);

  final FitFailure? failure;

  /// The specific thing that caused the failure -- a [FoodTag], [Equipment]
  /// or [BodyPart]. Kept as the enum rather than a formatted string so the
  /// UI owns localization; `ProfileFit` stays free of l10n dependencies and
  /// therefore stays unit-testable without a widget tree.
  final Object? detail;

  bool get fits => failure == null;
}

/// The single source of truth for "does this content suit this user?".
///
/// Onboarding collects diet type, exclusions, equipment and injuries, but
/// before this existed nothing could actually *answer* the question:
/// `MealTemplateGenerator` approximated it with hardcoded English food-name
/// lists, and `WorkoutTemplateGenerator` sidestepped it by minting its own
/// exercises with equipment baked into their names. Both went stale the
/// moment the catalog changed, and neither helped the browsing UI at all.
///
/// This plays the same role for profile matching that `FoodNutritionMath`
/// plays for unit conversion -- one module every caller goes through, so a
/// rule change lands everywhere at once. Do not re-implement these checks
/// anywhere else.
///
/// **Untagged content always fits.** A food or exercise with no tags is
/// treated as compatible with every profile rather than incompatible with
/// all of them. Anything else would make a user's own un-labelled entries
/// vanish from their catalog, which reads as data loss.
abstract final class ProfileFit {
  // ---------------------------------------------------------------- foods

  static FitResult foodFit(FoodItem food, UserProfile profile) {
    if (food.tags.isEmpty) return const FitResult.fits();

    // Diet type first: it is the broader statement, so "you don't eat meat"
    // is a more useful reason than "this contains dairy" for a steak.
    final dietFailure = _dietFailure(food.tags, profile.dietType);
    if (dietFailure != null) {
      return FitResult.fails(FitFailure.diet, dietFailure);
    }

    for (final exclusion in profile.exclusions) {
      final tag = FoodTag.forExclusion(exclusion);
      if (tag != null && food.tags.contains(tag)) {
        return FitResult.fails(FitFailure.exclusion, tag);
      }
    }

    return const FitResult.fits();
  }

  static bool foodFits(FoodItem food, UserProfile profile) =>
      foodFit(food, profile).fits;

  /// Which animal-origin tag (if any) rules this food out for [dietType].
  ///
  /// - `herbivore` rejects anything of animal origin, flesh or not.
  /// - `carnivore` rejects nothing here: it is a statement about what the
  ///   user *does* eat, and plant foods are not unsafe for them. Filtering
  ///   the catalog down to meat only would hide the vegetables they cook
  ///   with, which is a worse outcome than showing a few extras.
  /// - `omnivore` rejects nothing.
  static FoodTag? _dietFailure(Set<FoodTag> tags, String dietType) {
    if (dietType != 'herbivore') return null;
    for (final tag in const [
      FoodTag.meat,
      FoodTag.fish,
      FoodTag.animalProduct
    ]) {
      if (tags.contains(tag)) return tag;
    }
    return null;
  }

  // ------------------------------------------------------------ exercises

  static FitResult exerciseFit(Exercise exercise, UserProfile profile) {
    for (final injury in profile.injuries) {
      final part = BodyPart.forProfileId(injury);
      if (part != null && exercise.contraindicatedFor.contains(part)) {
        return FitResult.fails(FitFailure.injury, part);
      }
    }

    if (exercise.equipment.isEmpty) return const FitResult.fits();

    // Bodyweight work needs nothing, so it is always available regardless of
    // what the user owns.
    if (exercise.equipment.contains(Equipment.bodyweight)) {
      return const FitResult.fits();
    }

    final owned = _ownedEquipment(profile);
    // An exercise lists every piece of kit it *could* be done with, so it
    // fits as long as the user has any one of them.
    final match = exercise.equipment.any(owned.contains);
    if (!match) {
      return FitResult.fails(FitFailure.equipment, exercise.equipment.first);
    }

    return const FitResult.fits();
  }

  static bool exerciseFits(Exercise exercise, UserProfile profile) =>
      exerciseFit(exercise, profile).fits;

  static Set<Equipment> _ownedEquipment(UserProfile profile) {
    final owned = <Equipment>{Equipment.bodyweight};
    for (final id in profile.equipment) {
      final equipment = Equipment.forProfileId(id);
      // 'none' maps to bodyweight, which is already present -- selecting it
      // means "I have no equipment", not "I own a bodyweight".
      if (equipment != null) owned.add(equipment);
    }
    return owned;
  }

  // ------------------------------------------------------------ templates

  /// A meal template fits only if **every** food in it fits.
  ///
  /// Partial fitness isn't useful here: a recipe you can't eat one third of
  /// isn't a recipe you can cook. The first failing item is reported so the
  /// UI can name it.
  ///
  /// [foodsById] is passed in rather than fetched so this stays synchronous
  /// and side-effect free -- callers already hold the food list, and a
  /// per-item DB read inside a list builder would be pathological.
  static FitResult mealTemplateFit(
    MealTemplate template,
    Map<String, FoodItem> foodsById,
    UserProfile profile,
  ) {
    for (final item in template.items) {
      final food = foodsById[item.foodId];
      // A dangling foodId can't be judged; treat it as fitting rather than
      // hiding the whole template over a referential-integrity problem.
      if (food == null) continue;
      final result = foodFit(food, profile);
      if (!result.fits) return result;
    }
    return const FitResult.fits();
  }

  static bool mealTemplateFits(
    MealTemplate template,
    Map<String, FoodItem> foodsById,
    UserProfile profile,
  ) =>
      mealTemplateFit(template, foodsById, profile).fits;

  /// A workout template fits only if every exercise in it fits.
  static FitResult workoutTemplateFit(
    WorkoutTemplate template,
    Map<String, Exercise> exercisesById,
    UserProfile profile,
  ) {
    for (final templateExercise in template.exercises) {
      final exercise = exercisesById[templateExercise.exerciseId];
      if (exercise == null) continue;
      final result = exerciseFit(exercise, profile);
      if (!result.fits) return result;
    }
    return const FitResult.fits();
  }

  static bool workoutTemplateFits(
    WorkoutTemplate template,
    Map<String, Exercise> exercisesById,
    UserProfile profile,
  ) =>
      workoutTemplateFit(template, exercisesById, profile).fits;

  // ----------------------------------------------------------- regenerate

  /// The profile fields that change *which content suits the user*, as
  /// opposed to the ones that only change target numbers.
  ///
  /// Per the product decision, `goal` is deliberately absent: it drives
  /// calories and macros only, not template selection. Weight, height, age
  /// and activity level are likewise target-only.
  static bool contentAffectingFieldsChanged(
          UserProfile before, UserProfile after) =>
      before.dietType != after.dietType ||
      !_sameSet(before.exclusions, after.exclusions) ||
      !_sameSet(before.equipment, after.equipment) ||
      !_sameSet(before.injuries, after.injuries) ||
      before.trainingDaysPerWeek != after.trainingDaysPerWeek ||
      // Experience sets every prescribed load and the volume a plan targets,
      // so changing it makes the existing templates wrong in a way the user
      // can feel on the first set.
      before.trainingExperience != after.trainingExperience ||
      before.mealCountPerDay != after.mealCountPerDay;

  static bool _sameSet(List<String> a, List<String> b) =>
      a.toSet().difference(b.toSet()).isEmpty &&
      b.toSet().difference(a.toSet()).isEmpty;

  /// Whether regeneration is allowed to replace this template.
  ///
  /// Only generated content is ever replaced -- anything the user made or
  /// edited is theirs.
  static bool isReplaceable(TemplateOrigin origin) =>
      origin == TemplateOrigin.generated;
}
