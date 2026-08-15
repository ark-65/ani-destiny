import 'package:dio/dio.dart';

import '../entities/hls_manifest.dart';

abstract class HlsManifestLoader {
  const HlsManifestLoader();

  Future<HlsManifest> load(
    Uri manifestUri, {
    Map<String, String> headers,
    Map<String, String> importedVariables,
    CancelToken? cancelToken,
  });
}
