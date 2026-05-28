import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../danmaku/presentation/providers/danmaku_providers.dart';
import '../../../danmaku/presentation/widgets/danmaku_overlay.dart';
import '../../../download/presentation/providers/download_providers.dart';
import '../../../history/domain/entities/watch_history.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../domain/adapters/player_controller_adapter.dart';
import '../../domain/entities/player_route_args.dart';
import '../../domain/entities/player_state.dart';
import '../providers/player_providers.dart';
import '../widgets/playback_speed_sheet.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_surface.dart';

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({
    required this.args,
    super.key,
  });

  final PlayerRouteArgs args;

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  static const _historyWriteInterval = Duration(seconds: 5);

  late final PlayerControllerAdapter _controller;
  StreamSubscription<PlayerState>? _subscription;
  DateTime? _lastHistorySavedAt;
  PlayerState _state = PlayerState.initial();

  PlayerRouteArgs get _args => widget.args;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(playerRepositoryProvider).createController();
    _subscription = _controller.stateStream.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
      unawaited(_saveHistory());
    });
    unawaited(_loadPlayer());
  }

  @override
  void dispose() {
    unawaited(_saveHistory(force: true));
    unawaited(_subscription?.cancel());
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final danmakuSettings = ref.watch(danmakuSettingsProvider);
    final danmakuItems = ref.watch(
      danmakuItemsProvider(
        (animeId: _args.animeId, episodeId: _args.episodeId),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_args.episodeTitle),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: context.l10n.nextEpisodePlaceholder,
            onPressed: _showNextEpisodePlaceholder,
            icon: const Icon(Icons.skip_next),
          ),
          IconButton(
            tooltip: context.l10n.externalPlayerPlaceholder,
            onPressed: _showExternalPlayerPlaceholder,
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                PlayerSurface(
                  controller: _controller,
                  title: _args.animeTitle,
                  playUrl: _args.playUrl,
                ),
                if (_state.isBuffering)
                  const Center(child: CircularProgressIndicator()),
                if (_state.errorMessage != null)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _state.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                danmakuItems.when(
                  data: (items) => DanmakuOverlay(
                    items: items,
                    position: _state.position,
                    settings: danmakuSettings,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: PlayerControls(
              state: _state,
              danmakuEnabled: danmakuSettings.enabled,
              onPlayPause: () {
                if (_state.isPlaying) {
                  unawaited(_controller.pause());
                  unawaited(_saveHistory(force: true));
                } else {
                  unawaited(_controller.play());
                }
              },
              onSeek: (position) => unawaited(_controller.seek(position)),
              onSpeed: _showSpeedSheet,
              onDownload: () => unawaited(_createDownload()),
              onToggleDanmaku: () {
                ref.read(danmakuSettingsProvider.notifier).state =
                    danmakuSettings.copyWith(enabled: !danmakuSettings.enabled);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveHistory({bool force = false}) async {
    if (!_state.isInitialized) return;
    final now = DateTime.now();
    final lastSavedAt = _lastHistorySavedAt;
    if (!force &&
        lastSavedAt != null &&
        now.difference(lastSavedAt) < _historyWriteInterval) {
      return;
    }
    _lastHistorySavedAt = now;
    await ref.read(historyRepositoryProvider).upsert(
          WatchHistory(
            id: '${_args.sourceId}:${_args.animeId}:${_args.episodeId}',
            animeId: _args.animeId,
            episodeId: _args.episodeId,
            animeTitle: _args.animeTitle,
            episodeTitle: _args.episodeTitle,
            coverUrl: _args.coverUrl,
            position: _state.position,
            duration: _state.duration,
            sourceId: _args.sourceId,
            playSourceId: _args.playSourceId,
            playSourceTitle: _args.playSourceTitle,
            playUrl: _args.playUrl,
            playHeaders: _args.playHeaders,
            updatedAt: now,
          ),
        );
  }

  Future<void> _createDownload() async {
    try {
      final taskId = await ref.read(httpDownloadServiceProvider).createTask(
            animeId: _args.animeId,
            episodeId: _args.episodeId,
            sourceId: _args.sourceId,
            url: _args.playUrl,
            title: _args.animeTitle,
            episodeTitle: _args.episodeTitle,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.downloadTaskCreated(taskId)),
          action: SnackBarAction(
            label: context.l10n.open,
            onPressed: () => context.push('/downloads'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _loadPlayer() async {
    try {
      if (_args.playUrl.trim().isEmpty) {
        setState(
          () => _state = _state.copyWith(
            isBuffering: false,
            errorMessage: context.l10n.playerNoPlayUrl,
          ),
        );
        return;
      }
      await _controller.load(_args.playUrl, headers: _args.playHeaders);
      final initialPosition = _args.initialPosition;
      if (initialPosition != null && initialPosition > Duration.zero) {
        await _controller.seek(initialPosition);
      }
      unawaited(_saveHistory(force: true));
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _state = _state.copyWith(
          isBuffering: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _showSpeedSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => PlaybackSpeedSheet(
        currentSpeed: _state.speed,
        onSelected: (speed) => unawaited(_controller.setSpeed(speed)),
      ),
    );
  }

  void _showNextEpisodePlaceholder() {
    // TODO(ark65): Resolve the next episode from AnimeDetail and load it here.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.nextEpisodeNotImplemented)),
    );
  }

  void _showExternalPlayerPlaceholder() {
    // TODO(ark65): Add url_launcher based external-player intents per platform.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.externalPlayerNotImplemented)),
    );
  }
}
