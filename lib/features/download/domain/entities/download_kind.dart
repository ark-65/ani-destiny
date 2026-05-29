enum DownloadKind {
  directFile,
  hls,
  bt,
  unknown,
}

DownloadKind downloadKindFromName(String value) {
  return DownloadKind.values.firstWhere(
    (kind) => kind.name == value,
    orElse: () => DownloadKind.unknown,
  );
}
