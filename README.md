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
- 更新日志：[CHANGELOG.md](./CHANGELOG.md)
- English changelog: [CHANGELOG_en.md](./CHANGELOG_en.md)

## 项目标识

- App 名称：AniDestiny
- Flutter package：ani_destiny
- Android applicationId：com.ark65.anidestiny
- iOS bundleId：com.ark65.anidestiny

## 当前能力

- 首页推荐、搜索、番剧详情、剧集列表。
- Sakura 真实数据源解析，支持首页、搜索、详情、播放源和诊断信息。
- 播放页基础播放控制、倍速、全屏、播放诊断。
- Dandanplay 弹幕接入结构和 Mock fallback。
- 历史记录、收藏、下载任务的本地持久化。
- 多语言界面：中文、英文、日文。
- Android、macOS、Windows、Linux 的发布构建流程。

## 开发命令

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

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

- Android APK
- macOS ZIP
- Windows ZIP
- Linux tar.gz

## License Notice

This project is inspired by Animius.
Please keep original project attribution and license notes where applicable.
