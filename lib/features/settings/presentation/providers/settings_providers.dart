import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';

final appVersionLabelProvider = Provider<String>(
  (ref) => AppConstants.appVersion,
);
