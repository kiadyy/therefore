import 'package:flutter/material.dart';

/// Couleurs officielles Therefore.
class AppColors {
  AppColors._();

  static const Color primaryGreen = Color(0xFF138808);
  static const Color accentLime = Color(0xFFA6CE39);
  static const Color backgroundLight = Color(0xFFF4F4F4);
  static const Color fieldGrey = Color(0xFFD9DCE1);
  static const Color textDark = Color(0xFF3C3C3C);
  static const Color textGrey = Color(0xFF7A7A7A);
  static const Color success = Color(0xFF2E9E3D);
  static const Color warning = Color(0xFFE8A33D);
  static const Color cardBorder = Color(0xFFE3E3E3);
  static const Color white = Color(0xFFFFFFFF);

  // Statut "weekend" dans l'historique
  static const Color weekendBg = Color(0xFFEEE5F8);
  static const Color weekendBorder = Color(0xFF732FC0);

  // Statut "incomplet" dans l'historique
  static const Color incompletBg = Color(0xFFFFEBCF);
  static const Color incompletBorder = Color(0xFFF09517);

  // Barre de progression "Heure réalisée" selon le pourcentage
  static const Color progressLow = Color(0xFFE53935); // 0–30%
  static const Color progressMid = Color(0xFFFBC02D); // 31–60%
  static const Color progressHigh = Color(0xFF2E9E3D); // 61%+

  static Color progressColorFor(double value) {
    // value entre 0 et 1
    if (value <= 0.30) return progressLow;
    if (value <= 0.60) return progressMid;
    return progressHigh;
  }
}