import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Rayons et espacements communs à toute l'application.
class AppDimens {
  AppDimens._();

  static const double radiusCard = 24;
  static const double radiusButton = 26;
  static const double radiusIcon = 12;
  static const double paddingScreen = 16;
  static const double gap = 12;
}

/// Styles de texte de l'application (police Jost).
/// Une seule échelle, utilisée partout, pour une hiérarchie cohérente.
class AppText {
  AppText._();

  /// Titre d'en-tête (« Bonjour, Prénom », « Mon pointage »)
  static const TextStyle titre = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Grand chiffre d'une carte principale (« 150,66 h »)
  static const TextStyle chiffreFort = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.textDark,
  );

  /// Valeur d'une carte (« 08:10:14 »)
  static const TextStyle valeur = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  /// Libellé au-dessus d'une valeur (« Arrivée »)
  static const TextStyle libelle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textGrey,
  );

  /// Texte secondaire (« sur 184 h ouvrables »)
  static const TextStyle secondaire = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );

  /// Texte d'une pastille de statut (« Complet », « Moyenne »)
  static const TextStyle pastille = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );
}

/// Thème global de l'application.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Jost',
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          surface: AppColors.white,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primaryGreen,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      );
}
