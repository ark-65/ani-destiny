# Release Checklist

Use this checklist before publishing a new AniDestiny release.

## Preflight

- Version is correct in `pubspec.yaml`.
- `CHANGELOG.md` and `CHANGELOG_en.md` are updated under `[Unreleased]`.
- Release notes are prepared from user-facing Added, Changed, and Fixed sections.
- Source fallback smoke passed.
- Download task smoke passed.
- App icon smoke passed.
- `bash scripts/preflight-release.sh` passed.
- Android debug build passed.
- macOS build passed on macOS.
- Windows Build CI passed on `windows-latest`.
- Windows CI artifact is available for inspection when needed.

## Android

- Install APK.
- Launch app.
- Check launcher icon.
- Search.
- Play video.
- Toggle danmaku.
- Resume from history.
- Create direct download task.
- Verify unsupported HLS task message.
- Verify source fallback notice when the selected source is unavailable.

## Windows

- Launch app.
- Check EXE and taskbar icon.
- Confirm `ani_destiny.exe` exists in `build/windows/x64/runner/Release/`.
- Search.
- Play video.
- Create direct download task.
- Verify unsupported HLS task message.
- Check source fallback notice.
- Confirm release ZIP name is `AniDestiny-v<version>-windows-x64.zip`.

## macOS

- Launch app.
- Check Dock icon.
- Search.
- Play video.
- Toggle fullscreen.
- Check history resume.
- Create direct download task.
- Verify unsupported HLS task message.
- Confirm release ZIP name is `AniDestiny-v<version>-macos-universal.zip`.

## Feature Notes

- Source fallback resilience should show fallback notices instead of silently switching data.
- Direct file downloads are supported for regular media file URLs.
- HLS / m3u8 detection and manifest parsing are present, but full offline HLS segment download and merge are not implemented.
- BT / magnet links are detected as placeholders, but BT download is not implemented.
- Dandanplay is optional and should fall back cleanly when unavailable.
- Platform icon assets should appear on Android launcher, Windows taskbar / EXE, and macOS Dock.
