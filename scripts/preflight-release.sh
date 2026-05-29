#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Running AniDestiny release preflight from $ROOT_DIR"
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
git diff --check

cat <<'NEXT'
Release preflight passed.

Recommended platform build checks before publishing:
- flutter build apk --debug
- flutter build macos
- flutter build windows --release on a Windows host or Windows CI runner
NEXT
