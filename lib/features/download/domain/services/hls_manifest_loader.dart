import '../entities/hls_manifest.dart';

abstract class HlsManifestLoader {
  const HlsManifestLoader();

  Future<HlsManifest> load(Uri manifestUri, {Map<String, String> headers});
}

