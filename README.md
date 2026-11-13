# App Core (working title)

> The product name isn't decided yet. The codename is `app_core` (Dart package),
> **App Core** (display name) and `com.example.appcore` (bundle/application ID).
> See [docs/RENAMING.md](docs/RENAMING.md) for how to rename it.

> **Starting a new app from this template?** Run
> `tool/new_app.sh --name "Acme Garage" --package acme_garage --id com.acme.garage --setup`.
> It copies the template to `../acme_garage`, applies every rename from
> [docs/RENAMING.md](docs/RENAMING.md) and runs `git init`. The template itself is not changed.

A Flutter app for Android and iOS, built with a feature-first Clean Architecture:

- **Navigation:** go_router
- **State:** flutter_bloc (Bloc + Cubit)
- **DI:** get_it (manual registration)
- **Models:** freezed + json_serializable
- **Errors:** fpdart `Either<Failure, T>`
- **Flavors:** dev, qa, staging, uat, prod

Further reading: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Prerequisites

| Tool | Notes |
| --- | --- |
| [FVM](https://fvm.app) | `brew tap leoafarias/fvm && brew install fvm` (or `dart pub global activate fvm`) |
| Xcode | iOS builds (macOS only) |
| Android Studio / Android SDK | JDK 17+ (the bundled JBR works) |
| `make` | Already installed on macOS and Linux |

The Flutter version is pinned in [`.fvmrc`](.fvmrc) (currently **3.47.9**). **Run every Flutter or Dart command through FVM**
(`fvm flutter …`, `fvm dart …`). The `make` targets already do this.

## Getting started

```bash
git clone <repo-url> && cd garage-app
fvm install                     # installs the Flutter version from .fvmrc
fvm flutter pub get
make env                        # copies env/*.example.json → env/*.json
make gen                        # build_runner (freezed/json) + gen-l10n
make run-dev
```

`make setup` runs all of these steps except `make run-dev`.

### IDE setup

- **VS Code:** the committed [`.vscode/settings.json`](.vscode/settings.json) points the Dart extension at
  `.fvm/flutter_sdk`. [`.vscode/launch.json`](.vscode/launch.json) has launch configs grouped by
  build mode. Pick one in the Run & Debug panel; the selected device decides iOS or Android.
  - **debug:** every flavor (`dev`, `qa`, `staging`, `uat`, `prod`) for everyday development.
  - **profile:** `uat` only, for DevTools performance work against a prod-like API. Needs a physical device.
  - **release:** `uat` and `prod`, to check exactly what ships. Needs a physical device on iOS.

  For other flavor/mode combinations use the CLI, e.g. `fvm flutter run --release --flavor qa -t lib/main_qa.dart
  --dart-define-from-file=env/qa.json`.
- **Android Studio / IntelliJ:** go to *Settings → Languages & Frameworks → Flutter → Flutter SDK path* and set it to
  `<project>/.fvm/flutter_sdk`. Also mark `.fvm` as excluded (right-click → *Mark Directory as → Excluded*). Add a
  run configuration per flavor: *Dart entrypoint* `lib/main_dev.dart`, *Build flavor* `dev`, *Additional run args*
  `--dart-define-from-file=env/dev.json`.

## Environment files

Each flavor reads its config at compile time from `env/<flavor>.json` via `--dart-define-from-file`.

- Only the `env/*.example.json` files are committed. The real `env/*.json` files are git-ignored.
- To add a key: add it to **every** `*.example.json`, read it in
  [`EnvironmentValues`](lib/core/config/environment_values.dart), then expose it on
  [`AppConfig`](lib/core/config/app_config.dart).
- Never hardcode secrets, API keys or base URLs in Dart code.

| Key | Description |
| --- | --- |
| `API_BASE_URL` | Base URL for the REST API (required; the app throws at startup if it's empty) |
| `API_KEY` | Optional. Sent as the `x-api-key` header when set |
| `CONNECT_TIMEOUT_MS` / `RECEIVE_TIMEOUT_MS` | Dio timeouts |

## Flavors

| Flavor | Purpose | App name | Android application ID | iOS bundle ID | API (`API_BASE_URL`) | Goes to |
| --- | --- | --- | --- | --- | --- | --- |
| dev | Daily development | App Core DEV | `com.example.appcore.dev` | `com.example.appcore.dev` | Local / dev API | Developers |
| qa | QA testing | App Core QA | `com.example.appcore.qa` | `com.example.appcore.qa` | QA API | QA team |
| staging | Pre-release | App Core STG | `com.example.appcore.stg` | `com.example.appcore.stg` | Prod-like staging API | Internal release testing |
| uat | User acceptance testing | App Core UAT | `com.example.appcore.uat` | `com.example.appcore.uat` | UAT API | UAT / stakeholders |
| prod | Store release | App Core | `com.example.appcore` | `com.example.appcore` | Production API | App Store / Play Store |

All five can be installed side by side. Non-prod builds have a coloured DEV/QA/STG/UAT ribbon on the launcher
icon and a corner banner inside the app.

The example env files currently point at `https://jsonplaceholder.typicode.com` (placeholder API).

| | dev | qa | staging | uat | prod |
| --- | --- | --- | --- | --- | --- |
| Log level | verbose | info | warning+ | warning+ | warning+ |
| go_router `debugLogDiagnostics` | ✅ | ✅ | – | – | – |
| Bloc transition logs | ✅ | ✅ | – | – | – |
| Crash reporting (planned) | – | ✅ | ✅ | ✅ | ✅ |

## Run & build

```bash
make run-dev            # also: run-qa, run-staging, run-uat, run-prod
make build-apk FLAVOR=qa
make build-appbundle FLAVOR=prod
make build-ipa FLAVOR=qa          # needs signing set up in Xcode
make build-ios-nosign FLAVOR=qa   # CI-style iOS build without signing
```

The raw commands, if you need them:

```bash
fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json
fvm flutter build apk --release --flavor qa -t lib/main_qa.dart --dart-define-from-file=env/qa.json
fvm flutter build ipa --release --flavor prod -t lib/main_prod.dart --dart-define-from-file=env/prod.json
```

Every build needs `--flavor`. iOS has no plain `Runner` scheme, and Android has no unflavored variant.

## Code generation

Generated files (`*.freezed.dart`, `*.g.dart`, `lib/core/l10n/gen/`) are **not committed**. Regenerate them after
pulling or after you change a model, entity, failure, event or state:

```bash
make gen     # fvm dart run build_runner build --delete-conflicting-outputs && fvm flutter gen-l10n
make watch   # fvm dart run build_runner watch --delete-conflicting-outputs
```

[`build.yaml`](build.yaml) limits freezed and json_serializable to the folders that use them. It also sets
`explicit_to_json: true` and `field_rename: snake`.

## Testing & quality

```bash
make test        # fvm flutter test
make coverage    # fvm flutter test --coverage
make analyze     # fvm flutter analyze (must be zero issues)
make format      # fvm dart format .
make check       # format-check + analyze + test (what CI runs)
make integration FLAVOR=dev   # integration_test/ on a connected device
```

CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs on every PR to `develop`/`main`. It installs the
Flutter version from `.fvmrc`, then runs pub get → build_runner → format check → analyze → tests with coverage, then
builds a dev debug APK.

## Assets

- `assets/images/`, `assets/icons/`: in-app images and icons, already declared in `pubspec.yaml`.
- `assets/fonts/`: declare fonts under `flutter.fonts` in `pubspec.yaml` and use them in `core/theme/app_typography.dart`.
- `assets/icons/launcher/`: launcher icon sources only. They aren't bundled into the app because sub-folders
  aren't included.

## Launcher icons

The source images are in `assets/icons/launcher/` (they're placeholders until the brand is decided). There's one config
per flavor: `flutter_launcher_icons-<flavor>.yaml`. Regenerate the icons with `make icons`.

## Folder structure

```
lib/
├── main_<flavor>.dart        # each one only calls bootstrap(Flavor.x)
├── bootstrap.dart            # config → DI → Bloc observer → error handlers → runApp
├── app/
│   ├── app.dart              # MaterialApp.router
│   ├── router/               # app_router.dart, route_names.dart, guards/, not_found_page.dart
│   └── di/                   # injection_container.dart (sl, initDependencies, resetDependencies)
├── core/                     # cross-cutting, feature-agnostic code
│   ├── bloc/  config/  constants/  error/  extensions/  l10n/
│   ├── logging/  network/  storage/  theme/  usecase/  utils/
├── shared/widgets/           # reusable UI (buttons, loaders, error/empty views, flavor banner)
└── features/
    └── example/              # reference feature: copy it for real features
        ├── example_injection.dart
        ├── data/{datasources,models,repositories}
        ├── domain/{entities,repositories,usecases}
        └── presentation/{bloc,pages,widgets}
test/                         # mirrors lib/; helpers/ holds mocks, fixtures, pumpApp, get_it reset
integration_test/
assets/{images,icons,fonts}/
env/                          # <flavor>.example.json (committed), <flavor>.json (ignored)
docs/                         # ARCHITECTURE.md, RENAMING.md
```

## How to add a new feature

**Quick way:** generate the whole slice with one command.

```bash
make feature NAME=orders ENTITY=order      # or: tool/new_feature.sh orders --entity order
```

This creates every layer below (entity, model, remote data source, repository, use case, bloc, page, widget, DI and a
bloc test). It also registers the feature in `initDependencies()`, adds a `/orders` route and runs codegen. Then
replace the placeholder fields marked `TODO(orders)`, set the API path, and run `make check`. Use `--no-wire` to skip
the DI and router changes.

**By hand:** use `features/example` as the template. For a feature called `orders`:

1. **Folders:** create `lib/features/orders/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{bloc,pages,widgets}}`
   and the same tree under `test/features/orders/`.
2. **Domain entity:** `domain/entities/order.dart`, a freezed class in pure Dart (no Flutter imports).
3. **Repository contract:** `domain/repositories/order_repository.dart`, an `abstract interface class` that returns
   `FutureEither<T>`.
4. **Use case(s):** `domain/usecases/get_orders_use_case.dart`, which implements `UseCase<T, Params>` (use `NoParams`
   when there's no input).
5. **Model:** `data/models/order_model.dart`, freezed with `fromJson`/`toJson` and a `toEntity()` mapper.
6. **Data sources:** `data/datasources/order_remote_data_source.dart` (and a local one if needed), each an
   abstract class plus an `…Impl`.
7. **Repository impl:** `data/repositories/order_repository_impl.dart`. Catch every exception and map it with
   `ErrorMapper.toFailure`.
8. **Bloc/Cubit:** `presentation/bloc/`, with freezed events and states. It depends on use cases only. Pick a
   `bloc_concurrency` transformer.
9. **Run** `make gen`.
10. **Page + widgets:** in `presentation/pages|widgets`. Add strings to `lib/core/l10n/app_en.arb`.
11. **DI:** `orders_injection.dart` with `registerOrdersDependencies(GetIt sl)`. Data sources, repositories and
    use cases use `registerLazySingleton<Abstract>`. Blocs use `registerFactory`. Call it from `initDependencies()`.
12. **Route:** add name and path constants to `route_names.dart`, then a `GoRoute` in `app_router.dart` whose builder
    wraps the page in `BlocProvider(create: (_) => sl<OrdersBloc>()..add(...))`.
13. **Tests:** model JSON, repository success/failure mapping, use case, `blocTest` for every event/state path,
    and a widget test with a `MockBloc`.
14. Run `make check`, then open a PR to `develop`.
