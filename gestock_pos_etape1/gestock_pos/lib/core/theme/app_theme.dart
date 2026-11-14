// Thème global de l'application (Material 3).
// Une seule couleur "graine" suffit : Flutter génère toute la palette
// (primaire, secondaire, surfaces…) de façon harmonieuse et accessible.

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  /// Bleu professionnel, lisible au soleil sur un comptoir.
  static const Color _graine = Color(0xFF1E5AA8);

  static ThemeData get clair => _construire(Brightness.light);
  static ThemeData get sombre => _construire(Brightness.dark);

  static ThemeData _construire(Brightness luminosite) {
    final scheme = ColorScheme.fromSeed(seedColor: _graine, brightness: luminosite);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(centerTitle: false),
      // Champs de saisie arrondis, cohérents dans toute l'app
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
    );
  }
}
