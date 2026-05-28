import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system) {
    _load();
  }

  static const _themeModeKey = 'theme_mode';

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, mode.name);
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_themeModeKey);
    state = ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }
}
