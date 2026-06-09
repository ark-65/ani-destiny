import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../anime/presentation/providers/anime_providers.dart';
import '../../../danmaku/domain/entities/danmaku_item.dart';
import '../../../danmaku/presentation/providers/danmaku_providers.dart';
import '../../../danmaku/presentation/widgets/danmaku_overlay.dart';
import '../../../download/presentation/providers/download_providers.dart';
import '../../../history/domain/entities/watch_history.dart';
import '../../../history/domain/repositories/history_repository.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../domain/adapters/player_controller_adapter.dart';
import '../../domain/entities/player_route_args.dart';
import '../../domain/entities/player_state.dart';
import '../../domain/services/playback_diagnostics.dart';
import '../../domain/services/next_episode_navigation.dart';
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

class _PlayerPageState extends ConsumerState<PlayerPage>
    with WidgetsBindingObserver {
  static const _historyWriteInterval = Duration(seconds: 5);

  late final PlayerControllerAdapter _controller;
  late final HistoryRepository _historyRepository;
  late PlayerRouteArgs _currentArgs;
  StreamSubscription<PlayerState>? _subscription;
  DateTime? _lastHistorySavedAt;
  PlayerState _state = PlayerState.initial();
  bool _isFullscreen = false;
  bool _isDisposed = false;
  bool _isSwitchingEpisode = false;

  PlayerRouteArgs get _args => _currentArgs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentArgs = widget.args;
    _historyRepository = ref.read(historyRepositoryProvider);
    _controller = ref.read(playerRepositoryProvider).createController();
    _subscription = _controller.stateStream.listen((state) {
      if (!mounted || _isDisposed) return;
      setState(() => _state = state);
      unawaited(_saveHistory());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      _recordPlaybackDiagnostics();
    });
    unawaited(_loadPlayer());
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_restoreSystemUi());
    unawaited(_saveHistory(force: true));
    unawaited(_subscription?.cancel());
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_saveHistory(force: true));
      if (_state.isPlaying) unawaited(_controller.pause());
    }
  }

  @override
  Widget build(BuildContext context) {
    final danmakuSettings = ref.watch(danmakuSettingsProvider);
    final danmakuItems = ref.watch(
      danmakuItemsProvider(
        (
          animeId: _args.animeId,
          episodeId: _args.episodeId,
          animeTitle: _args.animeTitle,
          episodeTitle: _args.episodeTitle,
          episodeIndex: _args.episodeIndex,
        ),
      ),
    );

    return PopScope<void>(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !_isFullscreen) return;
        unawaited(_exitFullscreen());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _isFullscreen
            ? null
            : AppBar(
                title: Text(_args.episodeTitle),
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
                actions: [
                  if (kDebugMode)
                    IconButton(
                      tooltip: context.l10n.playbackDiagnostics,
                      onPressed: _showPlaybackDiagnostics,
                      icon: const Icon(Icons.bug_report_outlined),
                    ),
                  IconButton(
                    tooltip: context.l10n.nextEpisode,
                    onPressed: _isSwitchingEpisode
                        ? null
                        : () => unawaited(_playNextEpisode()),
                    icon: _isSwitchingEpisode
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.skip_next),
                  ),
                  IconButton(
                    tooltip: context.l10n.externalPlayer,
                    onPressed: () => unawaited(_openExternalPlayer()),
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
                              _playbackErrorMessage(),
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
                  if (danmakuSettings.enabled)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _DanmakuStatusBadge(value: danmakuItems),
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
                onNextEpisode: _isSwitchingEpisode
                    ? null
                    : () => unawaited(_playNextEpisode()),
                onDownload: () => unawaited(_createDownload()),
                onToggleFullscreen: () => unawaited(_toggleFullscreen()),
                onToggleDanmaku: () {
                  ref.read(danmakuSettingsProvider.notifier).state =
                      danmakuSettings.copyWith(
                    enabled: !danmakuSettings.enabled,
                  );
                },
                isFullscreen: _isFullscreen,
                isSwitchingEpisode: _isSwitchingEpisode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFullscreen() async {
    if (_isFullscreen) {
      await _exitFullscreen();
    } else {
      await _enterFullscreen();
    }
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;
    setState(() => _isFullscreen = true);
  }

  Future<void> _exitFullscreen() async {
    await _restoreSystemUi();
    if (!mounted) return;
    setState(() => _isFullscreen = false);
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  void _showPlaybackDiagnostics() {
    final diagnostics = _recordPlaybackDiagnostics();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.playbackDiagnostics,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _DiagnosticRow(
                  label: context.l10n.playbackDiagnosticSource,
                  value: context.l10n.sourceDisplayLabel(diagnostics.sourceId),
                ),
                _DiagnosticRow(
                  label: context.l10n.playbackDiagnosticLine,
                  value: diagnostics.playSourceTitle ?? '-',
                ),
                _DiagnosticRow(
                  label: context.l10n.playbackDiagnosticUrlType,
                  value: diagnostics.urlType,
                ),
                _DiagnosticRow(
                  label: context.l10n.playbackDiagnosticUrl,
                  value: diagnostics.sanitizedUrl,
                ),
                _DiagnosticRow(
                  label: context.l10n.playbackDiagnosticHeaders,
                  value: diagnostics.headerKeys.isEmpty
                      ? '-'
                      : diagnostics.headerKeys.join(', '),
                ),
                _DiagnosticRow(
                  label: context.l10n.playbackDiagnosticState,
                  value: _stateLabel(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PlaybackDiagnostics _recordPlaybackDiagnostics({
    PlayerRouteArgs? args,
  }) {
    final routeArgs = args ?? _args;
    final diagnostics = const PlaybackDiagnosticsBuilder().build(
      sourceId: routeArgs.sourceId,
      playSourceTitle: routeArgs.playSourceTitle,
      playUrl: routeArgs.playUrl,
      headers: routeArgs.playHeaders,
    );
    unawaited(
      Future<void>(() {
        if (!mounted || _isDisposed) return;
        ref.read(lastPlaybackDiagnosticsProvider.notifier).state = diagnostics;
      }),
    );
    return diagnostics;
  }

  String _stateLabel() {
    if (_state.errorMessage != null) {
      return context.l10n.playbackDiagnosticStateError;
    }
    if (_state.isBuffering) {
      return context.l10n.playbackDiagnosticStateBuffering;
    }
    if (_state.isPlaying) {
      return context.l10n.playbackDiagnosticStatePlaying;
    }
    if (_state.isInitialized) {
      return context.l10n.playbackDiagnosticStateReady;
    }
    return context.l10n.playbackDiagnosticStateLoading;
  }

  String _playbackErrorMessage() {
    if (_state.errorMessage == context.l10n.playerNoPlayUrl) {
      return context.l10n.noPlayableSourceFound;
    }
    return context.l10n.playbackFailedSuggestion;
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
    await _historyRepository.upsert(
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
      final taskId = await ref.read(downloadTaskCreatorProvider).create(
            animeId: _args.animeId,
            episodeId: _args.episodeId,
            sourceId: _args.sourceId,
            url: _args.playUrl,
            title: _args.animeTitle,
            episodeTitle: _args.episodeTitle,
            headers: _args.playHeaders,
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

  Future<void> _loadPlayer({
    PlayerRouteArgs? args,
    bool autoplay = false,
    double? playbackSpeed,
  }) async {
    final routeArgs = args ?? _args;
    _recordPlaybackDiagnostics(args: routeArgs);
    try {
      if (routeArgs.playUrl.trim().isEmpty) {
        setState(
          () => _state = _state.copyWith(
            isBuffering: false,
            errorMessage: context.l10n.playerNoPlayUrl,
          ),
        );
        return;
      }
      await _controller.load(routeArgs.playUrl, headers: routeArgs.playHeaders);
      final initialPosition = routeArgs.initialPosition;
      if (initialPosition != null && initialPosition > Duration.zero) {
        await _controller.seek(initialPosition);
      }
      if (playbackSpeed != null &&
          playbackSpeed > 0 &&
          (playbackSpeed - 1).abs() > 0.001) {
        await _controller.setSpeed(playbackSpeed);
      }
      if (autoplay) {
        await _controller.play();
      }
      unawaited(_saveHistory(force: true));
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _state = _state.copyWith(
          isBuffering: false,
          errorMessage: context.l10n.playbackFailedSuggestion,
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

  Future<void> _playNextEpisode() async {
    if (_isSwitchingEpisode) return;

    final currentArgs = _args;
    final shouldResumePlayback = _state.isPlaying;
    final playbackSpeed = _state.speed;

    setState(() => _isSwitchingEpisode = true);
    try {
      final detailResult = await ref.read(
        animeDetailBySourceProvider(
          (sourceId: currentArgs.sourceId, animeId: currentArgs.animeId),
        ).future,
      );
      if (!mounted) return;
      final nextEpisode = resolveNextEpisode(
        episodes: detailResult.value.episodes,
        currentEpisodeId: currentArgs.episodeId,
        currentEpisodeIndex: currentArgs.episodeIndex,
        currentEpisodeTitle: currentArgs.episodeTitle,
      );
      if (nextEpisode == null) {
        _showSnackBar(context.l10n.nextEpisodeUnavailable);
        return;
      }

      final playSourceResult = await ref.read(
        playSourcesBySourceProvider(
          (sourceId: detailResult.sourceId, episodeId: nextEpisode.id),
        ).future,
      );
      if (!mounted) return;
      final sources = playSourceResult.value;
      if (sources.isEmpty) {
        _showSnackBar(context.l10n.noPlayableSourceFound);
        return;
      }

      final selectedSource = selectPreferredPlaySource(
        sources,
        preferredSourceId: currentArgs.playSourceId,
        preferredSourceTitle: currentArgs.playSourceTitle,
      );
      await _saveHistory(force: true);
      if (!mounted) return;

      final nextArgs = currentArgs.copyWith(
        episodeId: nextEpisode.id,
        episodeTitle: nextEpisode.title,
        sourceId: playSourceResult.sourceId,
        playSourceId: selectedSource.id,
        playSourceTitle: selectedSource.title,
        playUrl: selectedSource.url,
        playHeaders: selectedSource.headers,
        episodeIndex: nextEpisode.index,
        initialPosition: null,
      );

      setState(() {
        _currentArgs = nextArgs;
        _state = PlayerState.initial();
        _lastHistorySavedAt = null;
      });

      await _loadPlayer(
        args: nextArgs,
        autoplay: shouldResumePlayback,
        playbackSpeed: playbackSpeed,
      );
      if (!mounted) return;
      if (detailResult.usedFallback || playSourceResult.usedFallback) {
        _showSnackBar(context.l10n.sourceFallbackNotice);
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(context.l10n.sourceTemporarilyUnavailable);
    } finally {
      if (mounted) {
        setState(() => _isSwitchingEpisode = false);
      }
    }
  }

  Future<void> _openExternalPlayer() async {
    final rawUrl = _args.playUrl.trim();
    final uri = Uri.tryParse(rawUrl);
    if (rawUrl.isEmpty || uri == null || !uri.hasScheme) {
      _showSnackBar(context.l10n.noPlayableSourceFound);
      return;
    }

    try {
      final launched = await ref.read(externalPlayerLauncherProvider)(uri);
      if (!mounted || launched) return;
      _showSnackBar(context.l10n.externalPlayerUnavailable);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(context.l10n.externalPlayerUnavailable);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _DanmakuStatusBadge extends StatelessWidget {
  const _DanmakuStatusBadge({required this.value});

  final AsyncValue<List<DanmakuItem>> value;

  @override
  Widget build(BuildContext context) {
    final label = value.when(
      data: (items) {
        if (items.isEmpty) return context.l10n.danmakuStatusEmpty;
        final sources = items.map((item) => item.source).toSet();
        if (sources.contains('dandanplay')) {
          return context.l10n.danmakuStatusDandanplay;
        }
        if (sources.contains('mock')) return context.l10n.danmakuStatusFallback;
        return context.l10n.danmakuStatusAvailable;
      },
      loading: () => context.l10n.danmakuStatusLoading,
      error: (_, __) => context.l10n.danmakuStatusUnavailable,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}
