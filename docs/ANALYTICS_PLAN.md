# Analytics Page — Architecture Plan

Status: **implemented, 2026-08-07.** Kept as the design record for the feature;
the living description is in `docs/REPO_GUIDE.md` under "Analytics". This
superseded the "out of scope" line in `docs/ROADMAP.md` for *weight history* and
*workout PR/progression analytics* — an analytics page that can answer "am I
progressing?" cannot be built without both.

Built as planned, with four decisions taken while building rather than asked:

| Decision | Chosen |
|---|---|
| Entry point | `/analytics` from the dashboard header. The bottom bar already carries five destinations; a sixth wraps every label at 393pt. |
| Calorie scoring | Goal-dependent, not a flat band. `fat_loss` counts under target as met (with a floor), `muscle_gain` wants it met or beaten, everything else is ±10%. A flat band marks a cutting user's best day as a failure. |
| Weight log scope | Weight only. Waist/body-fat stay out of scope. |
| Default range | Month. |

One addition not in the plan below: rest days count toward the training goal once
the week's target is already met, so a perfect week is possible for someone who
does not train daily.

---

## 1. What the page has to answer

The user's ask, restated as questions the screen must answer at a glance:

| Question | Data it needs | Where it lives today |
|---|---|---|
| Am I hitting all my goals, together, over time? | daily goal pass/fail across nutrition + training + sleep | goals: `PreferencesService`, `UserProfile`; actuals: 3 repos |
| Am I stuck on the same weight? | per-exercise top-set weight / e1RM series | `SetEntry` (exists, never queried by range) |
| Am I progressing? | volume, e1RM, body weight, adherence trend lines | volume/e1RM derivable; **body weight has no history** |
| What changed recently? | week-over-week deltas, plateau/PR/regression detection | nothing exists |

---

## 2. What is missing in the data layer

Four real gaps, in the order they block work:

1. **No range queries anywhere.** `watchMealsByDate(int date)` is one day.
   `getRecentWorkoutSessions({limit})` and `getRecentSleepEntries({limit})` are
   count-capped, not date-bounded. Analytics over 90 days must not issue 90
   single-day calls — that is 90 rebuilds of a stream chain that already
   re-reads every meal item each time.
   → add `getMealsInRange`, `getWorkoutSessionsInRange`, `getSleepEntriesInRange`
   to `AppDatabase`, and matching `watch…InRange` on the repositories.

2. **No body-weight history.** `UserProfile.weightKg` is a single scalar that
   onboarding writes and the calorie formula reads. A weight *trend* needs a new
   collection. This is the only new entity the plan introduces.

3. **No sleep goal and no explicit weekly-training goal.**
   `UserProfile.trainingDaysPerWeek` can serve as the training target as-is.
   Sleep needs a `sleepGoalHours` preference (default 8.0) — cheap, one
   `PreferencesService` getter/setter pair.

4. **In-progress sessions are indistinguishable in aggregates.**
   `WorkoutSession.endedAt == null` means "still running". Every analytics
   aggregate must filter on `isCompleted`, or an abandoned session logs as a
   zero-volume training day and corrupts the streak.

Non-gap, worth stating: **denormalized `MealItem` nutrition is correct here.**
History should show what was true when logged, not what the food catalog says
today. The known "stale nutrition" issue is a *feature* for this screen.

---

## 3. Layering

Mirrors `workout_programming.dart` — the judgement lives in pure functions with
no Flutter and no DB, so it is testable in the fast `test/` suite without
constructing an app.

```
lib/features/analytics/
├── domain/
│   ├── analytics_range.dart      # DateRange + Bucket(day|week|month) + bucketing
│   ├── series.dart               # TimeSeriesPoint, MetricSeries, trend/EMA/delta math
│   ├── aggregators.dart          # raw entities -> MetricSeries  (PURE)
│   ├── goal_scoring.dart         # daily goal pass/fail -> GoalDay, streaks (PURE)
│   ├── strength_progress.dart    # top set, e1RM (Epley), plateau detection (PURE)
│   └── insights.dart             # InsightRule list -> List<Insight>  (PURE)
├── data/
│   ├── analytics_repository.dart # the only place that touches AppDatabase
│   └── providers.dart            # one memoized snapshot provider per range
└── ui/
    ├── analytics_page.dart
    ├── sections/                 # one widget per card
    └── charts/                   # CustomPainter primitives
```

### Dataflow

