# Changelog

Notable completed work, most recent first. Update when a feature or fix ships —
see `CLAUDE.md` for the full doc-tracking rules.

## Unreleased

### Fast-food macros corrected against the Israeli menu (2026-08-09)

`ISSUES.md` #83, closing the owner-action flagged in #79. Read from McDonald's
Israel's own nutrition calculator rather than an aggregator — the first two
attempts were both wrong, which is the point worth recording: a plain search
returned US values presented as Israeli, and two Israeli aggregator sites
disagreed with each other, one of them impossibly (99 kcal/100g for a Big Mac
against its own stated serving total). Neither was used. The official
calculator is JavaScript behind an iframe, so it needed a real browser. Every
figure taken from it reconciles against 4/4/9 within 2% — that check is what
made it trustworthy.

| | was (US) | is (Israel) |
|---|---|---|
| Big Mac | 590 kcal, 34g fat | **434 kcal, 18.8g fat** |
| McChicken | 400 | 340 |
| Cheeseburger | 300 | 276 |
| Hamburger | 250 | 227 |
| Fries | 320 | 294 |
| McFlurry Oreo | 510 | 445 |
| Coca-Cola | 210 | 169 |

The menu differs in *what exists*, too. Israel has no Quarter Pounder (it has
the larger Mac Royal), no Filet-O-Fish (only the Double Mac Fish) and no
6-piece nuggets. Those rows keep their US numbers and now say **"McDonald's US
menu"**, with the three Israeli items added alongside under new ids — an id is
permanent and a logged meal points at it, so correcting a number is right but
changing what a row *is* would rewrite history.

Also cleared the mechanical half of ROADMAP C5: 17 hardcoded strings that
already had an l10n key are now wired. Two traps were caught by checking rather
than trusting the value match — `onboardingInjuriesBack` is the body part
("גב"), not the navigation "Back" ("חזור"), which would have put *torso* on
five back buttons; and one "Sleep" was a stored event title, not a label.

**Newly found and left open:** `profile_page.dart` has *zero* localisation —
the whole screen, not the few strays C5 described. Tracked as `ISSUES.md` #84.

### Exercise library: 58 → 115, and rehab that actually fills a session (2026-08-09)

Measured before touching anything, and the gaps were concrete.

**Rehab was the reported problem, and there were two.**

`SetupEngineService.getRehabExercises` was dead code with **no production
callers** — a hardcoded map of exercise *name strings*, covering three of the
seven body parts, sitting next to the real implementation. Its own test even
asserted that an elbow injury returns nothing, as if that were correct.
Deleted, the same way `getMacroPercentages` was.

The real path — `rehabFor` tags filtered by the user's equipment — worked but
could not fill a session. `WorkoutTemplateGenerator` asks for five exercises
and **silently skips the session** when the pool is empty. Measured pool with
no equipment: shoulder 2, elbow 2, knee 3, ankle 3. So a shoulder-injured user
with no bands got a two-exercise physiotherapy session, and an ankle-injured
one could not reach five *however well equipped*. Every body part now reaches
five with nothing but bodyweight — verified end to end through the generator,
not just by counting rows.

**Training coverage had holes you could not work around.**

| | bodyweight-only, before | after |
|---|---|---|
| Hamstrings | **0** | 3 |
| Shoulders | **0** | 2 |
| Biceps | **0** | 2 |
| Calves | 1 | 2 |
| `carry` pattern | **0 exercises, any kit** | 2 |

A user who owned nothing simply could not train hamstrings, shoulders or
biceps, and no generated plan could ever contain a carry.

**57 exercises added**, filling every measured gap: Nordic curls and
glute-ham walkouts, pike push-ups and wall handstands, chin-ups and towel
curls, reverse and Bulgarian lunges, hip thrusts, farmer and suitcase carries,
jump rope and burpees, and 17 rehab movements chosen so each joint has five
equipment-free options.

