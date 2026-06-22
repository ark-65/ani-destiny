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
import '../../../source/presentation/providers/source_providers.dart';
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
  String? _lastPlaybackDiagnosticKey;
  bool _isResolvingNextEpisode = false;
  bool _isSwitchingEpisode = false;
  String? _switchingEpisodeTitle;
  bool _isOpeningExternalPlayer = false;
  bool _isRetryingPlayback = false;

  PlayerRouteArgs get _args => _currentArgs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentArgs = widget.args;
    _historyRepository = ref.read(historyRepositoryProvider);
    _controller = ref.read(playerRepositoryProvider).createController();
    unawaited(ref.read(currentSourceIdProvider.future));
    _subscription = _controller.stateStream.listen((state) {
      if (!mounted || _isDisposed) return;
      final enteredFailureState =
          _state.errorMessage == null && state.errorMessage != null;
      setState(() => _state = state);
      _recordPlaybackDiagnostics();
      unawaited(_saveHistory(force: enteredFailureState));
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
    final canLeavePlayer = Navigator.of(context).canPop();
    final hasPlayableSource = _hasPlayableUrl();
    final animeDetailProvider = animeDetailBySourceProvider(
      (sourceId: _args.sourceId, animeId: _args.animeId),
    );
    final cachedAnimeDetail = ref.exists(animeDetailProvider)
        ? ref.watch(animeDetailProvider).valueOrNull
        : null;
    final knownNextEpisode = cachedAnimeDetail == null
        ? null
        : resolveNextEpisode(
            episodes: cachedAnimeDetail.value.episodes,
            currentEpisodeId: _args.episodeId,
            currentEpisodeIndex: _args.episodeIndex,
            currentEpisodeTitle: _args.episodeTitle,
          );
    final knowsNoNextEpisode =
        cachedAnimeDetail != null && knownNextEpisode == null;
    final isRetryingPlayback = _isRetryingPlayback;
    final hasCommittedRouteTransition =
        _isSwitchingEpisode || _isOpeningExternalPlayer || isRetryingPlayback;
    final isRouteBusy = hasCommittedRouteTransition;
    final isPreparingNextEpisode =
        _isResolvingNextEpisode || _isSwitchingEpisode;
    final showRouteTransitionOverlay =
        hasCommittedRouteTransition && _state.errorMessage == null;
    final routeTransitionMessage = _isSwitchingEpisode
        ? context.l10n.loadingNextEpisode
        : _isOpeningExternalPlayer
            ? context.l10n.openingExternalPlayer
            : context.l10n.retryingPlayback;
    final routeTransitionDetail = _isFullscreen
        ? (_isSwitchingEpisode
            ? (_switchingEpisodeTitle ?? _args.episodeTitle)
            : _args.episodeTitle)
        : null;
    final playerExitBusyMessage = _routeBusyExitMessage(context);
    final showDanmakuChrome =
        !hasCommittedRouteTransition && _state.errorMessage == null;
    final appBarEpisodeTitle = _isSwitchingEpisode
        ? (_switchingEpisodeTitle ?? _args.episodeTitle)
        : _args.episodeTitle;
    final appBarStatus =
        hasCommittedRouteTransition ? routeTransitionMessage : null;
    final nextEpisodeTooltip = isPreparingNextEpisode
        ? context.l10n.loadingNextEpisode
        : _isOpeningExternalPlayer
            ? context.l10n.openingExternalPlayer
            : isRetryingPlayback
                ? context.l10n.retryingPlayback
                : knowsNoNextEpisode
                    ? context.l10n.nextEpisodeUnavailable
                    : context.l10n.nextEpisode;
    final canRetryPlayback = _canRetryPlayback();
    final keepRetryActionVisible = _state.errorMessage != null &&
        _state.errorMessage != context.l10n.playerNoPlayUrl &&
        !_isSwitchingEpisode &&
        !_isOpeningExternalPlayer &&
        !isRetryingPlayback &&
        _hasPlayableUrl();
    final retryActionTooltip = isPreparingNextEpisode
        ? context.l10n.loadingNextEpisode
        : _isOpeningExternalPlayer
            ? context.l10n.openingExternalPlayer
            : isRetryingPlayback
                ? context.l10n.retryingPlayback
                : context.l10n.retry;
    final canStartNextEpisodeTransition = !_isResolvingNextEpisode &&
        !_isSwitchingEpisode &&
        !_isOpeningExternalPlayer &&
        !_isRetryingPlayback &&
        !knowsNoNextEpisode;
    final canExplainUnavailableNextEpisode = !_isResolvingNextEpisode &&
        !_isSwitchingEpisode &&
        !_isOpeningExternalPlayer &&
        !_isRetryingPlayback &&
        knowsNoNextEpisode;
    final nextEpisodeAction = canStartNextEpisodeTransition
        ? () => unawaited(_playNextEpisode())
        : canExplainUnavailableNextEpisode
            ? () => _showSnackBar(context.l10n.nextEpisodeUnavailable)
            : null;
    final externalPlayerTooltip = _externalPlayerTooltip(context);
    final downloadTooltip = _downloadTooltip(context);
    final unavailableActionColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
    final canCreateDownload = hasPlayableSource &&
        !_isResolvingNextEpisode &&
        !_isSwitchingEpisode &&
        !_isOpeningExternalPlayer &&
        !isRetryingPlayback;
    final canUseExternalPlayerAction = _canUseExternalPlayerAction();
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
      canPop: !_isFullscreen && !isRouteBusy,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isRouteBusy) {
          _showSnackBar(playerExitBusyMessage);
          return;
        }
        if (_isFullscreen) {
          unawaited(_exitFullscreen());
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _isFullscreen
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                leading: canLeavePlayer
                    ? IconButton(
                        tooltip: isRouteBusy
                            ? playerExitBusyMessage
                            : context.l10n.back,
                        onPressed: isRouteBusy
                            ? () => _showSnackBar(playerExitBusyMessage)
                            : () => Navigator.of(context).maybePop(),
                        icon: const BackButtonIcon(),
                      )
                    : null,
                title: _PlayerAppBarTitle(
                  title: appBarEpisodeTitle,
                  status: appBarStatus,
                ),
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
                    style: canExplainUnavailableNextEpisode
                        ? IconButton.styleFrom(
                            foregroundColor: Colors.white54,
                          )
                        : null,
                    tooltip: nextEpisodeTooltip,
                    onPressed: nextEpisodeAction,
                    icon: isPreparingNextEpisode
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.skip_next),
                  ),
                  IconButton(
                    tooltip: externalPlayerTooltip,
                    onPressed: canUseExternalPlayerAction
                        ? () => unawaited(_openExternalPlayer())
                        : null,
                    icon: _isOpeningExternalPlayer
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.open_in_new),
                  ),
                ],
              ),
        body: Column(
          children: [
            if (!_isFullscreen &&
                !isRouteBusy &&
                _hasSourceFallbackContext() &&
                _state.errorMessage == null)
              _SourceFallbackBanner(
                message: _sourceFallbackNotice(context),
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlayerSurface(
                    controller: _controller,
                    title: _args.animeTitle,
                    playUrl: _args.playUrl,
                  ),
                  if (showRouteTransitionOverlay)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: _PlaybackTransitionOverlay(
                            message: routeTransitionMessage,
                            detail: routeTransitionDetail,
                          ),
                        ),
                      ),
                    ),
                  if (_state.isBuffering && !showRouteTransitionOverlay)
                    const Center(child: CircularProgressIndicator()),
                  if (_state.errorMessage != null)
                    SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _playbackErrorMessage(),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_hasSourceFallbackContext()) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        _sourceFallbackNotice(context),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    _PlaybackIssueContext(
                                      animeTitle: _args.animeTitle,
                                      episodeTitle: _args.episodeTitle,
                                      requestedSourceLabel:
                                          _hasSourceFallbackContext()
                                              ? context.l10n.sourceDisplayLabel(
                                                  _args.requestedSourceId!,
                                                )
                                              : null,
                                      sourceLabel:
                                          context.l10n.sourceDisplayLabel(
                                        _args.sourceId,
                                      ),
                                      playSourceTitle: _args.playSourceTitle,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (keepRetryActionVisible)
                                          Tooltip(
                                            message: retryActionTooltip,
                                            child: TextButton.icon(
                                              onPressed: canRetryPlayback
                                                  ? () => unawaited(
                                                        _retryPlayback(),
                                                      )
                                                  : null,
                                              icon: const Icon(Icons.refresh),
                                              label: Text(context.l10n.retry),
                                            ),
                                          ),
                                        Tooltip(
                                          message: nextEpisodeTooltip,
                                          child: TextButton.icon(
                                            style:
                                                canExplainUnavailableNextEpisode
                                                    ? TextButton.styleFrom(
                                                        foregroundColor:
                                                            unavailableActionColor,
                                                      )
                                                    : null,
                                            onPressed: nextEpisodeAction,
                                            icon: isPreparingNextEpisode
                                                ? const SizedBox.square(
                                                    dimension: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(Icons.skip_next),
                                            label: Text(
                                              isPreparingNextEpisode
                                                  ? context
                                                      .l10n.loadingNextEpisode
                                                  : canExplainUnavailableNextEpisode
                                                      ? context
                                                          .l10n.latestEpisode
                                                      : context
                                                          .l10n.nextEpisode,
                                            ),
                                          ),
                                        ),
                                        if (_hasPlayableUrl())
                                          Tooltip(
                                            message: externalPlayerTooltip,
                                            child: TextButton.icon(
                                              style: canUseExternalPlayerAction
                                                  ? null
                                                  : TextButton.styleFrom(
                                                      foregroundColor:
                                                          unavailableActionColor,
                                                    ),
                                              onPressed:
                                                  canUseExternalPlayerAction
                                                      ? () => unawaited(
                                                            _openExternalPlayer(),
                                                          )
                                                      : null,
                                              icon: _isOpeningExternalPlayer
                                                  ? const SizedBox.square(
                                                      dimension: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.open_in_new,
                                                    ),
                                              label: Text(
                                                _isOpeningExternalPlayer
                                                    ? context.l10n
                                                        .openingExternalPlayer
                                                    : context
                                                        .l10n.externalPlayer,
                                              ),
                                            ),
                                          ),
                                        TextButton.icon(
                                          onPressed: () => unawaited(
                                            _copyPlaybackDiagnostics(),
                                          ),
                                          icon: const Icon(
                                            Icons.content_copy_outlined,
                                          ),
                                          label: Text(
                                            context.l10n.copyDiagnostics,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: _showPlaybackDiagnostics,
                                          icon: const Icon(
                                            Icons.bug_report_outlined,
                                          ),
                                          label: Text(
                                            context.l10n.playbackDiagnostics,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_hasPlayableUrl() &&
                                        _args.playHeaders.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        context.l10n
                                            .externalPlayerHeadersUnsupported(
                                          _activeSourceLabel(context),
                                        ),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (showDanmakuChrome)
                    danmakuItems.when(
                      data: (items) => DanmakuOverlay(
                        items: items,
                        position: _state.position,
                        settings: danmakuSettings,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  if (showDanmakuChrome && danmakuSettings.enabled)
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
                hasPlayableSource: hasPlayableSource,
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
                onNextEpisode: _isSwitchingEpisode || isRetryingPlayback
                    ? null
                    : nextEpisodeAction,
                isNextEpisodeUnavailable: canExplainUnavailableNextEpisode,
                nextEpisodeTooltip: nextEpisodeTooltip,
                onOpenExternalPlayer: canUseExternalPlayerAction
                    ? () => unawaited(_openExternalPlayer())
                    : null,
                externalPlayerTooltip: externalPlayerTooltip,
                downloadTooltip: downloadTooltip,
                onDownload: canCreateDownload
                    ? () => unawaited(_createDownload())
                    : null,
                onToggleFullscreen:
                    isRouteBusy ? null : () => unawaited(_toggleFullscreen()),
                onBlockedFullscreenExit: isRouteBusy && _isFullscreen
                    ? () => _showSnackBar(playerExitBusyMessage)
                    : null,
                onToggleDanmaku: () {
                  ref.read(danmakuSettingsProvider.notifier).state =
                      danmakuSettings.copyWith(
                    enabled: !danmakuSettings.enabled,
                  );
                },
                isFullscreen: _isFullscreen,
                isResolvingNextEpisode: _isResolvingNextEpisode,
                isSwitchingEpisode: _isSwitchingEpisode,
                isOpeningExternalPlayer: _isOpeningExternalPlayer,
                isRetryingPlayback: isRetryingPlayback,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canUseExternalPlayerAction() {
    if (!_supportsExternalPlayerHandoff() ||
        _isResolvingNextEpisode ||
        _isSwitchingEpisode ||
        _isOpeningExternalPlayer ||
        _isRetryingPlayback) {
      return false;
    }
    return true;
  }

  bool _supportsExternalPlayerHandoff() {
    return _hasPlayableUrl() && _args.playHeaders.isEmpty;
  }

  bool _hasPlayableUrl() {
    return _isPlayableUrl(_args.playUrl);
  }

  String _externalPlayerTooltip(BuildContext context) {
    if (_isOpeningExternalPlayer) {
      return context.l10n.openingExternalPlayer;
    }
    if (_isResolvingNextEpisode || _isSwitchingEpisode) {
      return context.l10n.loadingNextEpisode;
    }
    if (_isRetryingPlayback) {
      return context.l10n.retryingPlayback;
    }
    if (!_hasPlayableUrl()) {
      return context.l10n.noPlayableSourceFound;
    }
    if (_args.playHeaders.isNotEmpty) {
      return context.l10n.externalPlayerHeadersUnsupported(
        _activeSourceLabel(context),
      );
    }
    return context.l10n.externalPlayer;
  }

  String _downloadTooltip(BuildContext context) {
    if (_isOpeningExternalPlayer) {
      return context.l10n.openingExternalPlayer;
    }
    if (_isResolvingNextEpisode || _isSwitchingEpisode) {
      return context.l10n.loadingNextEpisode;
    }
    if (_isRetryingPlayback) {
      return context.l10n.retryingPlayback;
    }
    if (!_hasPlayableUrl()) {
      return context.l10n.noPlayableSourceFound;
    }
    return context.l10n.download;
  }

  String _routeBusyExitMessage(BuildContext context) {
    if (_isResolvingNextEpisode || _isSwitchingEpisode) {
      return context.l10n.playerExitBusyNextEpisode;
    }
    if (_isOpeningExternalPlayer) {
      return context.l10n.playerExitBusyExternalPlayer;
    }
    if (_isRetryingPlayback) {
      return context.l10n.playerExitBusyRetryingPlayback;
    }
    return context.l10n.playerExitBusy;
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
    final selectedAppSourceLabel =
        _selectedAppSourceLabelForDiagnostics(context, diagnostics);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
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
                  Text(
                    context.l10n.playbackDiagnosticsDebugHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _DiagnosticRow(
                    label: context.l10n.playbackDiagnosticCapturedAt,
                    value: _formatPlaybackDiagnosticCapturedAt(
                      context,
                      diagnostics.capturedAt,
                    ),
                  ),
                  _DiagnosticRow(
                    label: context.l10n.playbackDiagnosticAnime,
                    value: _diagnosticContextValue(diagnostics.animeTitle),
                  ),
                  _DiagnosticRow(
                    label: context.l10n.playbackDiagnosticEpisode,
                    value: _diagnosticContextValue(diagnostics.episodeTitle),
                  ),
                  if (selectedAppSourceLabel != null)
                    _DiagnosticRow(
                      label: context.l10n.playbackDiagnosticSelectedAppSource,
                      value: selectedAppSourceLabel,
                    ),
                  if (diagnostics.usedSourceFallback)
                    _DiagnosticRow(
                      label: context.l10n.playbackDiagnosticRequestedSource,
                      value: context.l10n.sourceDisplayLabel(
                        diagnostics.requestedSourceId!,
                      ),
                    ),
                  if (diagnostics.usedSourceFallback)
                    _DiagnosticRow(
                      label: context.l10n.playbackDiagnosticSourceStatus,
                      value: context.l10n.sourceFallbackPlayerNotice(
                        context.l10n.sourceDisplayLabel(
                          diagnostics.requestedSourceId!,
                        ),
                        context.l10n.sourceDisplayLabel(diagnostics.sourceId),
                      ),
                    ),
                  _DiagnosticRow(
                    label: context.l10n.playbackDiagnosticSource,
                    value:
                        context.l10n.sourceDisplayLabel(diagnostics.sourceId),
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
                    value: _diagnosticStateLabel(diagnostics.state),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.diagnosticsPrivacyNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => unawaited(
                      _copyPlaybackDiagnostics(diagnostics: diagnostics),
                    ),
                    icon: const Icon(Icons.content_copy_outlined),
                    label: Text(context.l10n.copyDiagnostics),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PlaybackDiagnostics _recordPlaybackDiagnostics({
    PlayerRouteArgs? args,
    bool force = false,
  }) {
    final routeArgs = args ?? _args;
    final candidate = const PlaybackDiagnosticsBuilder().build(
      animeTitle: routeArgs.animeTitle,
      episodeTitle: routeArgs.episodeTitle,
      selectedAppSourceId: ref.read(currentSourceIdProvider).valueOrNull,
      sourceId: routeArgs.sourceId,
      requestedSourceId: routeArgs.requestedSourceId,
      playSourceTitle: routeArgs.playSourceTitle,
      playUrl: routeArgs.playUrl,
      headers: routeArgs.playHeaders,
      state: _currentDiagnosticState(),
    );
    final previousDiagnostics = ref.read(lastPlaybackDiagnosticsProvider);
    final diagnostics = !force &&
            previousDiagnostics != null &&
            _matchesPlaybackDiagnostics(previousDiagnostics, candidate)
        ? _enrichCapturedSelectedAppSource(previousDiagnostics, candidate)
        : candidate;
    final diagnosticKey = _playbackDiagnosticKey(routeArgs, diagnostics.state);
    final shouldPersistSnapshot = force ||
        _lastPlaybackDiagnosticKey != diagnosticKey ||
        !_samePlaybackDiagnostics(previousDiagnostics, diagnostics);
    unawaited(
      Future<void>(() {
        if (!mounted || _isDisposed) return;
        if (!shouldPersistSnapshot) return;
        _lastPlaybackDiagnosticKey = diagnosticKey;
        ref.read(lastPlaybackDiagnosticsProvider.notifier).state = diagnostics;
      }),
    );
    return diagnostics;
  }

  bool _matchesPlaybackDiagnostics(
    PlaybackDiagnostics previous,
    PlaybackDiagnostics next,
  ) {
    return previous.animeTitle == next.animeTitle &&
        previous.episodeTitle == next.episodeTitle &&
        previous.sourceId == next.sourceId &&
        previous.requestedSourceId == next.requestedSourceId &&
        previous.playSourceTitle == next.playSourceTitle &&
        previous.urlType == next.urlType &&
        previous.sanitizedUrl == next.sanitizedUrl &&
        previous.state == next.state &&
        listEquals(previous.headerKeys, next.headerKeys);
  }

  PlaybackDiagnostics _enrichCapturedSelectedAppSource(
    PlaybackDiagnostics previous,
    PlaybackDiagnostics next,
  ) {
    final previousSelected = previous.selectedAppSourceId?.trim();
    if (previousSelected != null && previousSelected.isNotEmpty) {
      return previous;
    }
    final nextSelected = next.selectedAppSourceId?.trim();
    if (nextSelected == null || nextSelected.isEmpty) {
      return previous;
    }
    return previous.copyWith(selectedAppSourceId: nextSelected);
  }

  bool _samePlaybackDiagnostics(
    PlaybackDiagnostics? previous,
    PlaybackDiagnostics next,
  ) {
    if (previous == null) {
      return false;
    }
    return previous.capturedAt == next.capturedAt &&
        previous.animeTitle == next.animeTitle &&
        previous.episodeTitle == next.episodeTitle &&
        previous.selectedAppSourceId == next.selectedAppSourceId &&
        previous.sourceId == next.sourceId &&
        previous.requestedSourceId == next.requestedSourceId &&
        previous.playSourceTitle == next.playSourceTitle &&
        previous.urlType == next.urlType &&
        previous.sanitizedUrl == next.sanitizedUrl &&
        previous.state == next.state &&
        listEquals(previous.headerKeys, next.headerKeys);
  }

  String _playbackDiagnosticKey(
    PlayerRouteArgs routeArgs,
    PlaybackDiagnosticState state,
  ) {
    final headerKeys = routeArgs.playHeaders.keys.toList(growable: false)
      ..sort();
    return [
      routeArgs.animeId,
      routeArgs.episodeId,
      routeArgs.sourceId,
      routeArgs.requestedSourceId ?? '',
      routeArgs.playSourceId ?? '',
      routeArgs.playSourceTitle ?? '',
      routeArgs.playUrl,
      headerKeys.join(','),
      state.name,
    ].join('|');
  }

  PlaybackDiagnosticState _currentDiagnosticState() {
    if (_state.errorMessage != null) {
      return PlaybackDiagnosticState.error;
    }
    if (_state.isBuffering) {
      return PlaybackDiagnosticState.buffering;
    }
    if (_state.isPlaying) {
      return PlaybackDiagnosticState.playing;
    }
    if (_state.isInitialized) {
      return PlaybackDiagnosticState.ready;
    }
    return PlaybackDiagnosticState.loading;
  }

  String _diagnosticStateLabel(PlaybackDiagnosticState state) {
    return switch (state) {
      PlaybackDiagnosticState.loading =>
        context.l10n.playbackDiagnosticStateLoading,
      PlaybackDiagnosticState.ready =>
        context.l10n.playbackDiagnosticStateReady,
      PlaybackDiagnosticState.playing =>
        context.l10n.playbackDiagnosticStatePlaying,
      PlaybackDiagnosticState.buffering =>
        context.l10n.playbackDiagnosticStateBuffering,
      PlaybackDiagnosticState.error =>
        context.l10n.playbackDiagnosticStateError,
    };
  }

  String _formatPlaybackDiagnosticCapturedAt(
    BuildContext context,
    DateTime capturedAt,
  ) {
    final localizations = MaterialLocalizations.of(context);
    final localCapturedAt = capturedAt.toLocal();
    final date = localizations.formatMediumDate(localCapturedAt);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localCapturedAt),
      alwaysUse24HourFormat: true,
    );
    return '$date $time';
  }

  String _playbackErrorMessage() {
    if (_state.errorMessage == context.l10n.playerNoPlayUrl) {
      return context.l10n.noPlayableSourceFound;
    }
    return context.l10n.playbackFailedSuggestion;
  }

  bool _canRetryPlayback() {
    return _state.errorMessage != null &&
        _state.errorMessage != context.l10n.playerNoPlayUrl &&
        !_isResolvingNextEpisode &&
        !_isSwitchingEpisode &&
        !_isOpeningExternalPlayer &&
        !_isRetryingPlayback &&
        _hasPlayableUrl();
  }

  Future<void> _saveHistory({bool force = false}) {
    return _saveHistoryWithOverrides(force: force);
  }

  Future<void> _saveHistoryWithOverrides({
    bool force = false,
    PlayerRouteArgs? routeArgs,
    Duration? positionOverride,
    Duration? durationOverride,
  }) async {
    final historyArgs = routeArgs ?? _args;
    final historyPosition = positionOverride ?? _state.position;
    final historyDuration = durationOverride ?? _state.duration;
    if (!_state.isInitialized &&
        historyPosition <= Duration.zero &&
        historyDuration <= Duration.zero) {
      return;
    }
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
        id: '${historyArgs.sourceId}:${historyArgs.animeId}:${historyArgs.episodeId}',
        animeId: historyArgs.animeId,
        episodeId: historyArgs.episodeId,
        animeTitle: historyArgs.animeTitle,
        episodeTitle: historyArgs.episodeTitle,
        coverUrl: historyArgs.coverUrl,
        position: historyPosition,
        duration: historyDuration,
        sourceId: historyArgs.sourceId,
        playSourceId: historyArgs.playSourceId,
        playSourceTitle: historyArgs.playSourceTitle,
        playUrl: historyArgs.playUrl,
        playHeaders: historyArgs.playHeaders,
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

  Future<bool> _loadPlayer({
    PlayerRouteArgs? args,
    bool autoplay = false,
    double? playbackSpeed,
    Duration? historyPositionOverride,
    Duration? historyDurationOverride,
  }) async {
    final routeArgs = args ?? _args;
    _recordPlaybackDiagnostics(args: routeArgs);
    try {
      if (!_isPlayableUrl(routeArgs.playUrl)) {
        await Future<void>.delayed(Duration.zero);
        if (!mounted) return false;
        setState(
          () => _state = _state.copyWith(
            isBuffering: false,
            errorMessage: context.l10n.playerNoPlayUrl,
          ),
        );
        _recordPlaybackDiagnostics(args: routeArgs);
        unawaited(_saveHistory(force: true));
        return false;
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
      final resumePosition = historyPositionOverride ??
          (initialPosition != null && initialPosition > Duration.zero
              ? initialPosition
              : null);
      unawaited(
        _saveHistoryWithOverrides(
          force: true,
          routeArgs: routeArgs,
          positionOverride: resumePosition,
          durationOverride: historyDurationOverride,
        ),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(
        () => _state = _state.copyWith(
          isBuffering: false,
          errorMessage: context.l10n.playbackFailedSuggestion,
        ),
      );
      _recordPlaybackDiagnostics(args: routeArgs);
      unawaited(_saveHistory(force: true));
      return false;
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
    if (_isResolvingNextEpisode ||
        _isSwitchingEpisode ||
        _isOpeningExternalPlayer ||
        _isRetryingPlayback) {
      return;
    }

    final currentArgs = _args;
    final previousState = _state;
    final shouldResumePlayback = _state.isPlaying;
    const shouldAutoplayNextEpisode = true;
    final playbackSpeed = _state.speed;
    final restorePosition =
        _state.position > Duration.zero ? _state.position : null;
    final restoreArgs = currentArgs.copyWith(initialPosition: restorePosition);
    var shouldRestoreCurrentPlayback = false;
    var shouldRestorePreviousFailureState = false;
    var startedEpisodeSwitch = false;

    setState(() => _isResolvingNextEpisode = true);
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
        shouldRestorePreviousFailureState = previousState.errorMessage != null;
        _showSnackBar(context.l10n.nextEpisodeUnavailable);
        return;
      }
      setState(() => _switchingEpisodeTitle = nextEpisode.title);

      final playSourceResult = await ref.read(
        playSourcesBySourceProvider(
          (sourceId: detailResult.sourceId, episodeId: nextEpisode.id),
        ).future,
      );
      if (!mounted) return;
      final sources = playSourceResult.value;
      if (sources.isEmpty) {
        shouldRestorePreviousFailureState = previousState.errorMessage != null;
        _showSnackBar(context.l10n.nextEpisodeStayedOnCurrent);
        return;
      }

      final selectedSource = selectPreferredPlaySource(
        sources,
        preferredSourceId: currentArgs.playSourceId,
        preferredSourceTitle: currentArgs.playSourceTitle,
      );
      setState(() {
        _isResolvingNextEpisode = false;
        _isSwitchingEpisode = true;
        _switchingEpisodeTitle = nextEpisode.title;
        if (_state.errorMessage != null) {
          _state = _state.copyWith(clearErrorMessage: true);
        }
      });
      startedEpisodeSwitch = true;
      if (shouldResumePlayback) {
        await _controller.pause();
        shouldRestoreCurrentPlayback = true;
      }
      await _saveHistory(force: true);
      if (!mounted) return;

      final nextArgs = currentArgs.copyWith(
        episodeId: nextEpisode.id,
        episodeTitle: nextEpisode.title,
        sourceId: playSourceResult.sourceId,
        requestedSourceId: playSourceResult.usedFallback
            ? playSourceResult.fromSourceId ?? detailResult.sourceId
            : detailResult.usedFallback
                ? detailResult.fromSourceId ?? currentArgs.sourceId
                : null,
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
      shouldRestoreCurrentPlayback = false;

      final switched = await _loadPlayer(
        args: nextArgs,
        autoplay: shouldAutoplayNextEpisode,
        playbackSpeed: playbackSpeed,
      );
      if (!mounted) return;
      if (!switched) {
        setState(() {
          _currentArgs = currentArgs;
          _state = PlayerState.initial();
          _lastHistorySavedAt = null;
          _switchingEpisodeTitle = null;
        });
        await _loadPlayer(
          args: restoreArgs,
          autoplay: shouldResumePlayback,
          playbackSpeed: playbackSpeed,
          historyPositionOverride: restorePosition,
          historyDurationOverride: previousState.duration > Duration.zero
              ? previousState.duration
              : null,
        );
        if (!mounted) return;
        _showSnackBar(context.l10n.nextEpisodeStayedOnCurrent);
        return;
      }
      if (detailResult.usedFallback || playSourceResult.usedFallback) {
        _showSnackBar(_sourceFallbackNotice(context));
      }
    } catch (error) {
      if (!mounted) return;
      shouldRestorePreviousFailureState = previousState.errorMessage != null;
      _showSnackBar(context.l10n.nextEpisodeStayedOnCurrent);
    } finally {
      if (mounted && shouldRestoreCurrentPlayback) {
        try {
          await _controller.play();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _isResolvingNextEpisode = false;
          if (!startedEpisodeSwitch) {
            _switchingEpisodeTitle = null;
          }
          if (startedEpisodeSwitch) {
            _isSwitchingEpisode = false;
            _switchingEpisodeTitle = null;
          }
          if (shouldRestorePreviousFailureState) {
            _state = previousState;
          }
        });
      }
    }
  }

  Future<void> _openExternalPlayer() async {
    if (_isOpeningExternalPlayer ||
        _isSwitchingEpisode ||
        _isRetryingPlayback) {
      return;
    }
    final rawUrl = _args.playUrl.trim();
    final uri = Uri.tryParse(rawUrl);
    if (rawUrl.isEmpty || uri == null || !uri.hasScheme) {
      _showSnackBar(context.l10n.noPlayableSourceFound);
      return;
    }
    if (_args.playHeaders.isNotEmpty) {
      _showSnackBar(
        context.l10n.externalPlayerHeadersUnsupported(
          _activeSourceLabel(context),
        ),
      );
      return;
    }

    final previousState = _state;
    final shouldPauseCurrentPlayback = _state.isPlaying;
    var shouldResumeCurrentPlayback = false;
    var shouldRestorePreviousFailureState = false;
    var didOpenExternalPlayer = false;

    setState(() {
      _isOpeningExternalPlayer = true;
      if (_state.errorMessage != null) {
        _state = _state.copyWith(clearErrorMessage: true);
      }
    });
    try {
      if (shouldPauseCurrentPlayback) {
        await _controller.pause();
        shouldResumeCurrentPlayback = true;
      }
      final launched = await ref.read(externalPlayerLauncherProvider)(uri);
      if (!mounted) return;
      if (!launched) {
        shouldRestorePreviousFailureState = previousState.errorMessage != null;
        _showSnackBar(
          context.l10n.externalPlayerUnavailable(_activeSourceLabel(context)),
        );
        return;
      }

      didOpenExternalPlayer = true;
      shouldResumeCurrentPlayback = false;
      shouldRestorePreviousFailureState = previousState.errorMessage != null;
      await _saveHistory(force: true);
      if (_isFullscreen) {
        await _exitFullscreen();
      }
    } catch (_) {
      if (!mounted) return;
      shouldRestorePreviousFailureState = previousState.errorMessage != null;
      _showSnackBar(
        context.l10n.externalPlayerUnavailable(_activeSourceLabel(context)),
      );
    } finally {
      if (mounted && shouldResumeCurrentPlayback) {
        try {
          await _controller.play();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _isOpeningExternalPlayer = false;
          if (shouldRestorePreviousFailureState) {
            _state = previousState;
          }
        });
      }
    }
    if (mounted && didOpenExternalPlayer) {
      _showSnackBar(
        context.l10n.externalPlayerOpened(_activeSourceLabel(context)),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _copyPlaybackDiagnostics({
    PlaybackDiagnostics? diagnostics,
  }) async {
    final snapshot = diagnostics ?? _recordPlaybackDiagnostics();
    final summary = _playbackDiagnosticsSummary(
      snapshot,
      selectedAppSourceLabel: _selectedAppSourceLabelForDiagnostics(
        context,
        snapshot,
      ),
    );

    try {
      await Clipboard.setData(ClipboardData(text: summary));
      if (!mounted) return;
      _showSnackBar(context.l10n.diagnosticsCopied);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(context.l10n.diagnosticsCopyFailed);
    }
  }

  String _playbackDiagnosticsSummary(
    PlaybackDiagnostics diagnostics, {
    String? selectedAppSourceLabel,
  }) {
    final lineTitle = diagnostics.playSourceTitle?.trim();
    final headers = diagnostics.headerKeys.isEmpty
        ? '-'
        : diagnostics.headerKeys.join(', ');
    final summary = <String>[
      context.l10n.playbackDiagnosticsSummary,
      '${context.l10n.playbackDiagnosticAnime}: '
          '${_diagnosticContextValue(diagnostics.animeTitle)}',
      '${context.l10n.playbackDiagnosticEpisode}: '
          '${_diagnosticContextValue(diagnostics.episodeTitle)}',
    ];
    if (selectedAppSourceLabel != null) {
      summary.add(
        '${context.l10n.playbackDiagnosticSelectedAppSource}: '
        '$selectedAppSourceLabel',
      );
    }
    if (diagnostics.usedSourceFallback) {
      summary.add(
        '${context.l10n.playbackDiagnosticRequestedSource}: '
        '${context.l10n.sourceDisplayLabel(diagnostics.requestedSourceId!)}',
      );
      summary.add(
        '${context.l10n.playbackDiagnosticSourceStatus}: '
        '${context.l10n.sourceFallbackPlayerNotice(
          context.l10n.sourceDisplayLabel(diagnostics.requestedSourceId!),
          context.l10n.sourceDisplayLabel(diagnostics.sourceId),
        )}',
      );
    }
    summary.addAll([
      '${context.l10n.playbackDiagnosticCapturedAt}: '
          '${diagnostics.capturedAt.toIso8601String()}',
      '${context.l10n.playbackDiagnosticSource}: '
          '${context.l10n.sourceDisplayLabel(diagnostics.sourceId)}',
      '${context.l10n.playbackDiagnosticLine}: '
          '${lineTitle == null || lineTitle.isEmpty ? '-' : lineTitle}',
      '${context.l10n.playbackDiagnosticUrlType}: ${diagnostics.urlType}',
      '${context.l10n.playbackDiagnosticUrl}: ${diagnostics.sanitizedUrl}',
      '${context.l10n.playbackDiagnosticHeaders}: $headers',
      '${context.l10n.playbackDiagnosticState}: '
          '${_diagnosticStateLabel(diagnostics.state)}',
    ]);
    return summary.join('\n');
  }

  String? _selectedAppSourceLabelForDiagnostics(
    BuildContext context,
    PlaybackDiagnostics diagnostics,
  ) {
    final selectedAppSourceId = diagnostics.divergentSelectedAppSourceId();
    if (selectedAppSourceId == null) {
      return null;
    }
    return context.l10n.sourceDisplayLabel(selectedAppSourceId);
  }

  String _diagnosticContextValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '-';
    }
    return trimmed;
  }

  bool _hasSourceFallbackContext() {
    final requestedSourceId = _args.requestedSourceId?.trim();
    return requestedSourceId != null &&
        requestedSourceId.isNotEmpty &&
        requestedSourceId != _args.sourceId;
  }

  String _activeSourceLabel(BuildContext context) {
    return context.l10n.sourceDisplayLabel(_args.sourceId);
  }

  String _sourceFallbackNotice(BuildContext context) {
    final requestedSourceId = _args.requestedSourceId!;
    return context.l10n.sourceFallbackPlayerNotice(
      context.l10n.sourceDisplayLabel(requestedSourceId),
      _activeSourceLabel(context),
    );
  }

  Future<void> _retryPlayback() async {
    if (!_canRetryPlayback() || _isRetryingPlayback) return;

    final previousState = _state;
    final playbackSpeed = _state.speed;
    final resumePosition =
        _state.position > Duration.zero ? _state.position : null;
    final retryArgs = _args.copyWith(initialPosition: resumePosition);
    var shouldRestoreRetryContext = false;
    String? retryFailureMessage;
    setState(() {
      _isRetryingPlayback = true;
      _state = PlayerState.initial().copyWith(
        isBuffering: true,
      );
    });
    try {
      final retried = await _loadPlayer(
        args: retryArgs,
        autoplay: true,
        playbackSpeed: playbackSpeed,
        historyPositionOverride: resumePosition,
        historyDurationOverride: previousState.duration > Duration.zero
            ? previousState.duration
            : null,
      );
      if (!mounted) return;
      shouldRestoreRetryContext = !retried;
      retryFailureMessage = _state.errorMessage;
    } finally {
      if (mounted) {
        setState(() {
          _isRetryingPlayback = false;
          if (shouldRestoreRetryContext) {
            _state = previousState.copyWith(
              isPlaying: false,
              isBuffering: false,
              errorMessage: retryFailureMessage ?? previousState.errorMessage,
            );
          }
        });
        if (shouldRestoreRetryContext) {
          unawaited(_saveHistory(force: true));
        }
      }
    }
  }
}

bool _isPlayableUrl(String value) {
  final rawUrl = value.trim();
  final uri = Uri.tryParse(rawUrl);
  return rawUrl.isNotEmpty && uri != null && uri.hasScheme;
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

class _SourceFallbackBanner extends StatelessWidget {
  const _SourceFallbackBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerAppBarTitle extends StatelessWidget {
  const _PlayerAppBarTitle({
    required this.title,
    this.status,
  });

  final String title;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final titleText = title.trim().isEmpty ? '-' : title.trim();
    final statusText = status?.trim();
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (statusText != null && statusText.isNotEmpty)
          Text(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: Colors.white70,
            ),
          ),
      ],
    );
  }
}

class _PlaybackTransitionOverlay extends StatelessWidget {
  const _PlaybackTransitionOverlay({
    required this.message,
    this.detail,
  });

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final detailText = detail?.trim();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onInverseSurface,
                    ),
              ),
              if (detailText != null && detailText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  detailText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onInverseSurface.withValues(
                          alpha: 0.84,
                        ),
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaybackIssueContext extends StatelessWidget {
  const _PlaybackIssueContext({
    required this.animeTitle,
    required this.episodeTitle,
    required this.requestedSourceLabel,
    required this.sourceLabel,
    required this.playSourceTitle,
  });

  final String animeTitle;
  final String episodeTitle;
  final String? requestedSourceLabel;
  final String sourceLabel;
  final String? playSourceTitle;

  @override
  Widget build(BuildContext context) {
    final animeTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        );
    final episodeTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    final sourceTextStyle = episodeTextStyle;
    final lineTextStyle = episodeTextStyle;
    final lineTitle = playSourceTitle?.trim();
    final episodeLabel =
        episodeTitle.trim().isEmpty ? '-' : episodeTitle.trim();
    final animeLabel = animeTitle.trim().isEmpty ? '-' : animeTitle.trim();
    final requestedSource = requestedSourceLabel?.trim();
    final sourceContextLabel = requestedSource == null ||
            requestedSource.isEmpty
        ? sourceLabel
        : '$sourceLabel (${context.l10n.playbackDiagnosticRequestedSource}: '
            '$requestedSource)';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${context.l10n.playbackDiagnosticAnime}: $animeLabel',
          textAlign: TextAlign.center,
          style: animeTextStyle,
        ),
        const SizedBox(height: 4),
        Text(
          '${context.l10n.playbackDiagnosticEpisode}: $episodeLabel',
          textAlign: TextAlign.center,
          style: episodeTextStyle,
        ),
        const SizedBox(height: 8),
        Text(
          '${context.l10n.playbackDiagnosticSource}: $sourceContextLabel',
          textAlign: TextAlign.center,
          style: sourceTextStyle,
        ),
        if (lineTitle != null && lineTitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${context.l10n.playbackDiagnosticLine}: $lineTitle',
            textAlign: TextAlign.center,
            style: lineTextStyle,
          ),
        ],
      ],
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
