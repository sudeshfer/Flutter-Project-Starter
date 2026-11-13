#!/usr/bin/env bash
# Bump the app version in pubspec.yaml (version: X.Y.Z+BUILD).
#
# Usage:
#   tool/bump_version.sh <major|minor|patch|build|X.Y.Z> [--tag]
#   make bump PART=patch [TAG=1]
#   make version                       # print the current version
#
#   major|minor|patch  Bump that part (lower parts reset to 0)
#   build              Only increment the build number
#   X.Y.Z              Set an exact version name
#   --tag              Commit pubspec.yaml and create git tag vX.Y.Z+BUILD
#
# The build number ALWAYS increases: both stores reject an upload that reuses one.
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }
usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

PART="" TAG=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG=1; shift ;;
    -h|--help) usage 0 ;;
    -*) echo "unknown option: $1" >&2; usage 1 ;;
    *) [[ -z "$PART" ]] || usage 1; PART="$1"; shift ;;
  esac
done
[[ -n "$PART" ]] || usage 1

cd "$(dirname "$0")/.."
LINE="$(grep -E '^version:' pubspec.yaml || true)"
[[ "$LINE" =~ ^version:\ *([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)\ *$ ]] \
  || die "pubspec.yaml needs a line like 'version: 1.2.3+4' (found: '${LINE:-nothing}')"
MAJOR=${BASH_REMATCH[1]} MINOR=${BASH_REMATCH[2]} PATCH=${BASH_REMATCH[3]} BUILD=${BASH_REMATCH[4]}
OLD="$MAJOR.$MINOR.$PATCH+$BUILD"

case "$PART" in
  major) MAJOR=$((MAJOR + 1)) MINOR=0 PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)) PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
  build) ;;
  *)
    [[ "$PART" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || die "unknown part '$PART' (use major, minor, patch, build or X.Y.Z)"
    MAJOR=$((10#${BASH_REMATCH[1]})) MINOR=$((10#${BASH_REMATCH[2]})) PATCH=$((10#${BASH_REMATCH[3]}))
    ;;
esac
BUILD=$((BUILD + 1))
NEW="$MAJOR.$MINOR.$PATCH+$BUILD"

if [[ $TAG -eq 1 ]]; then
  git rev-parse --git-dir >/dev/null 2>&1 || die "--tag needs a git repository"
  git diff --quiet -- pubspec.yaml && git diff --cached --quiet -- pubspec.yaml \
    || die "pubspec.yaml has uncommitted changes; commit or stash them first"
  git rev-parse -q --verify "refs/tags/v$NEW" >/dev/null && die "tag v$NEW already exists"
fi

perl -pi -e "s/^version:.*\$/version: $NEW/" pubspec.yaml
echo "Version: $OLD -> $NEW"

if [[ $TAG -eq 1 ]]; then
  git add pubspec.yaml
  git commit -q -m "chore: bump version to $NEW"
  git tag -a "v$NEW" -m "v$NEW"
  echo "Committed and tagged v$NEW (push with: git push && git push origin v$NEW)"
fi