**The base, as with the food catalog:** the library moved into
`lib/data/catalog/starter_exercises.dart`, every row got a Hebrew name and
muscle label, and `exercise_audit_test.dart` now enforces the *coverage*
invariants rather than just field validity — because a library where every row
is perfectly tagged can still be unable to program a session, which is exactly
what this one was.

Two things the audit caught while being written:

* **Nothing may both rehabilitate and endanger the same body part.** Such a row
  would be put into a physiotherapy session for the exact injury it aggravates.
* **An injury must not silently wipe out a muscle group.** One case is real
  rather than a gap and is now pinned by name: every way to train the triceps
  loads the elbow extensors, so an elbow injury correctly leaves no direct
  triceps work. Any *other* pair joining that list is a coverage hole and the
  test will say which.

**The migration bug was here too.** `_applySnapshot` replaces the exercise list,
so all 57 additions would have reached nobody who already had the app —
identical to the food catalog. Rather than copy that fix, the high-water mark
is now one generic implementation (`_mergeNewSeededRows`) shared by both; the
contract is subtle enough that two copies would drift. Hebrew names are
backfilled onto existing rows too, and a renamed row keeps its own name while
still getting its movement tags — renaming changes what a row *is*, not how it
loads the body.

### Catalog: 233 foods, and a real category axis (2026-08-09)

**109 → 233 foods**, and categories are now a field rather than comment
headers in a source file, so the app can actually group and filter by them.

*Categorisation.* `FoodCategory` is a stored, bilingual, persisted field on
every food — 14 categories in a deliberate display order (protein, dairy,
grains, legumes, vegetables, fruit, nuts & seeds, fats & oils, sauces & spreads,
drinks, snacks & sweets, prepared dishes, supplements, fast food) plus `other`
for user-added foods, which the shipped catalog is forbidden to use.

It is a **separate axis from `FoodTag`**, on purpose. Tags answer "what does
this contain" and drive diet/allergen filtering; a category answers "where
would I look for this in a shop". Broccoli has no tags at all and still needs
to be findable under vegetables. `israeli` is a third, narrower axis — cuisine,
not category — so shakshuka is a prepared dish *and* Israeli without one fact
displacing the other. 39 items now carry it.

*The catalog page got usable.* It had no search box and no grouping, which was
survivable at 53 foods and absurd at 233. It now has a search field (matching
both names, either language) and a row of category chips that only offers
categories with something in them — a vegan is not shown an empty Fast Food tab.

*What was added (123 rows):*

| | |
|---|---|
| Protein | ground turkey, sardines, tilapia, cod, sea bass, lamb, liver, deli slices, hot dog, whole chicken, wings, tuna in oil |
| Dairy | whole/skim milk, plain yogurt, mozzarella, parmesan, cream cheese, sour cream, heavy cream, kefir |
| Grains | white bread, white pasta, bagel, tortilla, corn flakes, granola, rice cakes, bulgur, barley, matza, challah, instant noodles |
| Vegetables | lettuce, cabbage, green beans, beetroot, garlic, celery, pumpkin, asparagus, brussels sprouts, okra, leek, radish, butternut |
| Fruit | pear, peach, mango, pineapple, kiwi, melon, cherries, pomegranate, clementine, persimmon, fig, raisins, dried apricots |
| Drinks | water, coffee, tea, juices, cola, diet cola, sports/energy drinks, coconut water, almond & oat milk, beer, wine, vodka |
| Sauces | ketchup, mustard, soy sauce, sugar, jam, chocolate spread, maple syrup, BBQ, mayonnaise, almond butter, zhug, amba |
| Snacks | dark/milk chocolate, cookies, crisps, Bamba, Bisli, popcorn, pretzels, croissant, sufganiyah, rugelach, ice cream |
| Prepared | pizza, homemade burger, sushi, caesar salad, lentil soup, omelette, tuna sandwich |
| Legumes / nuts | kidney & white beans, green peas, ful, split peas, pistachios, pecans, hazelnuts, pine nuts, sesame, flax, coconut |

