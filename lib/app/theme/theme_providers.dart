import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_controller.dart';

final themeModeProvider = StateNotifierProvider<ThemeController, ThemeMode>(
  (ref) => ThemeController(),
);
