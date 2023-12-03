import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_preference.dart';

final sharedPreferenceProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError();
});

final appPreferenceProvider =
    NotifierProvider<AppPreferenceNotifier, AppPreference>(
        AppPreferenceNotifier.new);

class AppPreferenceNotifier extends Notifier<AppPreference> {
  static const colorSchemeKey = 'color scheme';
  static const isDarkModeKey = 'dark mode';

  @override
  AppPreference build() {
    final sp = ref.watch(sharedPreferenceProvider);
    final colorSeed = sp.getInt(colorSchemeKey) ?? Colors.green.value;
    final isDarkMode = sp.getBool(isDarkModeKey) ?? false;

    return AppPreference(
      colorSchemeSeed: colorSeed,
      isDarkMode: isDarkMode,
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
}