*Two fixes to the audit itself, found while extending it:*

* **The energy check was vacuous for per-ml and per-gram foods.** The absolute
  tolerance was a flat 15 kcal, but every value on a per-ml row is around 0.5 —
  a milk row with **ten times** the correct fat passed. The tolerance is now
  stated per 100g of serving basis and scaled by unit.
* **Alcohol needed an honest exemption.** Ethanol is 7 kcal/g and is not
  protein, carbohydrate or fat, so a beer's calories genuinely cannot be
  reconstructed from its macros. `containsAlcohol` exempts a row from the
  energy identity and nothing else — and the audit fails a row that sets the
  flag without needing it, so it cannot be used to wave anything through.

Every new row was validated against the audit rules before being written, and
all 233 pass. The audit also now enforces that no shipped food is left
unclassified, that a food sits in the block its category names, that both
language labels exist, and that the basics a first-week user logs are present.

Upgrading installs get categories backfilled onto rows they already had, with
the same rules as the Hebrew-name backfill: field-level, never overwriting a
user's value, never resurrecting a deleted food, and skipping a row the user
renamed — a repurposed "Chicken Breast" does not get told it is protein.

### Why the carbs goal was unreachable (2026-08-09)

Reported as "it's really hard to get to the carbs goal". Measured rather than
guessed at, and it turned out to be a real bug in the meal generator plus one
piece of arithmetic worth understanding.

**The bug.** `MealPortionSolver` capped every per-100g food at 400g and every
countable food at 4 units, regardless of what the food was doing in the meal.
At normal-to-high calorie targets that cap binds on the starch first, and a
generated day for an 80 kg bulking profile came out:

| | target | plan | |
|---|---|---|---|
| kcal | 3030 | 2594 | −14% |
| protein | 160g | 173g | +9% |
| **carbs** | **409g** | **256g** | **−37%** |
| fat | 84g | 102g | +22% |

Every carb source was pinned at its ceiling — rice 400g, sweet potato 400g,
bread 4 slices — so the solver closed the remaining calorie gap with the only
slot that had headroom left, which was fat. The plan read as "short on
everything except fat", and no amount of following it could reach the carb
target.

Bounds are now role-aware: the starch slot gets a 600g ceiling, but **only when
the food is actually dilute** (≤150 kcal/100g). Role alone is not enough — oats
are a carb source at 389 kcal/100g, and 600g of dry oats is 2,300 kcal, which
is not a portion. What makes a big plate of rice reasonable is that it is
mostly water, and energy density is already in the data. Same profile now:

| | target | plan | |
|---|---|---|---|
| kcal | 3030 | 2984 | −2% |
| protein | 160g | 168g | +5% |
| **carbs** | **409g** | **367g** | **−10%** |
| fat | 84g | 98g | +18% |

Across the seven profile shapes in the quality test, worst-case calorie error
went from 17.1% to 3.9% and worst-case carb undershoot from −36% to −2%.
Nothing regressed: protein and fat are equal or slightly better everywhere.

**Why the tolerance hid it.** The quality test allowed carbs to be off by ±42%
and calories by ±22%. Both are now set just outside measured worst case (38% /
8%), because the solver is deterministic and slack "just in case" is what let a
37% miss pass as normal. `Portion` now carries its `PortionRole` so the bound
contract can be checked rather than restated as a magic number.

**The arithmetic, which is not a bug.** Carbs are the residual: protein comes
from body weight, fat takes a fixed share of calories, and carbohydrate is
whatever is left. That makes it the largest number and the one that absorbs all
the slack — at maintenance for an 80 kg male it is 353g, 51% of intake. It also
means the four numbers are not independent. **If you hit calories and protein
and fat, you have hit carbs**; missing carbs specifically means either coming
in under on total calories, or going over on fat. Fat is the easy one to
overshoot, since 20g of it — a splash of oil — is 180 kcal, which is 45g of
carbohydrate off the budget.

