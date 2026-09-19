# Counter++

Flutter mobile app (Android + iOS) for tracking repetition-based memorization.
Published on Google Play as `com.bdzapps.counter.counter`. Package name is
`counter` (see `pubspec.yaml`), so internal imports are `package:counter/...`.

## Architecture

State management is Riverpod (`flutter_riverpod`), persistence is local SQLite
via `sqflite`. There is no backend of our own; synchronization is optional and
talks to a user-configured remote endpoint.

- `lib/models/` — plain data classes (`Counter`, `Folder`, `Count`, `Settings`,
  `Statistics`, result wrappers like `OperationResult` / `SyncResult`).
- `lib/repository/` — `CounterRepository` is the abstract contract;
  `DatabaseCounterRepository` is the only implementation and holds every SQL
  statement plus schema migrations. Largest file in the project (~1000 lines).
- `lib/providers/` — Riverpod providers. `counter_repository_provider.dart`
  exposes both a sync and an async (`asyncCounterRepositoryProvider`) handle;
  the async one gates app startup on DB initialization.
- `lib/screens/` — one file per full-page route.
- `lib/widgets/` — reusable UI, including the counter grid/list variants and
  their editable (reorderable) counterparts.
- `lib/utils/` — cross-cutting services: `synchronization_service.dart`,
  `logging_service.dart` (also handles crash/log email reporting).
- `lib/l10n/` — ARB sources plus the `app_localizations*.dart` that
  `flutter gen-l10n` derives from them. The generated files are gitignored;
  edit the ARB files and regenerate, never the Dart.

`assets/sql_scripts/` holds sample SQL used by the app for table bootstrapping.

## Conventions

- Lints come from `package:flutter_lints/flutter.yaml`, no custom rules on top.
- Debug output goes through `debugPrint` guarded by `!kReleaseMode`.
- Locales supported: `en` and `fr`. Every user-facing string must go through
  `AppLocalizations`, never a hardcoded literal.

## Toolchain

The Flutter SDK is pinned per project with [fvm](https://fvm.app): `.fvmrc`
selects **Flutter 3.47.4 / Dart 3.13.3**, and `.fvm/flutter_sdk` symlinks it.
Always drive the project through `fvm`, never the global `flutter` on PATH:

```bash
fvm flutter analyze
fvm flutter test
```

`android/local.properties` points `flutter.sdk` at `.fvm/flutter_sdk` too, so
Gradle builds use the same SDK. That file is not in git — a fresh clone needs
`fvm install` followed by `fvm flutter build apk` once to regenerate it.

No package is held back any more; every direct dependency is on its latest
release. `flutter pub outdated` can still overstate what is reachable, so
confirm a bump with a real build, not just `flutter analyze` (which does not
analyse package sources).

Platform floors that the toolchain forces, all verified by a release build:

| Where | Value | Why |
|---|---|---|
| Gradle / AGP / Kotlin | 9.3.1 / 9.1.0 / 2.4.0 | Flutter 3.47 rejects Gradle below 8.14 |
| `compileSdk` / `targetSdk` | 36 | Google Play requires targeting API 36 to publish updates |
| `minSdkVersion` | 30 | set in `android/app/build.gradle.kts` |
| iOS deployment target | 15.0 | raised by Flutter's own migrator |

`android/gradle.properties` keeps `android.builtInKotlin=false` and
`android.newDsl=false`: the `downloadsfolder` and `in_app_review` plugins still
apply the Kotlin Gradle Plugin themselves, so the app cannot move to AGP 9's
built-in Kotlin yet. `downloadsfolder` also has no Swift Package Manager
support, which Flutter now warns about on every iOS build.

## Common commands

Regenerate localization after editing ARB files:

```bash
fvm flutter gen-l10n
```

## Health Stack

- TYPECHECK: fvm flutter analyze
- LINT: fvm dart format --output=none --set-exit-if-changed $(git ls-files '*.dart')
- TEST: fvm flutter test
- DEADCODE: fvm dart run dart_code_linter:metrics check-unused-code lib
- DEPS: fvm flutter pub outdated

The lint command is scoped to tracked files on purpose. `flutter gen-l10n`
rewrites `lib/l10n/app_localizations*.dart` in a style `dart format` disagrees
with, so passing `lib/` would fail the gate after every build. Those files and
`lib/generated/` are gitignored, so `git ls-files` leaves them out.

## Tests

`test/` mirrors `lib/`. `test/helpers/test_database.dart` boots a real SQLite
engine on the host VM through `sqflite_common_ffi` and hands each case its own
throwaway database, so repository tests run against the production schema,
triggers and foreign keys rather than a mock.

`test/helpers/test_container.dart` builds on it for the provider tests: it hands
back a `ProviderContainer` with `counterRepositoryProvider` overridden to a
throwaway repository, so the notifiers run against real SQL without waiting on
app startup.

One trap when testing notifiers: every mutator calls `update(...)` without
awaiting it, so the new state lands a microtask after the method's own future
completes. Assert through a helper that calls `pumpEventQueue()` first, the way
`names()` does in the provider tests, or the read races the write.

Two seams exist purely for tests and are not used in production:
`DatabaseCounterRepository(databaseDirectory:)` and
`SynchronizationService().client`. HTTP is stubbed with `MockClient` from
`package:http/testing`; no test touches the network.

One behaviour worth knowing before writing repository tests: the
`*_history` delete triggers only fire when a non-empty
`synchronizationAccessToken` is stored in `settings`. Tests that assert on
pending deletions have to configure a token first.

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Author a backlog-ready spec/issue → invoke /spec
