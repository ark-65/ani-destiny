<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# AniDestiny Changelog

> [中文更新日志](./CHANGELOG.md) | English Changelog

## [Unreleased]

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
