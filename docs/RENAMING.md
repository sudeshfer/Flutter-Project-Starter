# Renaming the app

The app uses these placeholders until the real name is decided:

| Placeholder | Example replacement |
| --- | --- |
| Dart package: `app_core` | `acme_garage` |
| Display name: `App Core` | `Acme Garage` |
| Base ID: `com.example.appcore` | `com.acme.garage` |
| Icon monogram: "AC" | your brand icon |

> **Shortcut:** to start a *new* app from this template, `tool/new_app.sh` does sections 1–3 for you in a fresh
> copy (run it with `--help`). The steps below are for renaming this repo in place, or for checking what the
> script changed. Sections 4–7 are still manual either way.

Do the rename on its own branch (`chore/rename-app`) in a single PR. Run the commands below from the repo root and
replace the example values with the real ones.

```bash
NEW_PKG=acme_garage
NEW_NAME="Acme Garage"
NEW_ID=com.acme.garage
```

## 1. Dart package name

The package name appears in `pubspec.yaml` and in every `package:app_core/` import (the project uses package
imports everywhere).

```bash
sed -i '' "s/^name: app_core$/name: $NEW_PKG/" pubspec.yaml
grep -rl "package:app_core/" lib test integration_test | xargs sed -i '' "s#package:app_core/#package:$NEW_PKG/#g"
```

On Linux, use `sed -i` instead of `sed -i ''`.

## 2. Display names (all flavors)

| File | What to change |
| --- | --- |
| `lib/core/constants/app_constants.dart` | `AppConstants.appName`. This is the only place in Dart; flavor suffixes (DEV/QA/STG/UAT) are added automatically |
| `android/app/build.gradle.kts` | `resValue("string", "app_name", "...")` in each of the four `productFlavors` |
| `ios/Flutter/Flavors/{dev,qa,staging,uat,prod}.xcconfig` | `DISPLAY_NAME = ...` |
| `ios/Runner.xcodeproj/project.pbxproj` | `DISPLAY_NAME = "App Core"` on the base Debug/Release/Profile configs (used only by non-flavored builds) |
| `test/core/config/app_config_test.dart` | Expected app names |
| `README.md`, `.github/` docs | Text mentions |

```bash
grep -rl "App Core" --include="*.dart" --include="*.kts" --include="*.xcconfig" --include="*.pbxproj" --include="*.md" . \
  | grep -v "/.fvm/" | xargs sed -i '' "s/App Core/$NEW_NAME/g"
```

## 3. Bundle ID / application ID (all flavors)

The suffixes stay the same: `.dev`, `.qa`, `.stg` and `.uat`, with no suffix for prod.

| File | What to change |
| --- | --- |
| `android/app/build.gradle.kts` | `namespace` and `applicationId` in `defaultConfig` |
| `android/app/src/main/kotlin/com/example/appcore/MainActivity.kt` | `package` line, and move the file to the new package folder |
| `ios/Flutter/Flavors/*.xcconfig` | `PRODUCT_BUNDLE_IDENTIFIER` |
| `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` on the base configs and `RunnerTests` |

```bash
grep -rl "com.example.appcore" android ios | xargs sed -i '' "s/com\.example\.appcore/$NEW_ID/g"

# Move MainActivity to the new package directory
NEW_DIR=android/app/src/main/kotlin/$(echo $NEW_ID | tr . /)
mkdir -p "$NEW_DIR"
git mv android/app/src/main/kotlin/com/example/appcore/MainActivity.kt "$NEW_DIR/"
```

> ⚠️ Changing the bundle or application ID after a store release creates a *new* app. Do the rename before the
> first store upload.

## 4. iOS / Android config to double-check

- **iOS signing:** in Xcode (*Runner → Signing & Capabilities*), set the team for **every** configuration
  (`Debug-dev` … `Release-prod`). Register the four bundle IDs in the Apple Developer portal.
- **Android:** if Firebase is added, you need four `google-services.json` files, in
  `android/app/src/{dev,qa,staging,uat,prod}/`.
- **iOS Firebase:** you need one `GoogleService-Info.plist` per flavor, copied by a build phase.
- Search for leftovers. This should print nothing except this file:
  ```bash
  grep -rIn "app_core\|appcore\|appCore\|App Core" --exclude-dir={.fvm,build,.dart_tool,.git} .
  ```

## 5. Launcher icons

1. Replace the images in `assets/icons/launcher/`:
   - `app_icon_<flavor>.png`: 1024×1024, no transparency. Prod is the clean icon; dev, qa, staging and uat get a
     ribbon or badge.
   - `app_icon_<flavor>_foreground.png`: 1024×1024 Android adaptive foreground. Keep the artwork inside the
     central 66%.
2. Update `adaptive_icon_background` in each `flutter_launcher_icons-<flavor>.yaml` if the brand colour changes.
3. Run `make icons`.

## 6. Verify

```bash
fvm flutter clean
make get gen
make check
for f in dev qa staging uat prod; do
  fvm flutter build apk --debug --flavor $f -t lib/main_$f.dart --dart-define-from-file=env/$f.json
done
make build-ios-nosign FLAVOR=prod
```

Then install all four flavors on one device. Check that the names, icons and banners are correct and that the apps
install side by side.

## 7. Repository (optional)

Rename the GitHub repo under *Settings → General → Repository name*. GitHub redirects the old URL, but each
developer should still run:

```bash
git remote set-url origin git@github.com:<org>/<new-repo>.git
```
