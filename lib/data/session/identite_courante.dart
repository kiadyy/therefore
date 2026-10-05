import 'package:flutter/foundation.dart';

import '../models/pointage_models.dart';

/// Identité de l'employé connecté (prénom, nom, société, matricule),
/// gardée UNIQUEMENT en mémoire vive le temps de l'utilisation de l'app.
/// Rien n'est écrit sur le téléphone : elle disparaît à la fermeture de
/// l'application et est effacée à la déconnexion.
class IdentiteCourante {
  IdentiteCourante._();

  static final ValueNotifier<EmployeStats?> employe =
      ValueNotifier<EmployeStats?>(null);

  static void effacer() => employe.value = null;
}
