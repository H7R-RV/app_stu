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

  /// The dark "desk" behind the floating white pages.
  static const LinearGradient deskGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF312E81), Color(0xFF1E1B4B), Color(0xFF0B1020)],
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

  /// Layered shadows that make a page look like it floats above the desk.
  static List<BoxShadow> pageShadows = [
    BoxShadow(
      color: Colors.black.withOpacity(0.45),
      blurRadius: 40,
      spreadRadius: -6,
      offset: const Offset(0, 22),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 10,
      offset: const Offset(0, 5),
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