### The food catalog: audited, doubled, bilingual (2026-08-09)

**53 foods to 109**, every one of them checked as data rather than trusted.

*The base, built first:*

* The catalog moved out of a method body in the middle of `drift_database.dart`
  and into `lib/data/catalog/starter_foods.dart`, where it is a table with its
  sources written down.
* `FoodMacroAudit` checks a food's numbers against physics and arithmetic:
  energy agrees with 4/4/9 within a fibre-aware tolerance, nothing is negative,
  and a per-100g food cannot contain more than 100g of macros or beat pure fat
  for energy density. `catalog_audit_test.dart` runs it over every row, plus
  unique ids, valid units, tag consistency (dairy implies animal-origin;
  shellfish implies fish) and Hebrew coverage. **Adding a food means passing all
  of it.** It caught two real tagging bugs in the new rows while they were being
  written.
* The audit of the existing 53 found no wrong numbers. The apparent outliers —
  broccoli at 34 kcal against an Atwater 43 — are fibre and USDA's
  food-specific energy factors, correct as published, and the tolerance is
  shaped around that rather than around tidiness.

*Reaching people who already have the app:*

`_applySnapshot` **replaces** the seeded catalog rather than merging it, which
is right (merging would duplicate all 53 foods every boot and resurrect deleted
ones) but meant a catalog addition only ever reached fresh installs. Fifty-six
new foods nobody could see is not a shipped feature. `AppDatabase` now keeps a
high-water mark of starter ids it has *offered* — a different thing from the
ids it holds — so a new food arrives exactly once and a deleted one stays
deleted. Ids 1–53 are recorded as a frozen legacy set, which is what lets an
upgrading snapshot with no record of its own history be read correctly. The
mark travels in the backup too, so a restore cannot resurrect anything either.

*What was added:*

| Group | Count | Notes |
|---|---|---|
| Israeli | 26 | hummus, tahini (raw and prepared), falafel, pita/laffa, shakshuka, schnitzel, shawarma, sabich, couscous, ptitim, bourekas, malawach, jachnun, the dairy shelf by fat percentage, halva, medjool dates, olives |
| Protein supplements | 7 | whey isolate/concentrate, casein, plant, mass gainer, bar, RTD shake |
| McDonald's | 11 | Big Mac through McFlurry, each branded so it is never mistaken for a generic food |
| Everyday staples | 12 | the audit found no potato, no onion, no chicken thigh, no steak — all things a user logs in week one |

`scoop` is a new serving unit: protein powder is sold and measured that way,
and converting to grams would invent precision the tub does not have.

*Hebrew:* every one of the 109 rows now has `nameHe`. The bilingual plumbing
already existed and was waiting on content; the Israeli foods made it
unavoidable, since they have no natural English name. Food search now matches
**both** names in either language mode — it previously matched English only, so
adding Hebrew content without this would have made half the catalog
undiscoverable to the people it was added for.

*Caveat worth repeating from the source:* branded fast-food values are the
chain's published US figures, and menus differ by country. Israeli McDonald's
is not US McDonald's. They are close, not exact, and a user can edit any row.

### Nutrition targets were not a coherent plan (2026-08-09)

The per-food macro math (`FoodNutritionMath`) checked out — the problem was the
engine that produces the daily targets those numbers are measured against.
`SetupEngineService` had four separate defects:

* **Fat was never a target.** `calculateFatTarget` returned the 0.6 g/kg
  essential-fat *minimum* and ignored its own `calorieTarget` and `proteinG`
  parameters entirely. Fat landed at 13–16% of intake and every calorie it did
  not claim was dumped into carbs — an 80 kg maintenance profile got 48 g fat
  and ~370 g carbs. Fat is now a share of the calorie budget (25–30% by goal),
  floored at the essential minimum.
* **A flat ±kcal adjustment.** `-400` for fat loss is ~13% for a 3000 kcal
  athlete and ~30% for a 1350 kcal sedentary user. Now 20% down / 10% up,
  capped in absolute terms, and floored at 1200 kcal (women) / 1500 kcal (men)
  — the old formula handed a 50 kg sedentary woman a **922 kcal** target.
