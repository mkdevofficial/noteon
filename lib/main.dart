import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/core/l10n/locale_provider.dart';
import 'package:noteon/core/router/app_router.dart';
import 'package:noteon/core/theme/app_theme.dart';
import 'package:noteon/core/theme/theme_provider.dart';
import 'package:noteon/features/reminders/reminder_service.dart';
import 'package:noteon/features/settings/app_lock_service.dart';
import 'package:noteon/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Notifications and Reminders
  try {
    await ReminderService.instance.initialize();
  } catch (_) {}

  // Attempt Firebase Initialization
  bool firebaseInitialized = false;
  String? firebaseError;

  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options != null) {
      await Firebase.initializeApp(options: options);
      // Spark plan optimization: Firestore offline persistence
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      firebaseInitialized = true;
    }
  } catch (e) {
    firebaseError = e.toString();
  }

  runApp(
    ProviderScope(
      child: NoteOnApp(
        isFirebaseReady: firebaseInitialized,
        firebaseInitError: firebaseError,
      ),
    ),
  );
}

class NoteOnApp extends ConsumerStatefulWidget {
  final bool isFirebaseReady;
  final String? firebaseInitError;

  const NoteOnApp({
    super.key,
    required this.isFirebaseReady,
    this.firebaseInitError,
  });

  @override
  ConsumerState<NoteOnApp> createState() => _NoteOnAppState();
}

class _NoteOnAppState extends ConsumerState<NoteOnApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final appLockNotifier = ref.read(appLockProvider.notifier);
    if (state == AppLifecycleState.paused) {
      appLockNotifier.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      appLockNotifier.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);

    // Build ThemeData
    final lightTheme = AppTheme.lightTheme(
      themeSettings.accentColor,
      fontScale: themeSettings.fontScale,
    );
    final darkTheme = themeSettings.themeMode == AppThemeMode.amoled
        ? AppTheme.amoledTheme(
            themeSettings.accentColor,
            fontScale: themeSettings.fontScale,
          )
        : AppTheme.darkTheme(
            themeSettings.accentColor,
            fontScale: themeSettings.fontScale,
          );

    final ThemeMode mode = switch (themeSettings.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.amoled => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'NoteOn',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: mode,
      locale: locale,
      supportedLocales: const [Locale('en', ''), Locale('ar', '')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
