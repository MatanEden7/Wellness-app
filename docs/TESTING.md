# Testing

Requires **Flutter 3.24.5** (see `.fvmrc`). On macOS put `/opt/homebrew/bin` on `PATH`
first, or iOS runs fail with "CocoaPods not installed".

```bash
export PATH="/opt/homebrew/bin:$PATH"
export FL=~/fvm/versions/3.24.5/bin/flutter
```

---

## Run only the area you changed

Every regression test file is tagged with the area it covers. After touching code in an
area, run that tag — it takes seconds and catches the regressions that matter most.

```bash
$FL test test/ --tags calendar          # one area
$FL test test/ --tags "calendar || i18n" # several
$FL test test/                           # everything (still fast, ~30s)
```

| Tag | Run it after changing… | Covers |
|---|---|---|
| `calendar` | `lib/features/calendar/**`, `calendar_schedule_generator.dart` | Recurrence (daily/weekly/monthly/custom), per-occurrence complete/skip/miss, occurrence ids, date-range bounds, DST-safe day stepping |
| `persistence` | `lib/data/db/**`, `export_import_service.dart`, `backup_location_service.dart`, `user_profile_service.dart` | Snapshot save/load, corrupt-file recovery, export/import round-trip, profile serialization, device-backup toggle (iOS flag vs Android relocation) |
| `integrity` | `lib/data/db/drift_database.dart` | Cascade deletes, `byId` cache consistency, unguarded lookups, stream notifications |
| `nutrition` | `lib/features/meals/domain/**` | Unit parsing, display↔stored conversion, macro math |
| `i18n` | `lib/l10n/**`, any `displayName()` | EN/HE key parity, no empty strings, bilingual fallback |
| `catalog` | Seeded starter content in `drift_database.dart` | 42 foods / 16 exercises / built-in templates, and that templates reference real foods |
| `notifications` | `lib/services/notification_*.dart` | Which page an action opens, occurrence-id resolution, snooze leaving the schedule alone, payload parsing |
| `profile` | `lib/services/setup_engine_service.dart`, `lib/features/settings/**`, onboarding | BMR/TDEE/target formulas, profile/settings screen behavior, profile→PreferencesService write-through |
| `ui` | `lib/core/theme.dart`, shared widgets | WCAG AA contrast (4.5:1) for every built-in theme's onSurface/surface and onPrimary/primary pairs |

**Rule of thumb:** if you can't tell which tag applies, run the whole fast suite — it's
30 seconds. Tags are for tightening the loop while iterating, not for skipping coverage
before you hand work over.

### Adding a test

Tag it at the top of the file so it joins the right area:

```dart
@Tags(['calendar'])
library;

import 'package:flutter_test/flutter_test.dart';
```

Tags must also be declared in `dart_test.yaml`, otherwise the runner warns.

---

## The two suites

**Fast suite — `test/`.** Pure Dart + widget-level. No device. Run it constantly.

**Device suite — `integration_test/`.** Drives the real app on a booted simulator; this
is what CI runs.

```bash
$FL test integration_test/sanity/meals_test.dart -d <udid>
```

- `integration_test/sanity/` — every screen renders, in both languages
- `integration_test/regression/` — specific past bugs (e.g. nutrition math through the UI)
- `integration_test/e2e/` — full user journey. **Not run by CI**; slower and more brittle.

Two things that will bite you:

- **Never use `pumpAndSettle()`.** Several screens show an indeterminate
  `CircularProgressIndicator`, whose animation never settles, so it hangs until timeout.
  Use the bounded `settle()` helper in `integration_test/support/app_launcher.dart`.
- **A rebuild resets the app sandbox** (new container UUID), so you'll land on onboarding
  and previously-logged data will be gone. That's the simulator, not a data-loss bug.

---

## What isn't covered

Worth knowing before trusting a green run:

- **Notification delivery.** Whether the OS actually *shows* the notification at fire
  time is not testable without a device clock -- verify by hand
  (`integration_test/e2e/notification_smoke_test.dart`). That a schedule call reaches
  the OS at all *is* covered cheaply, without waiting on real time:
  `integration_test/e2e/notification_scheduling_test.dart` asserts the scheduled event
  shows up in `pendingNotificationRequests()` right after the call. Both live in `e2e/`
  and aren't run by CI -- calling `initialize()`/`requestPermissions()` for real can
  trigger a native permission dialog on first run.
- **Rendering/layout.** Golden tests exist for the two `CustomPaint` widgets most at risk
  of the zero-size class of bug (`test/regression/color_picker_painters_test.dart`) --
  `HuePicker`'s track collapsed to zero width this way before (ISSUES.md #32). They don't
  cover every screen: a dialog once failed to lay out because a button demanded infinite
  width, invisible to `flutter analyze` and the full test suite, and only turned up by
  opening the screen. Still worth looking at the UI you changed.
