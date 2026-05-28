class AppLogger {
  const AppLogger._();

  static void info(String message) {
    assert(() {
      // ignore: avoid_print
      print('[AniDestiny] $message');
      return true;
    }());
  }
}
