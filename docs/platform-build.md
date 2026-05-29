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

Suggested local artifact name:

```txt
AniDestiny-v1.0.1-android-debug.apk
```

## App Icon Assets

The source logo is stored under:

```txt
assets/branding/
```

The standard logo copies are:

```txt
assets/branding/ani_destiny_logo.png
assets/branding/ani_destiny_icon.png
assets/branding/ani_destiny_icon_1024.png
```

These files are copied or resized from the existing project logo at
`assets/brand/logo.png`.

## Android Icon

Android launcher icons are stored under:

```txt
android/app/src/main/res/mipmap-*/
```

## Windows Icon

The Windows icon is stored at:

```txt
windows/runner/resources/app_icon.ico
```

## macOS Icon

The macOS AppIcon images are stored under:

```txt
macos/Runner/Assets.xcassets/AppIcon.appiconset/
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

## Release Asset Naming

Release assets should use stable platform and architecture suffixes:

```txt
AniDestiny-v1.0.1-android-debug.apk
AniDestiny-v1.0.1-android.apk
AniDestiny-v1.0.1-macos-universal.zip
AniDestiny-v1.0.1-windows-x64.zip
AniDestiny-v1.0.1-linux-x64.tar.gz
```
