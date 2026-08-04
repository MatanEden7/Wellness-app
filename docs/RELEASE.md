# MVP Release Checklist

Status as of the release-prep pass. The app **is installed on your iPhone** (see #2).
The remaining blockers below need credentials or an install I can't perform for you.

---

## ✅ iOS: shipping

The app is **built, installed and launching** on Matan Eden as a **release** build — no
cable, no DEBUG banner, no Rosetta.

The original "Rosetta 2 missing" blocker is **gone, not worked around**. Flutter 3.24.5
shipped the iOS AOT compiler as an x86_64-only binary; **3.44.8 ships a universal binary
with a native arm64 slice**, so it runs directly on Apple Silicon.

`.fvmrc` had been pinning 3.24.5 while the source was written against 3.44.8 — that
mismatch, not the Mac, was the real problem. Evidence: `CardThemeData` and `intl ^0.20.2`
are both post-3.24 APIs that were already in the tree.

| | |
|---|---|
| Flutter | **3.44.8** (`.fvmrc` + CI updated) |
| Device | Matan Eden — iPhone 15 Pro, iOS 18.7.2 |
| Installed | `com.matan.wellnessx123` 1.0.0 (1), release/AOT |
| Signing | automatic, team `R6NSBVKVXV` |

Rebuild + reinstall:

```bash
~/fvm/versions/3.44.8/bin/flutter build ios --release
~/fvm/versions/3.44.8/bin/flutter install -d 00008130-000C64400E20001C
```

### Second device: ShaiOkev — blocked, needs Xcode updated

Flutter reports "enable Developer Mode", but that is a **misleading message** —
`devicectl` confirms `developerModeStatus: enabled`. Two real causes:

**1. Xcode is too old for that phone.**

| | |
|---|---|
| ShaiOkev | iOS **27.0** |
| Xcode 26.3 here ships | iOS **26.2** SDK |

Xcode cannot use a device running an OS newer than its SDK, so it refuses it as a run
destination.

**2. The device is not in the provisioning profile.**

Installing directly with `devicectl` (bypassing Flutter) gets further, then fails:

```
Failed to install embedded profile for com.matan.wellnessx123 :
0xe8008012 (This provisioning profile cannot be installed on this device.)
```

`ProvisionedDevices` contains Matan Eden and not ShaiOkev. Rebuilding with the phone
connected did **not** auto-register it, because of cause #1.

**These compound.** On a free/personal Apple account (see the expiry note below) only
Xcode can register a device — there is no portal to add a UDID by hand. So updating Xcode
to a version that supports iOS 27 is the required step; the profile then regenerates with
both phones on the next build.

### ⚠️ The build expires 2026-08-10

The profile is `iOS Team Provisioning Profile: com.matan.wellnessx123`, valid **7 days**.
That is the free/personal Apple Developer signature. The app on Matan Eden **will stop
launching on 2026-08-10** and needs a rebuild + reinstall to keep working.

A paid Apple Developer Program membership ($99/yr) raises this to a year, allows up to 100
registered devices, and lets you add device UDIDs from the web portal without Xcode.

### Deferred, non-blocking

- **UIScene lifecycle migration** will be required by a future iOS —
  <https://flutter.dev/to/uiscene-migration>
- `flutter_local_notifications`, `flutter_native_timezone` and `sqlite3_flutter_libs`
  don't support Swift Package Manager; a future Flutter makes that an error

---

## 🔴 Remaining blockers (Android only)

### 1. Android release is signed with the debug key

`android/app/build.gradle`:

```gradle
release {
    signingConfig = signingConfigs.debug   // <-- Play Store will reject this
```

This is the Flutter template default. Create an upload keystore, add `key.properties`
(and gitignore it), and point the release config at it. See
<https://docs.flutter.dev/deployment/android#signing-the-app>.

### 2. Android toolchain isn't installed here

`flutter doctor` reports **"Unable to locate Android SDK"**, so I could not build or
verify the Android side at all — including the backup rules and the `MainActivity`
method channel added for the Device Backup toggle. Those are written and analyzer-clean,
but **unverified on a real Android device**.

---

## ⚠️ Decide before shipping

**Bundle identifiers don't match across platforms:**

| Platform | Identifier |
|---|---|
| iOS | `com.matan.wellnessx123` |
| Android | `com.wellness.wellness_app` |

The iOS one looks like a scratch ID. Pick the real one **before** the first App Store
Connect / Play Console submission — it's effectively permanent afterwards. I left both
alone deliberately: changing a bundle ID after a listing exists orphans it.

**Display name also differs:** iOS shows "Wellness App", Android shows "Wellness".

---

## ✅ Done in this pass

- `ITSAppUsesNonExemptEncryption = false` added, so App Store Connect stops asking about
  export compliance on every upload
- Removed the unused `yaml` dependency and the asset it parsed; dropped the now-empty
  `assets/` declaration (an empty asset dir fails the build)
- Removed `updateBadgeCount()` — it requested badge permission and then did nothing, with
  no callers and no UI promising badges
- **All steady-state hardcoded UI strings are now localized** (EN + HE): 32 in a first
  pass, then **59 more** that a single-line `grep` had missed because they were written as
  multi-line `Text(\n  '…'\n)`. 49 new keys added, 10 folded onto existing ones. A
  multi-line-aware audit now returns 0
- **Pinned `intl` back to `^0.19.0`** — it had been bumped to `^0.20.2`, which Flutter
  3.24.5 cannot solve (`flutter_localizations` requires exactly 0.19.0). Every fresh
  `pub get` failed; only a stale lockfile was hiding it
- **`CardThemeData` -> `CardTheme`** — `CardThemeData` doesn't exist until after 3.24, so
  every device build failed to compile
- **`synthetic-package: false` added to `l10n.yaml`** — all 24 imports are
  `package:wellness_app/l10n/…`, but generation was going to `.dart_tool/flutter_gen`
- **Fixed a 9.1px overflow** in the dashboard "Today's Workouts" header (caught by the
  e2e suite, not by the analyzer)
- `.DS_Store` untracked and gitignored
- ProGuard rules reviewed — Flutter, notifications and native methods are all kept, so
  `minifyEnabled=true` is safe

---

## Verification status

| Check | Result |
|---|---|
| `flutter analyze lib/ test/ integration_test/` | ✅ 0 errors, 0 warnings |
| Fast suite (`flutter test test/`) | ✅ 91/91 |
| Device suites (simulator) | ✅ 8/8 |
| iOS **debug/simulator** build | ✅ clean |
| iOS **release** build | ✅ builds clean on 3.44.8 |
| Install on "Matan Eden" iPhone | ✅ installed and launching (release) |
| Install on "ShaiOkev" iPhone | 🔴 needs Xcode updated (iOS 27 > iOS 26.2 SDK) |
| Android build (any) | 🔴 blocked (no SDK) |

---

## Known gaps shipping in the MVP

These are documented in `ISSUES.md` and are deliberate scope calls, not regressions:

- **Export UX** — data round-trips correctly and OS-level device backup works, but there
  is no share sheet or file picker, and scheduled calendar events aren't in the export
  payload (`ISSUES.md` #3)
- **No profile screen** — onboarding collects weight/goal/BMR/TDEE and nothing ever
  displays it (`ROADMAP.md` A1). The highest-value gap for a v1.1
- **Hebrew catalog content** — UI is fully bilingual, but the 69 seeded foods/exercises
  have no Hebrew names and fall back to English (`ISSUES.md` #31)
- **Stale nutrition** — editing a food doesn't recompute past meals; currently reads as
  intentional snapshot semantics but has never been decided (`ISSUES.md` #14)
- **Notification delivery is manually verified only** — no automated coverage, see
  `TESTING.md`
