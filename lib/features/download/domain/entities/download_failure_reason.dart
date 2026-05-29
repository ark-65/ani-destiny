enum DownloadFailureReason {
  none,
  unsupportedType,
  permissionDenied,
  networkError,
  sourceUnavailable,
  invalidUrl,
  invalidManifest,
  storageUnavailable,
  canceled,
  unknown,
}

DownloadFailureReason downloadFailureReasonFromName(String value) {
  return DownloadFailureReason.values.firstWhere(
    (reason) => reason.name == value,
    orElse: () => DownloadFailureReason.unknown,
  );
}
