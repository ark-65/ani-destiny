<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# AniDestiny 更新日志

> 中文更新日志 | [English Changelog](./CHANGELOG_en.md)

## [Unreleased]

### Planned
- 完善 source fallback 和 Sakura 失败提示。
- 完善播放诊断与反馈时可复制的运行摘要。
- 继续打磨下载任务体验。

## [1.0.1] - 2026-05-28

### ✨ 新增
- 支持 Android、Windows 和 macOS 的跨平台应用发布验证。
- 新增 Sakura 数据源适配器。
- 新增视频播放、观看历史、收藏和基础下载任务。
- 新增弹幕 overlay、弹弹play 可选集成和 fallback。
- 新增构建脚本与多平台发布流程。

### 🔄 变更
- 稳定 Android 播放器生命周期。
- 改进从观看历史恢复播放。
- 改进数据源诊断记录。

### 🔧 CI/CD
- 新增 Flutter 质量检查、双语 changelog 门禁、手动预发布 PR 和多平台发布工作流。
- 发布流程改为先创建可审核的 release PR，合并后再读取中文 changelog、创建 tag、构建并发布多平台产物。

### 📚 文档
- 将主 README 改为中文文档，并新增英文文档 `README_en.md`。
- 新增中文主更新日志 `CHANGELOG.md` 和英文扩展更新日志 `CHANGELOG_en.md`。

### 已知限制
- 数据源可用性依赖上游网站。
- 弹弹play 凭据为可选配置；不可用时会使用 fallback。
- 下载支持仍为基础能力。

## [1.0.0] - 2026-05-28

### ✨ 新增
- 新增 AniDestiny Flutter App 基础架构。
- 新增 Sakura 真实数据源解析，支持首页、搜索、番剧详情、剧集列表和播放源。
- 新增播放页基础控制、弹幕 overlay、Dandanplay 接入结构和 mock fallback。
- 新增历史记录、收藏和下载任务的本地持久化。
- 新增中文、英文、日文界面语言。

### 🔧 CI/CD
- 初始版本通过本地 `flutter analyze`、`flutter test`、Android debug/release 构建和 macOS release 构建验证。
