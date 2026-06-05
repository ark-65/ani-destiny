import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search empty copy no longer points users to the mock source', () {
    for (final locale in const [
      Locale('zh'),
      Locale('en'),
      Locale('ja'),
    ]) {
      final l10n = AppLocalizations(locale);
      expect(l10n.searchEmpty.toLowerCase(), isNot(contains('mock')));
    }
  });
}
