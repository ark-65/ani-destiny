<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# AniDestiny Changelog

> [中文更新日志](./CHANGELOG.md) | English Changelog

## [Unreleased]

### ✨ Added
- Added a release page entry, runtime diagnostics page, and copyable feedback summary for playback and source issues.
- Added source health state, failure counts, recent issue summaries, and manual reset support.
- Added automatic fallback from the selected source to available backup sources.
- Added persistent source health state and reset support.
- Added fallback notices so users can tell when fallback data is being shown.
- Added source diagnostics for recent failures and fallback events.

### 🔄 Changed
- Improved Home, Search, Detail, Schedule, and History flows when the selected source is temporarily unavailable.
- Improved Source Settings with health status, failure count, and reset controls.
- Improved playback diagnostics and URL sanitization to avoid exposing query tokens, header values, or other sensitive details in feedback summaries.
- Kept empty search results as a normal empty state instead of treating them as source failures that trigger fallback.

### 🐛 Fixed
- Fixed empty detail episodes and empty play-source lists not being treated as source failures, allowing automatic fallback to run.

### 📚 Documentation
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
