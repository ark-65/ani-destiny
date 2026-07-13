import '../../domain/entities/download_kind.dart';
import '../../domain/entities/download_source.dart';
import '../../domain/services/download_service.dart';
import '../../domain/services/download_type_detector.dart';

class CreatedDownloadTask {
  const CreatedDownloadTask({
    required this.taskId,
    required this.kind,
  });

  final String taskId;
  final DownloadKind kind;

  bool get isSupported => kind == DownloadKind.directFile;
}

class DownloadTaskCreator {
  const DownloadTaskCreator(this._service);

  final DownloadService _service;

  Future<CreatedDownloadTask> create({
    required String animeId,
    required String episodeId,
    required String sourceId,
    required String url,
    required String title,
    required String episodeTitle,
    String? lineTitle,
    Map<String, String> headers = const {},
    String? fileName,
    String? mimeType,
  }) async {
    final kind = detectDownloadKind(url, contentType: mimeType);
    final taskId = await _service.createTask(
      animeId: animeId,
      episodeId: episodeId,
      sourceId: sourceId,
      source: DownloadSource(
        url: url,
        kind: kind,
        headers: headers,
        fileName: fileName,
        mimeType: mimeType,
      ),
      title: title,
      episodeTitle: _buildEpisodeTitle(
        episodeTitle: episodeTitle,
        lineTitle: lineTitle,
      ),
    );
    return CreatedDownloadTask(taskId: taskId, kind: kind);
  }

  String _buildEpisodeTitle({
    required String episodeTitle,
    String? lineTitle,
  }) {
    final trimmedEpisodeTitle = episodeTitle.trim();
    final trimmedLineTitle = lineTitle?.trim();
    if (trimmedLineTitle == null || trimmedLineTitle.isEmpty) {
      return trimmedEpisodeTitle;
    }
    if (_isLineTitleAlreadyIncludedInEpisodeTitle(
      episodeTitle: trimmedEpisodeTitle,
      lineTitle: trimmedLineTitle,
    )) {
      return trimmedEpisodeTitle;
    }
    return '$trimmedEpisodeTitle - $trimmedLineTitle';
  }

  bool _isLineTitleAlreadyIncludedInEpisodeTitle({
    required String episodeTitle,
    required String lineTitle,
  }) {
    final normalizedEpisodeTitle = _normalizeEpisodePart(episodeTitle);
    final normalizedLineTitle = _normalizeEpisodePart(lineTitle);
    if (normalizedEpisodeTitle == normalizedLineTitle) {
      return true;
    }

    const separatorBoundary = r'[\s\-–—·|()<>/:;.!?\[\]]';
    final boundaryPattern = RegExp(
      '(?:^|$separatorBoundary)${RegExp.escape(normalizedLineTitle)}'
      '(?=${'\$'}|$separatorBoundary)',
    );
    return boundaryPattern.hasMatch(normalizedEpisodeTitle);
  }

  String _normalizeEpisodePart(String title) {
    return title
        .toLowerCase()
        .replaceAll('「', '(')
        .replaceAll('」', ')')
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .replaceAll('【', '[')
        .replaceAll('】', ']')
        .replaceAll('《', '<')
        .replaceAll('》', '>')
        .replaceAll('〈', '<')
        .replaceAll('〉', '>')
        .replaceAll('－', '-')
        .replaceAll('：', ':')
        .replaceAll('；', ';')
        .replaceAll('，', ',')
        .replaceAll('、', ',')
        .replaceAll('。', '.')
        .replaceAll('！', '!')
        .replaceAll('？', '?')
        .replaceAll('／', '/')
        .replaceAll('｜', '|')
        .replaceAll('\u3000', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
