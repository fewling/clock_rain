import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_preference.dart';

part 'preference_provider.g.dart';

final sharedPreferenceProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError();
});

@riverpod
class AppPreferenceNotifier extends _$AppPreferenceNotifier {
  static const colorSchemeKey = 'color scheme';
  static const isDarkModeKey = 'dark mode';
  static const uprightTextKey = 'upright text';

  @override
  AppPreference build() {
    final sp = ref.watch(sharedPreferenceProvider);
    final colorSeed = sp.getInt(colorSchemeKey) ?? Colors.green.value;
    final isDarkMode = sp.getBool(isDarkModeKey) ?? false;
    final uprightText = sp.getBool(uprightTextKey) ?? false;

    return AppPreference(
      colorSchemeSeed: colorSeed,
      isDarkMode: isDarkMode,
      uprightText: uprightText,
    );
  }

  void setColorSchemeSeed(int colorValue) {
    final sp = ref.read(sharedPreferenceProvider);
    sp.setInt(colorSchemeKey, colorValue).then((success) {
      if (success) {
        state = state.copyWith(colorSchemeSeed: colorValue);
      }
    });
  }

  void toggleBrightness() {
    final isDark = state.isDarkMode;

    ref
        .read(sharedPreferenceProvider)
        .setBool(isDarkModeKey, !isDark)
        .then((value) => state = state.copyWith(isDarkMode: !isDark));
  }

  void toggleUprightText() {
    final isUpright = state.uprightText;

    ref
        .read(sharedPreferenceProvider)
        .setBool(uprightTextKey, !isUpright)
        .then((value) => state = state.copyWith(uprightText: !isUpright));
  }
}
