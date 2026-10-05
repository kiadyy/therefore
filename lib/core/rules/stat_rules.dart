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

/// Formate une durée de travail pour l'affichage : « 8 h 05 ».
String formatDureeTravail(Duration duree) {
  final heures = duree.inHours;
  final minutes = duree.inMinutes.remainder(60);
  return '$heures h ${minutes.toString().padLeft(2, '0')}';
}

/// Premier prénom, avec une majuscule à chaque partie :
/// « JEAN-MARC PAUL » -> « Jean-Marc ».
String prenomUsuel(String prenom) {
  final premier = prenom.trim().split(RegExp(r'\s+')).first;
  if (premier.isEmpty) return '';
  return premier
      .split('-')
      .map((p) =>
          p.isEmpty ? p : p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join('-');
}

/// Initiales pour l'avatar : première lettre du prénom et du nom.
String initiales(String prenom, String nom) {
  final p = prenom.trim();
  final n = nom.trim();
  return ((p.isNotEmpty ? p[0] : '') + (n.isNotEmpty ? n[0] : ''))
      .toUpperCase();
}

/// Heures avec 2 décimales et virgule française : « 150,66 h ».
String formatHeures(double heures) =>
    '${heures.toStringAsFixed(2).replaceAll('.', ',')} h';

/// Accord du mot « retard » : « 0 retard », « 1 retard », « 2 retards ».
String libelleRetards(int nombre) =>
    nombre <= 1 ? '$nombre retard' : '$nombre retards';

/// Rang en français : « 1er », « 2e », « 7e ».
String libelleRang(int rang) => rang == 1 ? '1er' : '${rang}e';

/// Accord simple au pluriel : « 1 complet », « 3 complets », « 0 absent ».
String accord(int nombre, String mot) =>
    nombre <= 1 ? '$nombre $mot' : '$nombre ${mot}s';

/// Durée courte pour le graphique : « 8h05 ».
String formatDureeCourt(Duration duree) {
  final minutes = duree.inMinutes.remainder(60);
  return '${duree.inHours}h${minutes.toString().padLeft(2, '0')}';
}

/// Position d'une heure sur la frise de la journée, qui va de 7 h à 19 h :
/// 0 = 7 h, 1 = 19 h. Les heures en dehors sont ramenées aux bords.
double fractionFrise(DateTime heure) {
  const debut = 7 * 60;
  const amplitude = 12 * 60;
  final minutes = heure.hour * 60 + heure.minute;
  return ((minutes - debut) / amplitude).clamp(0.0, 1.0);
}
