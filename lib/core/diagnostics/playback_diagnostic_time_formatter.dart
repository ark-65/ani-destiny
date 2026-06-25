String formatPlaybackDiagnosticCapturedAt(
  DateTime capturedAt, {
  required String localeName,
  bool includeExactIso = false,
}) {
  final localCapturedAt = capturedAt.toLocal();
  final languageCode = localeName.split('-').first.toLowerCase();
  final readable = switch (languageCode) {
    'en' => _formatEnglish(localCapturedAt),
    'ja' => _formatJapanese(localCapturedAt),
    _ => _formatChinese(localCapturedAt),
  };
  if (!includeExactIso) {
    return readable;
  }
  return '$readable (${capturedAt.toIso8601String()})';
}

String _formatChinese(DateTime capturedAt) {
  return '${capturedAt.year}年'
      '${capturedAt.month}月'
      '${capturedAt.day}日 '
      '${_pad2(capturedAt.hour)}:${_pad2(capturedAt.minute)}';
}

String _formatJapanese(DateTime capturedAt) {
  return '${capturedAt.year}/'
      '${_pad2(capturedAt.month)}/'
      '${_pad2(capturedAt.day)} '
      '${_pad2(capturedAt.hour)}:${_pad2(capturedAt.minute)}';
}

String _formatEnglish(DateTime capturedAt) {
  return '${_englishMonth(capturedAt.month)} '
      '${capturedAt.day}, '
      '${capturedAt.year} '
      '${_pad2(capturedAt.hour)}:${_pad2(capturedAt.minute)}';
}

String _englishMonth(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

String _pad2(int value) => value.toString().padLeft(2, '0');
