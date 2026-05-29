# Troubleshooting

Use this guide before opening an issue. If the problem remains, open the most
specific issue template and paste the sanitized diagnostics from Settings.

## Source Unavailable

- Source availability depends on upstream websites.
- Try refreshing the page or switching to another source in Source Settings.
- If a fallback notice appears, the selected source may be temporarily
  unavailable.
- When reporting, include the source name and whether fallback data was shown.

## Playback Fails

- Try a different playback source or line if one is available.
- Check whether the anime detail page loads correctly before opening playback.
- Do not paste full media URLs into issues. Include only the visible line name
  and the sanitized diagnostics package.

## Danmaku Unavailable

- Dandanplay credentials are optional.
- If Dandanplay is unavailable or no match is found, AniDestiny can fall back to
  mock danmaku data.
- Include whether danmaku was enabled and whether other playback features
  worked.

## Download Task Unsupported

- Direct media file downloads are supported for regular file URLs.
- HLS / m3u8 detection and manifest parsing are present, but full offline HLS
  segment download and merge are not implemented yet.
- BT / magnet links are detected as placeholders, but BT download is not
  implemented.
- Pause support is basic and may restart a direct download.

## Windows Launch Issues

- Download `AniDestiny-v<version>-windows-x64.zip`.
- Extract the ZIP before launching the app.
- Run `ani_destiny.exe` from the extracted folder.
- Keep the `data` directory and DLL files next to `ani_destiny.exe`.
- If Windows blocks the app, review the warning and only continue when the
  release source is trusted.

## macOS Gatekeeper

- Download `AniDestiny-v<version>-macos-universal.zip`.
- Extract the ZIP and open AniDestiny.app.
- Current artifacts are not distributed through the Mac App Store, so Gatekeeper
  may require a manual allow step.
- Only allow the app when the release source is trusted.

## Android Install Issues

- Download `AniDestiny-v<version>-android-universal.apk`.
- Make sure the APK is from the GitHub Releases page.
- Android may require allowing installs from the browser or file manager used
  to open the APK.
- If installation fails, include the Android version and exact install error.

## Copy Diagnostics

Open Settings and choose **Copy diagnostics**. The copied Markdown summary
includes app version, platform, source health, fallback, playback, danmaku, and
download task information.

Diagnostics are sanitized before copying, but users should still review the text
before posting. Remove any credential values, cookies, tokens, or full URLs with
query parameters if they appear.

## When Opening An Issue

- Use **Bug report** for general app problems.
- Use **Playback or source issue** for source, search/detail, playback, danmaku,
  or download-source problems.
- Use **Feature request** for new capabilities or workflow improvements.
- Include reproduction steps, expected behavior, actual behavior, platform, app
  version, and sanitized diagnostics when available.
