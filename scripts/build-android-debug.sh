#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Building Android debug APK from $ROOT_DIR"
flutter pub get
flutter build apk --debug
echo "Android debug APK: $ROOT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
