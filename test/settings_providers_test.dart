import 'package:ani_destiny/core/constants/app_constants.dart';
import 'package:ani_destiny/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('app version label reads runtime package metadata', () async {
    PackageInfo.setMockInitialValues(
      appName: AppConstants.appName,
      packageName: AppConstants.packageName,
      version: '1.2.3',
      buildNumber: '9',
      buildSignature: '',
    );
    addTearDown(() {
      PackageInfo.setMockInitialValues(
        appName: AppConstants.appName,
        packageName: AppConstants.packageName,
        version: AppConstants.appVersion,
        buildNumber: '',
        buildSignature: '',
      );
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(appVersionLabelProvider.future), '1.2.3');
  });
}
