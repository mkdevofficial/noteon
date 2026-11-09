import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<Locale?> {
  static const _keyLocale = 'settings_app_locale';

  LocaleNotifier() : super(null) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_keyLocale);
    if (langCode != null && (langCode == 'ar' || langCode == 'en')) {
      state = Locale(langCode);
    } else {
      state = null; // System default
    }
  }

  Future<void> setLocale(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null) {
      state = null;
      await prefs.remove(_keyLocale);
    } else {
      state = Locale(languageCode);
      await prefs.setString(_keyLocale, languageCode);
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});
