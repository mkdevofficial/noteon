import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noteon/core/constants/app_constants.dart';
import 'package:noteon/core/theme/app_theme.dart';

class ThemeSettings {
  final AppThemeMode themeMode;
  final Color accentColor;
  final double fontScale;

  const ThemeSettings({
    this.themeMode = AppThemeMode.system,
    this.accentColor = const Color(0xFF4A6572),
    this.fontScale = 1.0,
  });

  ThemeSettings copyWith({
    AppThemeMode? themeMode,
    Color? accentColor,
    double? fontScale,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeSettings> {
  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyAccentColor = 'settings_accent_color';
  static const _keyFontScale = 'settings_font_scale';

  ThemeNotifier() : super(const ThemeSettings()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyThemeMode);
    final colorValue = prefs.getInt(_keyAccentColor);
    final fontScale = prefs.getDouble(_keyFontScale);

    state = ThemeSettings(
      themeMode: themeIndex != null && themeIndex < AppThemeMode.values.length
          ? AppThemeMode.values[themeIndex]
          : AppThemeMode.system,
      accentColor: colorValue != null
          ? Color(colorValue)
          : AppConstants.accentColors.first,
      fontScale: fontScale ?? 1.0,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccentColor, color.toARGB32());
  }

  Future<void> setFontScale(double scale) async {
    state = state.copyWith(fontScale: scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontScale, scale);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeSettings>((
  ref,
) {
  return ThemeNotifier();
});
