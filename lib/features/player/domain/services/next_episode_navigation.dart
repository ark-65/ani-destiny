import '../../../anime/domain/entities/episode.dart';
import '../../../anime/domain/entities/play_source.dart';

Episode? resolveNextEpisode({
  required List<Episode> episodes,
  required String currentEpisodeId,
  int? currentEpisodeIndex,
  String? currentEpisodeTitle,
}) {
  if (episodes.isEmpty) return null;

  var currentPosition = episodes.indexWhere(
    (episode) => episode.id == currentEpisodeId,
  );
  if (currentPosition == -1 && currentEpisodeIndex != null) {
    currentPosition = episodes.indexWhere(
      (episode) => episode.index == currentEpisodeIndex,
    );
  }
  if (currentPosition == -1) {
    final normalizedTitle = _normalizeEpisodeTitle(currentEpisodeTitle);
    if (normalizedTitle.isNotEmpty) {
      currentPosition = episodes.indexWhere(
        (episode) => _normalizeEpisodeTitle(episode.title) == normalizedTitle,
      );
    }
  }
  if (currentPosition < 0 || currentPosition >= episodes.length - 1) {
    return null;
  }

  return episodes[currentPosition + 1];
}

PlaySource selectPreferredPlaySource(
  List<PlaySource> sources, {
  String? preferredSourceId,
  String? preferredSourceTitle,
}) {
  assert(sources.isNotEmpty, 'sources must not be empty');

  final normalizedTitle = _normalizeSourceTitle(preferredSourceTitle);
  for (final source in sources) {
    if (preferredSourceId != null && source.id == preferredSourceId) {
      return source;
    }
  }
  if (normalizedTitle.isNotEmpty) {
    for (final source in sources) {
      if (_normalizeSourceTitle(source.title) == normalizedTitle) {
        return source;
      }
    }
  }

  return sources.first;
}

String _normalizeSourceTitle(String? value) {
  if (value == null) return '';
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String _normalizeEpisodeTitle(String? value) {
  if (value == null) return '';
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
