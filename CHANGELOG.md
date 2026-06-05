<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# AniDestiny 更新日志

> 中文更新日志 | [English Changelog](./CHANGELOG_en.md)

## [Unreleased]

### 🐛 修复
- 修复数据源设置页向普通用户暴露 `id: mock`、`id: sakura` 等内部技术标识的问题，改为仅展示本地化名称和说明。
- 修复设置页仍将 Mock 描述为最稳定数据源的问题，改为面向正式默认源 `sakura` 的中性说明。
- 修复搜索页空状态仍提示用户搜索 Mock 数据源的问题，改为面向正式使用场景的中性引导文案。
- 修复下载页默认向普通用户暴露 Mock 测试任务入口的问题，改为仅在 debug 环境显示该操作。
- 修复播放器路由在缺少 `sourceId` 时默认回退到 Mock 数据源的问题，改为使用正式默认源 `sakura`。
- 修复剧集列表和历史记录模型在缺少来源信息时仍默认回落到 Mock 的问题，改为统一使用正式默认源 `sakura`。
- 修复下载页中已完成任务无法直接移除的问题，允许清理已完成记录。
- 修复下载页中失败任务只能取消不能直接清理的问题，失败任务现在保留重试并支持直接移除。
- 修复下载页中失败任务仍显示暂停提示的问题，避免在仅支持重试/移除时产生误导。
- 修复下载页中失败任务仍显示“开始”按钮的问题，改为明确的“重试”按钮和图标。
- 修复下载进度百分比文案未限制在 `0%` 到 `100%` 的问题，避免异常进度值直接暴露在列表中。
- 修复已取消下载任务仍被渲染为错误并进入最新诊断问题的问题，避免取消操作产生误导性告警。
- 修复下载页只能逐条清理已结束任务的问题，新增一键清理已完成、失败、取消和暂不支持任务的入口。
- 修复下载页批量清理在单条删除失败时会中断且无反馈的问题，改为继续处理剩余任务并提示清理结果；暂停、取消和移除失败也会直接提示错误。
- 修复下载页批量清理执行中仍可重复点击的问题，避免同一批已结束任务被重复删除。
- 修复下载任务单条开始、暂停、取消、重试和移除操作执行中仍可重复点击的问题，改为按任务进入忙碌态并禁用重复触发。
- 修复下载页在单条移除进行中仍可将同一任务纳入批量清理的问题，避免并发重复删除同一条结束任务。
- 修复下载页在结束态任务单条操作进行中仍可触发批量清理的问题，避免多个结束态清理流程并行造成反馈混乱。

### 🔧 CI/CD
- 稳定下载页清理与任务操作的 widget 测试定位方式，避免 Flutter CI 环境下因按钮结构差异导致误报失败。
- 修复下载任务忙碌态与批量清理忙碌态测试中的不稳定等待和过宽断言，避免 CI 因持续中的加载指示器误报失败。

### 📚 文档
- 新增 GitHub issue 模板，覆盖通用 bug、播放/数据源问题和功能请求。
- 新增故障排查文档，说明数据源、播放、弹幕、下载、安装和诊断信息复制流程。
- 更新 README 和问题反馈指南，引导用户选择模板并附上已脱敏诊断摘要。
- 明确 release assets 的平台选择说明，并将 Android debug 示例命名改为版本占位符。

## [1.0.2] - 2026-05-29

### ✨ 新增
- 新增下载任务类型识别，区分直链文件、HLS/m3u8、BT 占位和未知类型。
- 新增 HLS/m3u8 manifest 解析基础能力，可识别 media playlist 和 master playlist。
- 新增下载失败原因、headers、字节进度和本地路径等任务字段。
- 新增设置页“复制诊断信息”入口，可生成已脱敏的 Markdown 反馈摘要。
- 新增反馈诊断包，汇总 App 版本、平台、数据源健康、fallback、播放、弹幕和下载任务状态。
- 新增标准品牌资源目录，接入现有 AniDestiny logo 作为 README 和平台图标源资源。
- 新增基于现有 logo 同步生成的 Android、Windows 和 macOS 平台图标资源。
- 新增发布页入口、运行诊断页和可复制的反馈摘要，方便用户反馈播放和数据源问题。
- 新增数据源健康状态、失败计数、最近问题摘要和手动重置能力。
- 新增所选数据源不可用时自动回退到可用备用数据源的能力。
- 新增持久化数据源健康状态和手动重置支持。
- 新增 fallback 提示，让用户知道当前是否正在展示备用数据。
- 新增最近失败和 fallback 事件的数据源诊断信息。
- 新增运行诊断中的数据源健康概览和最近 fallback 事件。

### 🔄 变更
- 刷新 AniDestiny logo 配图，并同步更新 README 品牌图、Android launcher icon、Windows icon 和 macOS AppIcon。
- 重构下载任务模型和状态，下载页现在展示任务类型、状态、进度、失败原因和本地路径。
- 稳定直链文件下载链路，保留基础暂停/取消能力，并明确 HLS 离线和 BT 下载仍未实现。
- 改进首页、搜索、详情、排期、历史和播放页面在所选数据源暂时不可用时的恢复路径。
- 改进 Source Settings，显示健康状态、失败次数和重置控件。
- 改进播放诊断和 URL 脱敏，避免反馈摘要暴露 query token、header 值或其他敏感信息。
- 搜索空结果保持为正常空状态，不再作为数据源失败触发 fallback。

### 🐛 修复
- 修复空详情剧集和空播放源未被视为数据源失败的问题，确保自动 fallback 能够生效。

### 🔧 CI/CD
- 新增 Windows Build CI job，在 `windows-latest` 上验证 `flutter build windows --release` 并上传临时 Windows x64 artifact。
- 新增 release preflight 脚本和发布前质量门禁 checklist。
- 调整 Android release asset 命名为 universal APK 后缀，并记录 arm64 命名规范。
- 调整 macOS 和 Windows release asset 命名，补充平台和架构后缀。
- 修复 release rebuild、Linux release 依赖和 release 发布 checkout 上下文。
- 调整预发布 PR 和正式 GitHub Release 的发布说明生成规则，只输出【新增】【变更】【修复】面向用户章节。
- 新增 `changelog correction` PR label 通道，允许受控修正已发布 changelog 段落，同时仍要求更新 `[Unreleased]`。
- 新增 Android debug 构建脚本和清理脚本，补充 post-release 验证配置。

### 📚 文档
- 补充 Windows CI 构建产物路径、临时 artifact 和 exe/taskbar icon 验证说明。
- 新增问题反馈指南，说明反馈播放、数据源、弹幕和下载问题时需要提供的诊断信息。
- 新增 Android、Windows、macOS 发布 smoke checklist。
- 补充 release asset 命名、Windows 构建验证和当前功能边界说明。
- 新增下载路径、Android 权限策略和暂未实现范围说明。
- 更新 README 视觉展示、平台说明、截图占位和品牌资源说明。
- 补充平台构建文档中的平台图标路径和 release asset 命名规范。
- 更新中英文 README 和平台构建说明。
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
