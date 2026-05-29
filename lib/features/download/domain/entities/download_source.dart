import 'download_kind.dart';

class DownloadSource {
  const DownloadSource({
    required this.url,
    required this.kind,
    this.headers = const {},
    this.fileName,
    this.mimeType,
  });

  final String url;
  final DownloadKind kind;
  final Map<String, String> headers;
  final String? fileName;
  final String? mimeType;
}
