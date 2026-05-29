<p align="center">
  <img src="assets/branding/ani_destiny_logo.png" alt="AniDestiny" width="180">
</p>

# AniDestiny

> [中文](./README.md) | English

AniDestiny is a non-profit Flutter anime discovery, playback, and danmaku learning project.

## Project

This project is for learning, research, and Flutter architecture practice only. It has no commercial purpose.

AniDestiny currently uses a client-side source adapter architecture:

- Default source: Sakura Anime website parser source.
- Fallback source: Mock anime source for offline demos and development fallback.
- Future extension: Remote Source Proxy, self-hosted source proxy, and additional public sources.

## Links

- Open source: <https://github.com/ark-65/ani-destiny>
- Releases: <https://github.com/ark-65/ani-destiny/releases>
- Chinese changelog: [CHANGELOG.md](./CHANGELOG.md)
- English changelog: [CHANGELOG_en.md](./CHANGELOG_en.md)

## Platforms

AniDestiny currently validates builds for Android, macOS, Windows, and Linux.

## Project Identity

- App Name: AniDestiny
- Flutter package: ani_destiny
- Android applicationId: com.ark65.anidestiny
- iOS bundleId: com.ark65.anidestiny
- Brand assets: `assets/branding/`

## Current Features

- Home recommendations, search, anime detail, and episode list.
- Sakura live source parsing for home, search, detail, play sources, and diagnostics.
- Player controls, speed selection, fullscreen mode, and playback diagnostics.
- Dandanplay danmaku integration structure with mock fallback.
- Local persistence for watch history, favorites, and download tasks, with direct-file download support and HLS/BT type detection placeholders.
- UI localization: Chinese, English, and Japanese.
- Release build workflow for Android, macOS, Windows, and Linux.

## Screenshots

Screenshots will be added in a future release.

## Development

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

## Local Scripts

```sh
bash scripts/clean.sh
bash scripts/build-android-debug.sh
bash scripts/preflight-release.sh
```

See [docs/platform-build.md](./docs/platform-build.md) for platform build notes, [docs/release-checklist.md](./docs/release-checklist.md) for pre-release checks, and [docs/downloads.md](./docs/downloads.md) for download paths and permission policy.

## Manual Packaging

```sh
flutter build apk --release
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

Notes:

- Windows artifacts must be built on a Windows host or Windows CI runner.
- macOS artifacts must be built on a macOS host or macOS CI runner.
- iOS release distribution requires certificates, signing, and App Store distribution, so it is not published as a public automated artifact yet.

## Release Flow

This repository uses a reviewed release PR flow:

1. Regular PRs should update the `[Unreleased]` section in both `CHANGELOG.md` and `CHANGELOG_en.md`.
2. Manually run the `Prepare Release` workflow in GitHub Actions with the target version.
3. The workflow updates `pubspec.yaml`, archives Chinese and English changelog entries, and opens a `release/vX.Y.Z` PR.
4. A maintainer reviews and merges the release PR.
5. The `Release` workflow reads the Chinese release notes from `CHANGELOG.md`, creates the tag, builds multi-platform artifacts, and publishes the GitHub Release.

## Release Artifacts

Release CI uploads:

- Android universal APK
- macOS universal ZIP
- Windows x64 ZIP
- Linux tar.gz

## License Notice

This project is inspired by Animius.
Please keep original project attribution and license notes where applicable.