```
range selector (W / M / 6M / Y)
   ↓
analyticsSnapshotProvider(range)        <- FutureProvider.family, autoDispose+keepAlive
   ↓  (rebuilds only when a repo stream ticks, not per widget build)
AnalyticsRepository.load(range)          <- ONE pass, 3 range queries
   ↓
AnalyticsSnapshot { meals[], sessions[], sleep[], weights[], goals }
   ↓  pure aggregators
AnalyticsView {
  goalDays[], calories, macros, volume, sessionCount,
  strength{exerciseId -> series}, bodyWeight, sleepHours, insights[]
}
   ↓
sections read slices of AnalyticsView — no section queries anything itself
```

**One provider, one pass.** The documented repo antipattern (`ref.watch(repo).watchX()`
inside `build()`, ~15 screens) must not be repeated here — with 6 chart sections it
would mean 6 stream rebuilds per frame over the whole history.

Cost is fine: the DB is in-memory lists. 365 days of data is a few thousand objects;
one full aggregation pass is sub-millisecond. Correctness risk is recomputation
frequency, not compute — hence memoization on `(range, dataVersion)`.

---

## 4. Screen layout

iOS-native structure: large title, a pinned segmented range control, then a single
scrolling column of cards. `UIConstants` already sets the grammar
(20pt side padding, 16pt radius, 12pt card gap, 24pt section gap) — reuse it, do
not invent a second spacing scale.

```
┌─────────────────────────────────┐
│  Analytics                 [⌄]  │  large title
│  ┌───────────────────────────┐  │
│  │  W  │  M  │  6M  │  Y     │  │  pinned segmented control
│  └───────────────────────────┘  │
├─────────────────────────────────┤
│ ▸ 1. GOALS TOGETHER   (hero)    │  ← "all goals reached together"
│ ▸ 2. NUTRITION                  │
│ ▸ 3. TRAINING                   │
│ ▸ 4. STRENGTH / PLATEAU         │  ← "same weight for a while"
│ ▸ 5. BODY WEIGHT                │
│ ▸ 6. SLEEP                      │
│ ▸ 7. INSIGHTS                   │
└─────────────────────────────────┘
```

### 1 — Goals Together (hero, top)

The single chart that combines every goal. Per day, four goals each worth 25%:

| Goal | Met when |
|---|---|
| Calories | within ±10% of `calorieGoal` (a band, not a ceiling — under-eating is not a win) |
| Protein | ≥ `proteinGoal` |
| Training | a completed session on a scheduled training day, or rest day honoured |
| Sleep | ≥ `sleepGoalHours` |

Rendered as one bar per day, stacked in fixed colour order (meals / workouts /
sleep colours already exist in `PreferencesService`), height = 0–100%. A full-height
bar is instantly readable as "everything hit". Above it: today's completion, current
streak, best streak.

Why a stacked bar and not four rings: rings show *today*; the ask is "over time".
Rings go in the header row as a secondary, single-day readout.

Bucketing: day bars for W/M, week averages for 6M/Y — 365 daily bars on a 393pt
screen is noise.

### 2 — Nutrition

- Calories per day, bars, with a dashed goal line and a shaded ±10% band.
- 7-day moving average line over the bars — this is what makes a trend visible
  when day-to-day is spiky.
- Macro split: three thin sparklines (protein/carbs/fat) with `goal %` badges,
  not a stacked area — stacked macro areas are unreadable at 100pt tall.
- Footer stat row: avg kcal, avg protein, days logged / days in range.

### 3 — Training

- Weekly volume bars (Σ reps × weight, completed sessions only, kg-normalised).
- Sessions per week vs `trainingDaysPerWeek` target.
- Muscle-group distribution for the range (horizontal bars off
  `Exercise.primaryMuscle`) — surfaces neglected groups.

### 4 — Strength / Plateau  ← the "same weight for a while" ask

- An exercise picker (default: the exercise with the most sets in range).
- Line chart of **estimated 1RM** (Epley: `w × (1 + reps/30)`) with the actual
  top-set weight as dots. e1RM is the right metric: adding a rep at the same
  weight *is* progress, and a raw-weight line hides it — which is exactly the
  false "I'm stuck" reading to avoid.
- A **plateau strip** beneath: for every exercise trained ≥3 times in range,
  a row showing `last top weight`, `sessions at that weight`, `days since it
  moved`. Rows sort worst-first. This is the literal answer to "am I using the
  same weight for a while", and it works across all exercises at once rather
  than one at a time.

