<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# AniDestiny Changelog

> [中文更新日志](./CHANGELOG.md) | English Changelog

## [Unreleased]

### 🐛 Fixed
- Fixed Source Settings exposing raw technical identifiers like `id: mock` and `id: sakura` to users, so it now shows only localized names and descriptions.
- Fixed Source Settings still describing Mock as the most stable source, replacing it with neutral copy that matches the production default `sakura`.
- Fixed the search empty state still telling users to search the Mock source, replacing it with neutral copy for normal browsing.
- Fixed the downloads page exposing the Mock test-task action to regular users by default; it now only appears in debug builds.
- Fixed the player route falling back to the Mock source when `sourceId` is missing, so it now uses the default production source `sakura`.
- Fixed episode cards and the watch-history model still defaulting missing source metadata to Mock, so they now align with the production default source `sakura`.
- Fixed completed download tasks not offering direct removal, so finished records can now be cleared from the list.
- Fixed failed download tasks only offering cancel, so they now keep retry and allow direct removal.
- Fixed failed download tasks still showing the pause note even though they only support retry or removal.
- Fixed failed download tasks still showing a generic Start action, replacing it with a clear Retry label and icon.
- Fixed download progress labels showing values outside `0%` to `100%`, so out-of-range progress no longer leaks into the list UI.
- Fixed canceled download tasks being rendered as errors and reported as the latest diagnostics issue, avoiding misleading warnings after user-initiated cancellation.
- Fixed the downloads page only allowing one-by-one cleanup, adding a single action to clear completed, failed, canceled, and unsupported tasks together.
- Fixed batch cleanup stopping on the first deletion failure with no feedback, so the downloads page now keeps clearing the remaining ended tasks and reports the result; pause, cancel, and remove failures also surface immediately.
- Fixed batch cleanup staying tappable while it was already running, so the same ended tasks cannot be deleted repeatedly.
- Fixed per-task start, pause, cancel, retry, and remove actions staying tappable while they were already running, so each task now enters a busy state and blocks duplicate taps.
- Fixed ended tasks that were already being removed individually still being picked up by batch cleanup, preventing duplicate concurrent deletion attempts for the same task.
- Fixed batch cleanup still being available while an ended task action was already running, preventing overlapping cleanup flows and confusing feedback.

### 🔧 CI/CD
- Stabilized widget-test targeting for downloads cleanup and task actions so Flutter CI does not misread button structure differences as failures.
- Fixed flaky busy-state test waits and overly broad cleanup loading assertions so CI no longer fails on active progress indicators.

### 📚 Documentation
- Added GitHub issue templates for general bugs, playback/source issues, and feature requests.
- Added troubleshooting documentation for source, playback, danmaku, download, install, and diagnostics-copy flows.
- Updated README and reporting docs to guide users toward templates and sanitized diagnostics.
- Clarified release asset platform selection and changed the Android debug artifact example to use a version placeholder.

## [1.0.2] - 2026-05-29

### ✨ Added
- Added download type detection for direct files, HLS/m3u8, BT placeholders, and unknown URLs.
- Added an HLS/m3u8 manifest parser foundation for media and master playlists.
- Added download task fields for failure reasons, headers, byte progress, and local paths.
- Added a Copy diagnostics entry in Settings that generates a sanitized Markdown feedback summary.
- Added a feedback diagnostics package with app version, platform, source health, fallback, playback, danmaku, and download task status.
- Added a standard brand asset directory using the existing AniDestiny logo as the README and platform icon source.
- Added Android, Windows, and macOS platform icon assets generated from the existing logo.
- Added a release page entry, runtime diagnostics page, and copyable feedback summary for playback and source issues.
- Added source health state, failure counts, recent issue summaries, and manual reset support.
- Added automatic fallback from the selected source to available backup sources.
- Added persistent source health state and reset support.
- Added fallback notices so users can tell when fallback data is being shown.
- Added source diagnostics for recent failures and fallback events.
- Added source health summaries and recent fallback events to runtime diagnostics.

### 🔄 Changed
- Refreshed AniDestiny logo artwork and synced the README brand image, Android launcher icon, Windows icon, and macOS AppIcon.
- Redesigned the download task model and states; the downloads page now shows task type, status, progress, failure reason, and local path.
- Stabilized the direct-file download path while keeping HLS offline and BT downloads clearly marked as not implemented yet.
- Improved Home, Search, Detail, Schedule, History, and Player flows when the selected source is temporarily unavailable.
- Improved Source Settings with health status, failure count, and reset controls.
- Improved playback diagnostics and URL sanitization to avoid exposing query tokens, header values, or other sensitive details in feedback summaries.
- Kept empty search results as a normal empty state instead of treating them as source failures that trigger fallback.

### 🐛 Fixed
- Fixed empty detail episodes and empty play-source lists not being treated as source failures, allowing automatic fallback to run.

### 🔧 CI/CD
- Added a Windows Build CI job that verifies `flutter build windows --release` on `windows-latest` and uploads a temporary Windows x64 artifact.
- Added a release preflight script and pre-release quality gate checklist.
- Changed Android release asset naming to use the universal APK suffix and documented the arm64 naming rule.
- Changed macOS and Windows release asset names to include platform and architecture suffixes.
- Fixed release rebuild handling, Linux release dependencies, and release publishing checkout context.
- Changed release preparation PRs and GitHub Release notes to publish only user-facing Added, Changed, and Fixed sections.
- Added a `changelog correction` PR label path for controlled fixes to released changelog sections while still requiring `[Unreleased]` updates.
- Added Android debug build and clean scripts, plus post-release validation configuration.

### 📚 Documentation
- Added Windows CI build output path, temporary artifact, and EXE / taskbar icon verification notes.
- Added an issue reporting guide for playback, source, danmaku, and download diagnostics.
- Added Android, Windows, and macOS release smoke checklists.
- Added release asset naming, Windows build verification, and current capability boundary notes.
- Added download path, Android permission policy, and not-yet-implemented scope notes.
- Updated README visuals, platform notes, screenshot placeholders, and brand asset references.
- Added platform icon paths and release asset naming notes to platform build documentation.
- Updated the Chinese and English READMEs and platform build notes.
- Moved post-release changelog content back under `[Unreleased]` so the released `1.0.1` record stays stable.

### Known Limitations
- Fallback data may not always map perfectly between different sources.
- Source availability still depends on upstream websites.
- Dandanplay credentials are optional; fallback is used when unavailable.
- Download support is still basic.
## [1.0.1] - 2026-05-28

### 🔧 CI/CD
- Added Flutter quality checks, bilingual changelog gate, manual release preparation PR, and multi-platform release workflows.
- Changed releases to use a reviewed release PR first, then read the Chinese changelog, create the tag, build artifacts, and publish the release after merge.

### 📚 Documentation
- Changed the main README to Chinese and added `README_en.md`.
- Added the Chinese primary changelog `CHANGELOG.md` and English secondary changelog `CHANGELOG_en.md`.

## [1.0.0] - 2026-05-28

### ✨ Added
- Added the AniDestiny Flutter app foundation.
- Added Sakura live source parsing for home, search, anime detail, episode list, and play sources.
- Added player controls, danmaku overlay, Dandanplay integration structure, and mock fallback.
- Added local persistence for watch history, favorites, and download tasks.
- Added Chinese, English, and Japanese UI languages.

### 🔧 CI/CD
- Verified the initial version locally with `flutter analyze`, `flutter test`, Android debug/release builds, and macOS release build.
