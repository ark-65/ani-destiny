<p align="center">
  <img src="assets/branding/ani_destiny_logo.png" alt="AniDestiny" width="180">
</p>

# AniDestiny

> 中文 | [English](./README_en.md)

AniDestiny 是一个非盈利的 Flutter 动漫发现、播放与弹幕学习项目。

## 项目说明

本项目仅用于学习、研究和 Flutter 架构实践，不用于商业用途。

AniDestiny 当前以客户端数据源适配器为核心：

- 默认数据源：Sakura Anime 网站解析源。
- 备用数据源：Mock 动漫数据源，用于离线演示和开发兜底。
- 未来可扩展：Remote Source Proxy、自建服务端代理、更多公开数据源。

## 链接

- 开源仓库：<https://github.com/ark-65/ani-destiny>
- 发布页面：<https://github.com/ark-65/ani-destiny/releases>
- 问题反馈指南：[docs/reporting-issues.md](./docs/reporting-issues.md)
- 故障排查：[docs/troubleshooting.md](./docs/troubleshooting.md)
- 更新日志：[CHANGELOG.md](./CHANGELOG.md)
- English changelog: [CHANGELOG_en.md](./CHANGELOG_en.md)

## 平台

AniDestiny 当前面向 Android、macOS、Windows 和 Linux 构建验证。

## 项目标识

- App 名称：AniDestiny
- Flutter package：ani_destiny
- Android applicationId：com.ark65.anidestiny
- iOS bundleId：com.ark65.anidestiny
- 品牌资源：`assets/branding/`

## 当前能力

- 首页推荐、搜索、番剧详情、剧集列表。
- Sakura 真实数据源解析，支持首页、搜索、详情、播放源和诊断信息。
- 播放页基础播放控制、倍速、全屏、播放诊断。
- Dandanplay 弹幕接入结构和 Mock fallback。
- 历史记录、收藏、下载任务的本地持久化，支持直链下载和 HLS/BT 类型识别占位。
- 设置页可复制已脱敏诊断摘要，用于反馈播放、数据源、弹幕和下载问题。
- 多语言界面：中文、英文、日文。
- Android、macOS、Windows、Linux 的发布构建流程。

## Screenshots

Screenshots will be added in a future release.

## 开发命令

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

## 本地脚本

```sh
bash scripts/clean.sh
bash scripts/build-android-debug.sh
bash scripts/preflight-release.sh
```

更多平台构建说明见 [docs/platform-build.md](./docs/platform-build.md)，发布前检查见 [docs/release-checklist.md](./docs/release-checklist.md)，下载路径和权限策略见 [docs/downloads.md](./docs/downloads.md)。

## 问题反馈

反馈播放、数据源、弹幕或下载问题时，请优先使用 GitHub Issue 模板，并提供 App 版本、平台、复现步骤、数据源名称、是否使用 fallback，以及从设置页复制的已脱敏诊断摘要。不要提交账号凭据、cookie、token 或包含 query 参数的完整 URL。

更多说明见 [docs/reporting-issues.md](./docs/reporting-issues.md)，常见问题见 [docs/troubleshooting.md](./docs/troubleshooting.md)。

## 手动打包

```sh
flutter build apk --release
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

说明：

- Windows 包需要在 Windows 主机或 Windows CI runner 上构建。
- macOS 包需要在 macOS 主机或 macOS CI runner 上构建。
- iOS 正式发布需要证书、签名和 App Store 流程，当前不作为公开自动发布产物。

## 发布流程

本仓库使用“预发布 PR 审核后发布”的流程：

1. 普通 PR 需要更新 `CHANGELOG.md` 和 `CHANGELOG_en.md` 的 `[Unreleased]` 区块。
2. 在 GitHub Actions 手动运行 `Prepare Release`，输入目标版本号。
3. 工作流会更新 `pubspec.yaml` 版本号，归档中英文 changelog，并创建 `release/vX.Y.Z` PR。
4. 维护者审核并合并 release PR。
5. `Release` 工作流读取 `CHANGELOG.md` 中对应版本的中文发布说明，创建 tag，构建多平台产物，并发布 GitHub Release。

## 发布产物

Release CI 会上传：

- Android universal APK
- macOS universal ZIP
- Windows x64 ZIP
- Linux tar.gz

## 下载说明

- Android：下载 `AniDestiny-v<version>-android-universal.apk`，在 Android 设备上安装。
- Windows：下载 `AniDestiny-v<version>-windows-x64.zip`，解压后运行 `ani_destiny.exe`。
- macOS：下载 `AniDestiny-v<version>-macos-universal.zip`，解压后打开 AniDestiny.app。当前产物未走商店签名流程，若系统拦截，请只在信任来源时通过系统安全设置允许打开。
- Linux：下载 `AniDestiny-v<version>-linux-x64.tar.gz`，解压后按平台环境运行。

## License Notice

This project is inspired by Animius.
Please keep original project attribution and license notes where applicable.
