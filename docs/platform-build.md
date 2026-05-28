# Platform Build Notes

AniDestiny supports local Flutter builds for Android, macOS, Windows, and Linux.

## Quick Checks

Run from the repository root:

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## Local Scripts

```sh
bash scripts/clean.sh
bash scripts/build-android-debug.sh
```

The Android debug APK is written to:

```txt
build/app/outputs/flutter-apk/app-debug.apk
```

## Release Builds

```sh
flutter build apk --release
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

Windows builds require a Windows host or runner. macOS builds require a macOS
host or runner. iOS distribution requires signing certificates and the App Store
release flow, so it is not part of the current public release artifacts.
