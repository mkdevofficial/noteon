import 'package:flutter/material.dart';

class AppConstants {
  /// HARD CONSTRAINT: Free Firebase plan (Spark).
  /// Image/file attachments require Cloud Storage (Blaze plan), so they sit
  /// behind this feature flag. Disabled by default.
  static const bool kAttachmentsEnabled = false;

  /// Debounce time for saving note edits to Cloud Firestore (800 ms).
  static const Duration kSaveDebounce = Duration(milliseconds: 800);

  /// Maximum version history snapshots stored per note in Firestore subcollection.
  static const int kMaxVersionHistory = 10;

  /// Batch write chunk size (staying well under the 500 limit).
  static const int kBatchSize = 400;

  /// Trash auto-purge retention duration.
  static const Duration kTrashRetentionDuration = Duration(days: 30);

  /// Note Color Palette (12 beautiful, accessible pastel/neutral colors).
  static const List<Color> noteColorsLight = [
    Color(0xFFFFFFFF), // Default white
    Color(0xFFFFF0F5), // Lavender blush
    Color(0xFFFFF8E7), // Warm amber / cream
    Color(0xFFF0FFF0), // Honeydew / mint
    Color(0xFFF0F8FF), // Alice blue / sky
    Color(0xFFF5F5DC), // Beige
    Color(0xFFFFF5EE), // Seashell / coral tint
    Color(0xFFE6E6FA), // Lavender
    Color(0xFFE0FFFF), // Light cyan
    Color(0xFFFDF5E6), // Old lace / peach
    Color(0xFFF0FFF4), // Pale green
    Color(0xFFF5F5F5), // Light grey
  ];

  static const List<Color> noteColorsDark = [
    Color(0xFF1E1E1E), // Dark charcoal (default)
    Color(0xFF2C222B), // Deep berry
    Color(0xFF332A1E), // Deep amber
    Color(0xFF1E2D24), // Deep emerald
    Color(0xFF1C2A38), // Deep sapphire
    Color(0xFF2B2620), // Dark bronze
    Color(0xFF352422), // Deep coral
    Color(0xFF262035), // Deep violet
    Color(0xFF1A2E33), // Deep teal
    Color(0xFF33251E), // Deep rust
    Color(0xFF1C3026), // Deep olive
    Color(0xFF262626), // Neutral grey
  ];

  /// Accent colors available for personalization.
  static const List<Color> accentColors = [
    Color(0xFF4A6572), // Slate Teal (default)
    Color(0xFF2A9D8F), // Persian Green
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Material Blue
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFFE76F51), // Coral
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFFFF9800), // Orange
  ];
}
