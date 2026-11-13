#!/usr/bin/env bash
# Create a new Flutter app from this starter.
#
# Usage:
#   tool/new_app.sh --name "Acme Garage" --package acme_garage --id com.acme.garage [--dest ../acme_garage] [--setup]
#
#   --name     Display name shown under the launcher icon (flavor suffixes DEV/QA/STG/UAT are added automatically)
#   --package  Dart package name (lower_snake_case)
#   --id       Base bundle / application ID (reverse-DNS). Flavors get .dev .qa .stg .uat; prod has no suffix
#   --dest     Where to create the app (default: ../<package>)
#   --setup    Also run `make setup` (fvm install, env files, pub get, codegen) in the new app
#
# The template itself is never modified.
set -euo pipefail

TEMPLATE_PKG="app_core"
TEMPLATE_NAME="App Core"
TEMPLATE_ID="com.example.appcore"

die() { echo "error: $*" >&2; exit 1; }
usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

NEW_NAME="" NEW_PKG="" NEW_ID="" DEST="" SETUP=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NEW_NAME="${2:-}"; shift 2 ;;
    --package) NEW_PKG="${2:-}"; shift 2 ;;
    --id) NEW_ID="${2:-}"; shift 2 ;;
    --dest) DEST="${2:-}"; shift 2 ;;
    --setup) SETUP=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "unknown option: $1" >&2; usage 1 ;;
  esac
done

[[ -n "$NEW_NAME" && -n "$NEW_PKG" && -n "$NEW_ID" ]] || usage 1
[[ "$NEW_PKG" =~ ^[a-z][a-z0-9_]*$ ]] || die "--package must be lower_snake_case, e.g. acme_garage"
[[ "$NEW_ID" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]] \
  || die "--id must be reverse-DNS with lowercase segments starting with a letter, e.g. com.acme.garage"
[[ "$NEW_NAME" != *$'\n'* && "$NEW_NAME" != *'"'* ]] || die "--name must not contain quotes or newlines"

TEMPLATE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${DEST:-$TEMPLATE_DIR/../$NEW_PKG}"
[[ -e "$DEST" ]] && die "$DEST already exists"
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"

echo "==> Copying template to $DEST"
rsync -a \
  --include='env/*.example.json' --exclude='env/*.json' \
  --exclude='.git/' --exclude='.fvm/' --exclude='.dart_tool/' --exclude='/build/' --exclude='/coverage/' \
  --exclude='.idea/' --exclude='*.iml' --exclude='.DS_Store' \
  --exclude='.flutter-plugins' --exclude='.flutter-plugins-dependencies' \
  --exclude='*.g.dart' --exclude='*.freezed.dart' --exclude='lib/core/l10n/gen/' \
  --exclude='ios/Pods/' --exclude='ios/.symlinks/' --exclude='ios/Flutter/ephemeral/' \
  --exclude='ios/Flutter/Generated.xcconfig' --exclude='ios/Flutter/flutter_export_environment.sh' \
  --exclude='xcuserdata/' --exclude='android/.gradle/' --exclude='android/.kotlin/' \
  --exclude='android/local.properties' \
  --exclude='/tool/new_app.sh' --exclude='/docs/RENAMING.md' \
  "$TEMPLATE_DIR/" "$DEST/"
rmdir "$DEST/tool" 2>/dev/null || true

cd "$DEST"
export NEW_NAME NEW_PKG NEW_ID TEMPLATE_PKG TEMPLATE_NAME TEMPLATE_ID

echo "==> Cleaning up 'name not decided yet' notes"
# README: drop the "(working title)" suffix and the codename note block under the title.
perl -0pi -e 's/^# \Q$ENV{TEMPLATE_NAME}\E \(working title\)\n\n(?:>.*\n)+\n/# $ENV{TEMPLATE_NAME}\n\n/m' README.md
perl -pi -e 's/, RENAMING\.md//' README.md
perl -pi -e 's/^description: .*/description: "$ENV{NEW_NAME} Flutter app."/' pubspec.yaml
perl -ni -e 'print unless m{^// Codename values: see docs/RENAMING\.md\.$}' ios/Flutter/Flavors/*.xcconfig
perl -pi -e 's{ Codename: see docs/RENAMING\.md\.}{}' android/app/build.gradle.kts
perl -ni -e 'print unless m{^/// See docs/RENAMING\.md when the final name is decided\.$}' lib/core/constants/app_constants.dart
perl -pi -e 's/cd garage-app/cd $ENV{NEW_PKG}/' README.md

echo "==> Renaming $TEMPLATE_ID -> $NEW_ID, $TEMPLATE_PKG -> $NEW_PKG, '$TEMPLATE_NAME' -> '$NEW_NAME'"
grep -rIl -e "$TEMPLATE_ID" -e "$TEMPLATE_PKG" -e "$TEMPLATE_NAME" . | while IFS= read -r f; do
  perl -pi -e '
    s/\Q$ENV{TEMPLATE_ID}\E/$ENV{NEW_ID}/g;
    s/\Q$ENV{TEMPLATE_PKG}\E/$ENV{NEW_PKG}/g;
    s/\Q$ENV{TEMPLATE_NAME}\E/$ENV{NEW_NAME}/g;
  ' "$f"
done

echo "==> Moving MainActivity to the new Kotlin package"
KOTLIN_ROOT=android/app/src/main/kotlin
OLD_KT_DIR="$KOTLIN_ROOT/$(tr . / <<<"$TEMPLATE_ID")"
NEW_KT_DIR="$KOTLIN_ROOT/$(tr . / <<<"$NEW_ID")"
if [[ "$OLD_KT_DIR" != "$NEW_KT_DIR" ]]; then
  mkdir -p "$NEW_KT_DIR"
  mv "$OLD_KT_DIR"/* "$NEW_KT_DIR/"
  # Remove now-empty old package folders (com/example/appcore -> com/example -> com).
  d="$OLD_KT_DIR"
  while [[ "$d" != "$KOTLIN_ROOT" ]] && rmdir "$d" 2>/dev/null; do d="$(dirname "$d")"; done
fi

echo "==> Checking for leftovers"
if LEFT=$(grep -rIn -e "$TEMPLATE_PKG" -e "appcore" -e "$TEMPLATE_NAME" -e "RENAMING" . ); then
  echo "warning: template names still present:" >&2
  echo "$LEFT" >&2
fi

git init -q
echo "==> Initialised git repo"

if [[ $SETUP -eq 1 ]]; then
  echo "==> Running make setup"
  make setup
fi

cat <<EOF

Done: $DEST

Next steps:
  cd "$DEST"
$( [[ $SETUP -eq 1 ]] || echo "  make setup                 # fvm install, env files, pub get, codegen" )
  # fill in env/*.json with real API URLs/keys
  make run-dev
  make check                 # format, analyze, test

Still manual (see README):
  - Launcher icons: replace assets/icons/launcher/*, then 'make icons'
  - iOS signing team for every configuration in Xcode
  - Register the bundle IDs ($NEW_ID, .dev, .qa, .stg, .uat) with Apple / Play
  - Update .github/CODEOWNERS
EOF
