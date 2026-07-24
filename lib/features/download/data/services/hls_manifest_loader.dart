import 'package:dio/dio.dart';

import '../../domain/entities/hls_manifest.dart';
import '../../domain/services/hls_manifest_loader.dart';
import 'hls_manifest_parser.dart';

class DioHlsManifestLoader extends HlsManifestLoader {
  const DioHlsManifestLoader({
    required Dio dio,
    HlsManifestParser? parser,
  })  : _dio = dio,
        _parser = parser ?? const HlsManifestParser();

  final Dio _dio;
  final HlsManifestParser _parser;

  @override
  Future<HlsManifest> load(Uri manifestUri, {Map<String, String> headers = const {}}) {
    return _load(manifestUri, headers: headers);
  }

  Future<HlsManifest> _load(Uri manifestUri, {Map<String, String> headers = const {}}) async {
    final response = await _dio.getUri<String>(
      manifestUri,
      options: Options(
        responseType: ResponseType.plain,
        headers: headers.isEmpty ? null : headers,
      ),
    );
    final body = response.data ?? '';
    return _parser.parse(body, uri: manifestUri);
  }
}
