import 'package:flutter/material.dart';

/// Centralised colours, gradients and shadows that give the app its
/// modern, animated, "floating paper on a desk" 3D feel.
class AppTheme {
  static const Color seed = Color(0xFF4F46E5);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF1F2F8),
      cardTheme: CardThemeData(
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        border: InputBorder.none,
      ),
    );
  }

  /// The light-grey "desk" behind the white pages, like Microsoft Word.
  static const LinearGradient deskGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEDEEF2), Color(0xFFE2E4EA), Color(0xFFD7D9E0)],
  );

  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
  );

  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  /// Subtle shadow that makes the white page sit above the grey desk (Word).
  static List<BoxShadow> pageShadows = [
    BoxShadow(
      color: Colors.black.withOpacity(0.22),
      blurRadius: 18,
      spreadRadius: -2,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static Color typeColor(int index) {
    const colors = [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
      Color(0xFFF59E0B),
      Color(0xFF0EA5E9),
      Color(0xFFEF4444),
      Color(0xFF22C55E),
    ];
    return colors[index % colors.length];
  }
}
