import 'package:flutter/material.dart';

enum AppThemeMode { system, light, dark, amoled }

class AppTheme {
  static ThemeData lightTheme(Color primaryColor, {double fontScale = 1.0}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: const Color(0xFFF8F9FA),
      cardBg: Colors.white,
      fontScale: fontScale,
    );
  }

  static ThemeData darkTheme(Color primaryColor, {double fontScale = 1.0}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: const Color(0xFF121212),
      cardBg: const Color(0xFF1E1E1E),
      fontScale: fontScale,
    );
  }

  static ThemeData amoledTheme(Color primaryColor, {double fontScale = 1.0}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(surface: Colors.black, onSurface: Colors.white);

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: Colors.black,
      cardBg: const Color(0xFF101010),
      fontScale: fontScale,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color cardBg,
    required double fontScale,
  }) {
    final baseTextTheme = Typography.material2021().englishLike;
    final scaledTextTheme = baseTextTheme.apply(
      fontSizeFactor: fontScale,
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardBg,
      textTheme: scaledTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldBg,
        elevation: 2,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: cardBg,
      ),
    );
  }
}
