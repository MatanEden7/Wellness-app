/// How long to rest between sets, resolved in one place.
///
/// Rest used to be answered three different ways depending on who asked:
///
///   * `TemplateExerciseData.restSeconds` implemented a rep-based ladder --
///     and nothing ever called it, because the repository mapped the raw
///     `defaultRestSeconds` field straight through.
///   * The session page went `defaultRestSeconds ?? prefs.defaultRestTime`,
///     skipping the ladder entirely, so any exercise without an explicit rest
///     got a flat 90s whether it was a 5-rep squat or a 20-rep raise.
///   * `SetEntry.restSeconds` existed on the model, the row and the JSON, and
///     was never written by anyone.
///
/// Everything now goes through [resolveRestSeconds], so there is exactly one
/// answer to "how long is the rest here".
library;

/// Rest presets offered in the pickers, in seconds.
///
/// Deliberately short: a long list of near-identical durations is harder to
/// choose from than four clearly different ones, and anything else is
/// reachable through the custom field.
const restPresets = <int>[60, 90, 120, 180];

/// Rest derived from the prescribed rep count, when nothing more specific is
/// known.
///
/// Fewer reps means heavier work and a longer recovery; high-rep work is
/// metabolic and needs far less. This is the ladder that already existed in
/// the data layer but was never reachable.
int restSecondsForReps(int reps) {
  if (reps <= 5) return 180;
  if (reps <= 8) return 120;
  if (reps <= 12) return 90;
  return 60;
}

/// The rest to use for a set, most specific source first.
///
/// 1. [explicitSeconds] -- what the user set for this exercise, on the
///    template. Always wins; null means "never set", not "zero".
/// 2. [reps] -- the rep-based ladder, so a heavy compound and a light
///    isolation don't get the same rest by default.
/// 3. [globalDefaultSeconds] -- the Workout Settings slider, the last resort
///    when there is no rep count to reason from either.
int resolveRestSeconds({
  int? explicitSeconds,
  int? reps,
  required int globalDefaultSeconds,
}) {
  if (explicitSeconds != null && explicitSeconds > 0) return explicitSeconds;
  if (reps != null && reps > 0) return restSecondsForReps(reps);
  return globalDefaultSeconds;
}

/// `2:30`-style label for a duration in seconds.
String formatRest(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}
