import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockState {
  final bool isAppLockEnabled;
  final bool isUnlocked;
  final int backgroundTimeoutSeconds;

  const AppLockState({
    this.isAppLockEnabled = false,
    this.isUnlocked = false,
    this.backgroundTimeoutSeconds = 0, // 0 = immediately
  });

  AppLockState copyWith({
    bool? isAppLockEnabled,
    bool? isUnlocked,
    int? backgroundTimeoutSeconds,
  }) {
    return AppLockState(
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      backgroundTimeoutSeconds:
          backgroundTimeoutSeconds ?? this.backgroundTimeoutSeconds,
    );
  }
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  static const _keyEnabled = 'settings_app_lock_enabled';
  static const _keyTimeout = 'settings_app_lock_timeout';

  final LocalAuthentication _localAuth = LocalAuthentication();
  DateTime? _pausedTime;

  AppLockNotifier() : super(const AppLockState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? false;
    final timeout = prefs.getInt(_keyTimeout) ?? 0;
    state = AppLockState(
      isAppLockEnabled: enabled,
      isUnlocked: !enabled, // If not enabled, it's considered unlocked
      backgroundTimeoutSeconds: timeout,
    );
  }

  Future<bool> setAppLockEnabled(bool enabled) async {
    if (enabled) {
      final success = await authenticate(
        reason: 'Authenticate to enable App Lock',
      );
      if (!success) return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    state = state.copyWith(isAppLockEnabled: enabled, isUnlocked: true);
    return true;
  }

  Future<void> setBackgroundTimeout(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimeout, seconds);
    state = state.copyWith(backgroundTimeoutSeconds: seconds);
  }

  Future<bool> authenticate({String reason = 'Unlock NoteOn'}) async {
    try {
      final canCheck =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canCheck) {
        // Device has no biometric/PIN hardware support, allow pass in demo/unsupported environment
        state = state.copyWith(isUnlocked: true);
        return true;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );

      if (authenticated) {
        state = state.copyWith(isUnlocked: true);
      }
      return authenticated;
    } on PlatformException catch (_) {
      return false;
    }
  }

  void onAppPaused() {
    if (state.isAppLockEnabled) {
      _pausedTime = DateTime.now();
    }
  }

  void onAppResumed() {
    if (!state.isAppLockEnabled) return;
    if (_pausedTime == null) return;

    final diffSeconds = DateTime.now().difference(_pausedTime!).inSeconds;
    if (diffSeconds >= state.backgroundTimeoutSeconds) {
      state = state.copyWith(isUnlocked: false);
    }
    _pausedTime = null;
  }

  void lock() {
    if (state.isAppLockEnabled) {
      state = state.copyWith(isUnlocked: false);
    }
  }
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>((
  ref,
) {
  return AppLockNotifier();
});