### 5 — Body Weight

Line + 7-day EMA (daily weight is water noise; the EMA is the signal), goal
direction from `UserProfile.goal`, and rate-per-week vs a healthy band.
Blocked on the new weight log (§2.2) — ship the section behind an empty-state
CTA ("log your first weigh-in") so the page is complete before the data is.

### 6 — Sleep

Duration bars with a goal band, average, and consistency (stdev of bedtime).
Quality 1–5 as a colour tint on each bar rather than a second chart.

### 7 — Insights

The generated cards. Each is a pure rule over the already-computed series:

| Rule | Fires when | Copy |
|---|---|---|
| Plateau | same top weight ≥3 sessions and ≥14 days | "Bench Press hasn't moved in 3 weeks — try 2.5kg or one more rep." |
| PR | e1RM above every prior value in range | "New best on Squat: 102kg estimated 1RM." |
| Protein shortfall | 7-day avg < 85% of goal | "Protein averaged 118g vs 150g goal this week." |
| Volume drop | week volume < 70% of 4-week average | "Training volume down 35% vs your average." |
| Sleep debt | 3+ nights under goal in the last 7 | — |
| Consistency win | streak ≥ 7 | — |
| Neglected muscle | zero sets for a group in 21 days | — |

Rules are `Insight? evaluate(AnalyticsView)`; the engine is `rules.map(...).nonNulls`,
sorted by severity, capped at 3 cards. Adding a rule is one pure function and one
unit test — no UI change.

---

## 5. Charts: build, don't add a package

No charting dependency exists today. Recommendation: **write the painters.**

- The page needs exactly four primitives: `LineChart` (+ optional EMA overlay and
  goal line), `BarChart` (+ stacked variant, + goal band), `RingRow`, `Sparkline`.
  That is ~400 lines of `CustomPainter`.
- `fl_chart`'s default look is Material, not iOS — matching the app's 9 themes,
  RTL, and `UIConstants` would mean fighting it on every card.
- The app already has 9 user-selectable themes and custom section colours. Every
  chart must read from `Theme.of(context)` / `PreferencesService`; a package's
  own theming layer is a second source of truth for colour.

Chart rules to hold the line on "clean and simple":
- No gridlines except a single baseline; no chart borders; no legends where a
  label fits on the series.
- Max 4 y-axis labels, max 5 x-axis labels, regardless of range.
- Values are shown by tap (a scrubber with a haptic tick), never as permanent
  labels on every point.
- Empty state per card, never a blank chart frame.

**RTL decision:** the time axis stays **left → right in both languages**, matching
the app's existing "numbers stay LTR" convention. Only labels and card content
mirror. Flipping the time axis for Hebrew is defensible but doubles the painter
test matrix for a screen that is mostly numeric.

---

## 6. Phasing

Each phase leaves the app shippable.

| Phase | Contents | Gate |
|---|---|---|
| **P0** | Range queries in `AppDatabase` + repos; `AnalyticsSnapshot`; `sleepGoalHours` pref | unit tests on range boundaries (inclusive start, exclusive end, DST) |
| **P1** | `domain/` pure layer: bucketing, series math, goal scoring, e1RM, plateau | fast-suite tests only, no UI |
| **P2** | Chart primitives + page shell + range selector + Goals-Together hero | golden-free widget tests; visual check |
| **P3** | Nutrition, Training, Sleep sections | — |
| **P4** | Strength/plateau section + insights engine | — |
| **P5** | Weight log: new entity, DB list, snapshot serialization, **export/import**, quick-log UI, section | round-trip test — the export gap is how new entities have been lost before |
| **P6** | l10n (en + he), a11y (semantic labels on every chart — a `CustomPainter` is invisible to VoiceOver without them) | — |

`P5` is separable and can be dropped without touching P0–P4.

---

## 7. Decisions

All four resolved — see the table at the top of this file.

## 8. What is left

- **Localisation.** Every string on the screen is English, written inline rather
  than through `AppLocalizations`. The insight rules emit numbers, not sentences,
  so the Hebrew pass is one function (`insightText`) plus the card labels — but
  it has not been done, and `docs/ROADMAP.md` C5 already wants a real translator
  rather than more code.
- **Accessibility.** A `CustomPainter` is invisible to VoiceOver. Each chart
  needs a `Semantics` label summarising its series.
- **Device verification.** Nothing here has been seen on hardware; the fast suite
  is the only thing that has run against it.