* **Protein scaled off total body weight.** 2.2 g/kg at a high BMI prescribed
  264 g/day for a 120 kg user, over half their calories. Now scaled against
  adjusted body weight above BMI 27.5, and capped at 40% of intake.
* **The four numbers did not have to agree.** Carbs silently clamped to 0 when
  protein and fat overran the budget, leaving a target set where 4P + 4C + 9F
  did not reconstruct the calorie target. `calculateTargets` now solves all
  four together, walking fat and then protein back toward their floors instead,
  and rounds so the grams still reconcile.

`getMacroPercentages` is gone: dead code that documented splits (fat 25–35%)
the engine never actually produced.

Onboarding and the Profile page's recompute had each open-coded the same four
calls; both now go through the single `calculateTargets`, so which screen you
edit from can no longer change your targets. Generated meal templates improve
for free — `MealTemplateGenerator` sizes every meal against these targets.

Covered by 72 new fast tests in `test/regression/setup_engine_test.dart`,
including a sweep of all 72 profile shapes the onboarding form can produce,
each asserting the target set reconciles and sits in a defensible range.

### Custom foods and exercises could not be saved on a phone (2026-08-07)

`ISSUES.md` #77. Both the add/edit food dialog and the add/edit exercise dialog
were a `Column` with no scroll view. On a 402x874 phone the content overflowed
its dialog by 159pt and pushed the Add / Update button to y=926 — past the
bottom of the render tree, with nothing to scroll. The button was unreachable,
so adding a custom food or exercise was **impossible on a real device**.

Each dialog now caps at 85% of screen height and scrolls only its fields, with
the title and action row pinned.

Found by running the full integration suite rather than by reading the code, and
the reason it had gone unnoticed is worth recording: `tester.tap()` does not
fail when its target is off-screen — it misses, prints a `warnIfMissed`
*warning*, and carries on, so the run died several steps later at something
unrelated and looked like test rot. `integration_test/support/app_launcher.dart`
gained `tapVisible()` (ensureVisible + tap), and every form and onboarding
button now goes through it.

### New: onboarding → full schedule integration flows (2026-08-07)

`integration_test/regression/onboarding_schedule_flow_test.dart` — four flows
that all **start from a user who already has three weeks of history** (meals,
progressive training, sleep, weigh-ins) via a new `seed` hook on the test
harness. An empty install is the easy case; the interesting question is whether
generation copes with, and does not destroy, data already there.

They assert that completing the real wizard leaves: workouts, meals and one
sleep event; every event recurring rather than one-off; every workout pinned to
a template; counts matching the profile just saved; the schedule actually
rendered on the calendar rather than merely stored; the analytics screen
populated; and the pre-existing history intact.

### Analytics: duplicate rows, accessibility, Hebrew (2026-08-07)

Three follow-ups closed together — `ISSUES.md` #75, #73, #72, plus #76 which
only surfaced because of them.

- **#75 — scheduling something for *right now* showed it twice.** The dialog
  wrote the real meal / session / sleep entry *before* constructing the event,
  so the logged row had no `sourceEventId` and the calendar rendered the plan
  and the log side by side: #57's symptom via a new path. The event is now
  built first, `_createDataFromTemplate` takes the id as a **required**
  argument (which is what makes the ordering un-reversible), and
  `createMeal` / `createSession` / `createEntry` finally accept the link at all.
  `metadata.dataId` is merged rather than replacing the map, so a recurring
  event's occurrence history survives an edit.
- **#73 — the charts were silent under VoiceOver.** Every chart is wrapped in a
  `Semantics` node describing what a sighted user reads off the shape: measure,
  bucket, coverage, average, range, direction, goal. Direction is only called a
  trend when the drift covers at least half the series' own spread — that ratio
  is what separates calorie noise from a real body-weight decline, where no
  absolute threshold could.
