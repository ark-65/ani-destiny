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
    expect(zh.sourceHealthDegradedHint, isNot(contains('fallback')));
    expect(zh.sourceHealthUnavailableHint, isNot(contains('fallback')));

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.sourceHealthHealthy, '正常');
    expect(ja.sourceHealthDegraded, '不安定');
    expect(ja.sourceHealthUnavailable, '利用不可');
    expect(ja.sourceHealthDegradedHint, isNot(contains('fallback')));
    expect(ja.sourceHealthUnavailableHint, isNot(contains('fallback')));
  });

  test('runtime diagnostics helpers keep support copy localized', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.runtimeDiagnosticsSubtitle, isNot(contains('Debug')));
    expect(zh.playbackDiagnosticsDebugHint, isNot(contains('Debug')));
    expect(zh.playbackDiagnosticsDebugHint, isNot(contains('header keys')));
    expect(zh.sourceFallbackEvents, isNot(contains('fallback')));
    expect(zh.sourceFallbackEventsEmpty, isNot(contains('fallback')));
    expect(zh.playbackDiagnosticHeaders, '请求头');
    expect(zh.yesNo(true), '是');
    expect(zh.yesNo(false), '否');
    expect(zh.platformDisplayName('android'), 'Android');
    expect(zh.sourceOperationLabel('detail'), '详情');

    const en = AppLocalizations(Locale('en'));
    expect(en.playbackDiagnosticHeaders, 'Request headers');
    expect(en.sourceOperationLabel('play_sources'), 'Playback lines');
    expect(en.yesNo(true), 'Yes');
    expect(en.yesNo(false), 'No');

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.runtimeDiagnosticsSubtitle, isNot(contains('Debug')));
    expect(ja.playbackDiagnosticsDebugHint, isNot(contains('Debug')));
    expect(ja.playbackDiagnosticsDebugHint, isNot(contains('header keys')));
    expect(ja.sourceFallbackEvents, isNot(contains('fallback')));
    expect(ja.sourceFallbackEventsEmpty, isNot(contains('fallback')));
    expect(ja.playbackDiagnosticHeaders, 'リクエストヘッダー');
    expect(ja.yesNo(true), 'はい');
    expect(ja.yesNo(false), 'いいえ');
    expect(ja.platformDisplayName('windows'), 'Windows');
    expect(ja.sourceOperationLabel('detail'), '詳細');
  });
}
