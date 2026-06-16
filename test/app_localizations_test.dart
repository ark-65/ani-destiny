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

  test('source settings copy no longer recommends the mock source', () {
    for (final locale in const [
      Locale('zh'),
      Locale('en'),
      Locale('ja'),
    ]) {
      final l10n = AppLocalizations(locale);
      expect(
        l10n.sourceSettingsSubtitle.toLowerCase(),
        isNot(contains('mock')),
      );
      expect(l10n.sourceV1Note.toLowerCase(), isNot(contains('mock')));
      expect(
        l10n.sourceDisplayDescription('sakura', 'ignored').toLowerCase(),
        isNot(contains('experimental')),
      );
      expect(
        l10n.sourceStatusValue.toLowerCase(),
        isNot(contains('experimental')),
      );
    }
  });

  test('player placeholder copy no longer exposes mock wording', () {
    for (final locale in const [
      Locale('zh'),
      Locale('en'),
      Locale('ja'),
    ]) {
      final l10n = AppLocalizations(locale);
      expect(l10n.playerReadyHint.toLowerCase(), isNot(contains('mock')));
    }
  });

  test('external player copy no longer uses placeholder text', () {
    for (final locale in const [
      Locale('zh'),
      Locale('en'),
      Locale('ja'),
    ]) {
      final l10n = AppLocalizations(locale);
      expect(l10n.externalPlayer.toLowerCase(), isNot(contains('placeholder')));
      expect(
        l10n.externalPlayerUnavailable.toLowerCase(),
        isNot(contains('not implemented')),
      );
    }
  });

  test('source health labels stay localized in Chinese and Japanese', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.sourceHealthHealthy, '正常');
    expect(zh.sourceHealthDegraded, '不稳定');
    expect(zh.sourceHealthUnavailable, '不可用');

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.sourceHealthHealthy, '正常');
    expect(ja.sourceHealthDegraded, '不安定');
    expect(ja.sourceHealthUnavailable, '利用不可');
  });
}