- **#72 — the screen is bilingual.** 77 new keys in both ARB files; not one
  English literal remains in `lib/features/analytics/ui/`. The insight rules
  still emit numbers rather than sentences, so all eight translate as ARB keys.
  The Hebrew is not a translator's — #31 still covers that pass.
- **#76 — every multi-placeholder ARB string had its arguments in the wrong
  order.** `gen-l10n` orders parameters alphabetically by placeholder name
  absent metadata, and no existing key had ever hit it. `"Average {average},
  from {min} to {max}"` generated `(average, max, min)`, announcing the range
  backwards. Seven keys were affected, silently. Metadata is now declared for
  all 33 parameterised keys.

581 → 606 fast tests.

### A scheduled event could save without ever appearing (2026-08-07)

`ISSUES.md` #74. Anything scheduled into a month the user had *scrolled to* was
written to storage correctly and never rendered.

`CalendarNotifier.refresh()` reloaded one month — `state.focusedDate`. But
`onMonthChanged` deliberately never moves `focusedDate` (moving it re-animates
the scroll list, which was #44), so it stays on whichever month the page opened
at however far you scroll. Now the notifier tracks the months actually paged in
and refreshes all of them, plus the month of the event being acted on — so
scheduling into a month never yet visited works too. Two hand-rolled reloads in
`calendar_page.dart` that had been working around this for the complete and
delete paths were removed.

The regression test asserts against `CalendarState.days`, not the service: the
service was already correct in every case, so a service-level test would have
stayed green through the whole bug.

### Analytics screen (2026-08-07)

A dated view of everything logged, at `/analytics` (dashboard header, not the
bottom bar — five destinations already wrap their labels at 393pt). Planned in
`docs/ANALYTICS_PLAN.md`.

- **Goals-together hero chart.** One bar per bucket, split into equal segments
  for calories / protein / training / sleep. A full-height bar means the whole
  day was hit, which reads without a legend. Streak and best streak above it,
  today's rings below.
- **Calorie scoring follows the profile goal.** `fat_loss` counts comfortably
  under target as a win (with a floor, so starving still fails), `muscle_gain`
  wants the target met or beaten, everything else is a ±10% band. A flat band
  for everyone marks a cutting user's best day as a failure.
- **Rest days count once the week's target is met**, so a perfect week is
  possible for someone who does not train daily.
- **Strength: estimated 1RM, not raw load.** Adding a rep at the same weight is
  progress and a raw-weight line hides it — the exact false "I'm stuck" reading
  the plateau strip is supposed to be the only source of.
- **Plateau strip** covers every loaded exercise at once, worst stall first:
  last working weight, sessions at it, days since it moved. Fires only at ≥3
  sessions *and* ≥14 days; a deload does not reset the clock, and bodyweight
  exercises are never flagged.
- **Body-weight history** is a new tracked entity (`BodyWeightEntryData`),
  upserted per calendar day. Charted as a 7-ish-day EMA with the raw weigh-ins
  as dots — daily weight moves a kilo on water alone. In the backup from the
  same commit that introduced it (export `1.4.0`).
- **Insight rules** — plateau, PR, protein shortfall, calorie drift, volume
  drop, sleep debt, consistency win, neglected muscle. Pure functions over the
  computed view, capped at three cards, emitting numbers rather than strings so
  wording stays in one place.
- **Charts are hand-painted**, no charting dependency: four `CustomPainter`
  primitives that read the app's 9 themes and custom section colours directly.
- **One provider, one pass.** Every section reads a slice of a single
  `AnalyticsView`; nothing queries per-card. Sleep goal added to preferences
  (default 8h); in-progress sessions are excluded from every aggregate.
- 531 → 581 fast tests.

### Goal-driven workout programming (2026-08-06)

Generated workouts were `3 sets x 10 reps, no weight, no rest` for every goal
and every person -- a placeholder that looked like a program. Filed as
`ISSUES.md` #70.

- **Sessions are programmed from the goal.** Sets, reps and rest now come from
  the goal (`muscle_gain` 4x8, `fat_loss` 3x14, `maintenance` 3x10,
  `mobility_rehab` 2x12), with rest split by mechanic -- compounds rest two to
  three times as long as accessories.
- **Exercise count is derived from a time budget**, not fixed. Sessions target
  45 minutes and are capped at 60, warm-up ramps included. A fixed six
  exercises is ~45 minutes at 3x10 and ~75 at 4x8 once real compound rest is
  counted.
- **Starting weights are prescribed**, from bodyweight-relative strength
  standards adjusted for sex, training experience and age, converted to the
  rep range via Epley and rounded to 2.5kg. Only ever for `kg`-based
  exercises; bodyweight, band and timed work get none.
- **New onboarding question: training experience.** Activity level is a
  calorie input and a poor strength proxy -- an active postman is not an
  experienced lifter.
- **Splits target training each muscle twice a week** and support 1-7 days.
  The schedule capped at 5, so asking for 6 silently gave 5; the training-days
  slider capped at 6.
- **Selection is by movement pattern, not muscle name.** Fixes sessions that
  paired Bench Press with Push-ups, or Squats with Bodyweight Squat, while
  never reaching the arms at all. Loaded lifts are preferred over bodyweight
  ones when the user owns the kit, because the progression rule is "add
  2.5kg".
- **Per-exercise rest drives the in-session timer**, replacing one global 90s
  value used for heavy squats and cable curls alike. Visible and editable in
  the template editor.
- **The profile and every setting are now in the backup.** They were in no
  backup at all: restoring on a new phone brought back the meals and workouts
  and dropped the goal, targets, equipment and injuries that give them
  meaning. Preferences are captured by walking the store, so a new setting
  cannot be forgotten.
- Generated templates carry Hebrew names, which `WorkoutTemplateData` has
  supported all along and the generator never filled.

### Notification audit (2026-08-05)

Full pass over the notification path. Dispatch was already fixed (#4/#58/#59);
these are the defects underneath it, in the layer that decides whether the
handler is reached at all. Filed as `ISSUES.md` #69.

- **Snooze and meal "Remove" now actually work.** iOS routes an action to the
  background isolate unless it is declared `foreground` — regardless of whether
  the app is running. All four such actions were missing it, so their handler
  code was unreachable in production. Pressing them did nothing, always.
- **A completed rest timer no longer kills every notification button.** A
  duplicate `NotificationService` in `lib/core/notifications.dart` ran its own
  `initialize()` on the same (singleton) plugin, nulling the tap handler for the
  rest of the session. File deleted; the rest-timer notification moved onto the
  real service.
- **The rest timer plays an actual sound.** It set a volume on a player that
  had no audio source, so the sound switch and volume slider in workout settings
  were inaudible no-ops. Ships a generated beep asset.
- **Notification settings now apply to reminders already scheduled.** Sound,
  vibration, lead time, quiet hours and the category switches were read only when
  an event was written, so toggling one left the existing queue untouched. Every
  such change now re-issues the queue.
- **The queue is re-synced on app start and on language change** — it previously
  drifted after a reboot or timezone change, and pending reminders kept whatever
  language they were scheduled in.
- **The sleep goal-reached alert no longer offers "Start Sleep" / "Snooze 30m"**
  on an alert announcing that the sleep just finished.
- **The rest-timer notification is localized** (it was the last hardcoded English
  user-facing string) and honours the sound/vibration preferences.

### Edit-path fixes (2026-08-05)

- **Calendar "Edit" no longer opens a blank form — or creates a duplicate.** The
  scheduling dialog always supported editing; the Edit action just never handed it
  the event, so the form came up empty *and* saving added a second event instead of
  updating the one being edited. Recurring occurrences now resolve to their base
  event first (editing an occurrence edits the series).
- **Editing a meal, workout or sleep entry no longer un-links it from the calendar
  event that created it.** `sourceEventId` lives only on the DB row, so every
  repository update silently nulled it and brought back the duplicated-row bug.
  Reachable just by stopping a sleep timer started from an event.
- **Editing a meal no longer moves it on the calendar.** Its `createdAt` was being
  stamped forward on every edit, and the calendar falls back to `createdAt` when no
  explicit time is set.
- **Deleted workout sessions and sleep entries no longer resolve by id.** Both
  deletes skipped their `*ById` cache — same class of bug as the referential-integrity
  pass, missed there.
- **Export share sheet no longer crashes on iPad**, which the app ships for: UIKit
  needs a `sharePositionOrigin` to anchor the popover.

- Profile screen wired up end-to-end: view/edit body, goal, activity, targets;
  reachable from Settings and the dashboard. Recomputes BMR/TDEE/targets live
  via `SetupEngineService`, matches `PROFILE_AND_SETTINGS_PLAN.md`'s Option A
  (that plan is now retired — fully superseded by this).
- Calendar events + meal templates added to export/import (was DB-only before;
  scheduled events lived in SharedPreferences and were silently excluded).
- Export gained a real share sheet; import gained a file picker (previously
  paste-JSON-into-a-TextField only).
- Sleep streaks (consecutive nights meeting the sleep goal) added, surfaced on
  the Sleep page.
- Fixed a real DST bug in `AppDateUtils.startOfWeek`/`endOfWeek` — used
  `Duration`-based day arithmetic, which drifts across a clock change; now
  uses the DST-safe `DateTime(y, m, d±n)` pattern already used elsewhere.
- Added `Meal.loggedAt` — a real time-of-day field instead of guessing from
  `createdAt`/keyword matching. Meal editor has a Time (optional) field; the
  calendar prefers it when present.
- "Stop Sleep" affordance surfaced on the dashboard quick-action (reflects an
  active session instead of always reading "Sleep Timer").
- Added a "Delete data older than X" option (Settings → Data Management) for
  meals/workouts/sleep entries and one-off calendar events.
- Fixed 3 real WCAG AA contrast failures in the built-in theme palette (ocean/
  forest/sunset primary colors were 2.5–2.8:1 against white button text,
  below the 4.5:1 bar) — caught by a new `test/regression/theme_contrast_test.dart`
  that audits every built-in theme.
- Added golden tests for `HuePicker`/`SaturationBrightnessPicker` (guards the
  zero-width `CustomPaint` regression class — ISSUES.md #32).
- Added a widget-interaction test tier (`test/widget/`) — tap a widget in
  isolation, assert its callback fired.
- Added `test/regression/notification_scheduling_test.dart` — asserts a
  scheduled event reaches the OS pending-notification queue, without waiting
  on real delivery.
- Accessibility: every icon-only `IconButton` now has a `tooltip`.
- Verified (not removed) `BackgroundRefreshService` — trimmed one dead
  `invalidate()` call after tracing it had no watcher, kept the two that do.

## Earlier

### Performance pass

- **Removed 500ms polling.** Every collection (`meals`, `foods`,
  `mealTemplates`, `workouts`, `sleep`) now has a `StreamController` that
  mutators fire on insert/update/delete, instead of a 500ms polling timer.
  ~60–70% CPU-while-idle reduction; updates are now instant instead of
  delayed up to 500ms.
- **O(n) → O(1) lookups.** Added `Map<String, T>` id-caches (`_foodsById`,
  `_mealsById`, `_mealTemplatesById`, `_exercisesById`,
  `_workoutTemplatesById`, `_workoutSessionsById`, `_sleepEntriesById`)
  alongside the existing lists, kept in sync on every mutation. `getById()`
  calls that used to do a linear `firstWhere()` scan are now instant
  regardless of collection size.

(`OPTIMIZATION_PROGRESS.md`'s remaining open items — moved to `docs/ROADMAP.md`
Epic G, since they're still real and hadn't been tracked as roadmap items.)
