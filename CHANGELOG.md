<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# AniDestiny 更新日志

> 中文更新日志 | [English Changelog](./CHANGELOG_en.md)

## [Unreleased]

### ✨ 新增
- 新增发布页入口、运行诊断页和可复制的反馈摘要，方便用户反馈播放和数据源问题。
- 新增数据源健康状态、失败计数、最近问题摘要和手动重置能力。
- 新增所选数据源不可用时自动回退到可用备用数据源的能力。
- 新增持久化数据源健康状态和手动重置支持。
- 新增 fallback 提示，让用户知道当前是否正在展示备用数据。
- 新增最近失败和 fallback 事件的数据源诊断信息。

### 🔄 变更
- 改进首页、搜索、详情、排期和历史流程在所选数据源暂时不可用时的恢复路径。
- 改进 Source Settings，显示健康状态、失败次数和重置控件。
- 改进播放诊断和 URL 脱敏，避免反馈摘要暴露 query token、header 值或其他敏感信息。
- 搜索空结果保持为正常空状态，不再作为数据源失败触发 fallback。

### 🐛 修复
- 修复空详情剧集和空播放源未被视为数据源失败的问题，确保自动 fallback 能够生效。

### 📚 文档
- 将发布后新增的 changelog 内容移回 `[Unreleased]`，避免继续修改已发布的 `1.0.1` 记录。

### 已知限制
- 不同数据源之间的 fallback 数据可能无法完全映射。
- 数据源可用性仍依赖上游网站。
- 弹弹play 凭据为可选配置；不可用时会使用 fallback。
- 下载支持仍为基础能力。

## [1.0.1] - 2026-05-28

### 🔧 CI/CD
- 新增 Flutter 质量检查、双语 changelog 门禁、手动预发布 PR 和多平台发布工作流。
- 发布流程改为先创建可审核的 release PR，合并后再读取中文 changelog、创建 tag、构建并发布多平台产物。

### 📚 文档
- 将主 README 改为中文文档，并新增英文文档 `README_en.md`。
- 新增中文主更新日志 `CHANGELOG.md` 和英文扩展更新日志 `CHANGELOG_en.md`。

## [1.0.0] - 2026-05-28

### ✨ 新增
- 新增 AniDestiny Flutter App 基础架构。
- 新增 Sakura 真实数据源解析，支持首页、搜索、番剧详情、剧集列表和播放源。
- 新增播放页基础控制、弹幕 overlay、Dandanplay 接入结构和 mock fallback。
- 新增历史记录、收藏和下载任务的本地持久化。
- 新增中文、英文、日文界面语言。

### 🔧 CI/CD
- 初始版本通过本地 `flutter analyze`、`flutter test`、Android debug/release 构建和 macOS release 构建验证。
