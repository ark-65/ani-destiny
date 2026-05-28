# AniDestiny

AniDestiny is a non-profit Flutter anime discovery, playback and danmaku learning project.

## Project

This project is for learning, research, and Flutter architecture practice only.
It has no commercial purpose.

## Links

- Open source: <https://github.com/ark-65/ani-destiny>
- Releases: <https://github.com/ark-65/ani-destiny/releases>

## Project Identity

- App Name: AniDestiny
- Package: ani_destiny
- Android applicationId: com.ark65.anidestiny
- iOS bundleId: com.ark65.anidestiny

## First Version Scope

- Mock anime source for stable home, search, detail, schedule, and play-source flows.
- Experimental Sakura Anime source adapter for real search, detail, episode, and play-source parsing.
- Flutter Material 3 shell with Riverpod and go_router.
- Local history, favorites, and download tasks.
- Player, danmaku, source, and download adapters with clear placeholders for future real integrations.

## License Notice

This project is inspired by Animius.
Please keep original project attribution and license notes where applicable.

## Development

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```
