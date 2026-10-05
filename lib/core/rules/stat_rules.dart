import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Règles de couleur et de libellé pour les indicateurs du tableau de bord.
/// Extraites de l'interface pour pouvoir être testées sans lancer l'application.

// Vert si peu de retards, orange à partir de 13, rouge à partir de 16
Color classementColor(int nbRetards) {
  if (nbRetards <= 12) return AppColors.success;
  if (nbRetards <= 15) return const Color(0xFFF09517);
  return Colors.red;
}

// Vert si retard moyen < 30min, orange entre 30min et 2h, rouge au-delà de 2h
Color dureeRetardColor(double minutes) {
  if (minutes > 120) return Colors.red;
  if (minutes >= 30) return const Color(0xFFF09517);
  return AppColors.success;
}

// Rouge si moyenne de travail <= 4h, orange entre 4h et 7h, vert au-delà de 7h
Color dureeTravailColor(double heures) {
  if (heures <= 4) return Colors.red;
  if (heures <= 7) return const Color(0xFFF09517);
  return AppColors.success;
}

// Rouge = Faible, sinon Moyenne (même au vert, comme demandé par l'entreprise)
String dureeRetardLabel(double minutes) {
  if (minutes > 120) return 'Faible';
  return 'Moyenne';
}

// Rouge = Faible, jaune = Moyenne, vert = Élevé
String dureeTravailLabel(double heures) {
  if (heures <= 4) return 'Faible';
  if (heures <= 7) return 'Moyenne';
  return 'Élevé';
}

/// Convertit une durée au format "HH:mm:ss" (renvoyée par l'API) en minutes.
/// Renvoie 0 si le format est invalide, plutôt que de lever une exception.
double hmsToMinutes(String value) {
  final parts = value.split(':');
  if (parts.length != 3) return 0;
  final heures = double.tryParse(parts[0]) ?? 0;
  final minutes = double.tryParse(parts[1]) ?? 0;
  final secondes = double.tryParse(parts[2]) ?? 0;
  return heures * 60 + minutes + secondes / 60;
}
