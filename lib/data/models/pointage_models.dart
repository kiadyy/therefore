/// Pointage du jour : {entree: "08:10:14", sortie: "17:32:27", annee: 2026, mois: 8}
class PointageJour {
  final String? entree;
  final String? sortie;
  final int annee;
  final int mois;

  PointageJour({this.entree, this.sortie, required this.annee, required this.mois});

  factory PointageJour.fromJson(Map<String, dynamic> json) => PointageJour(
    entree: json['entree'] as String?,
    sortie: json['sortie'] as String?,
    annee: json['annee'] as int,
    mois: json['mois'] as int,
  );
}

/// Total d'heures réalisées : {total_heures: 150.66, annee: 2026}
class TotalHeures {
  final double totalHeures;
  final int annee;

  TotalHeures({required this.totalHeures, required this.annee});

  factory TotalHeures.fromJson(Map<String, dynamic> json) => TotalHeures(
    totalHeures: (json['total_heures'] as num).toDouble(),
    annee: json['annee'] as int,
  );
}

/// Infos employé + stats : {MATRICULE, NOM, SOCIETE, PRENOM, duree_moyenne_retard,
/// duree_moyenne_travail, nb_retards} + classement fourni séparément (index/length)
class EmployeStats {
  final String matricule;
  final String nom;
  final String prenom;
  final String societe;
  final double dureeMoyenneRetard; // en minutes
  final double dureeMoyenneTravail; // en heures
  final int nbRetards;
  final int classementIndex; // ex: 7
  final int classementTotal; // ex: 10

  EmployeStats({
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.societe,
    required this.dureeMoyenneRetard,
    required this.dureeMoyenneTravail,
    required this.nbRetards,
    required this.classementIndex,
    required this.classementTotal,
  });

  factory EmployeStats.fromJson(
      Map<String, dynamic> emp, {
        required int index,
        required int length,
      }) =>
      EmployeStats(
        matricule: emp['MATRICULE'].toString(),
        nom: emp['NOM'] as String,
        prenom: emp['PRENOM'] as String,
        societe: emp['SOCIETE'] as String,
        dureeMoyenneRetard: (emp['duree_moyenne_retard'] as num).toDouble(),
        dureeMoyenneTravail: (emp['duree_moyenne_travail'] as num).toDouble(),
        nbRetards: (emp['nb_retards'] as num).toInt(),
        classementIndex: index,
        classementTotal: length,
      );
}

/// Un événement de pointage brut : [{date_pointage: "2026-07-30 17:18:00", ref_demande: null}]
class PointageEvent {
  final DateTime datePointage;
  final String? refDemande;

  PointageEvent({required this.datePointage, this.refDemande});

  factory PointageEvent.fromJson(Map<String, dynamic> json) => PointageEvent(
    datePointage: DateTime.parse(json['date_pointage'] as String),
    refDemande: json['ref_demande'] as String?,
  );
}

/// Regroupement des événements par jour, pour affichage dans l'historique
class JourPointage {
  final DateTime date;
  final DateTime? entree;
  final DateTime? sortie;
  final bool estWeekend;

  JourPointage({required this.date, this.entree, this.sortie, required this.estWeekend});

  String get statut {
    if (estWeekend) return 'weekend';
    if (entree != null && sortie != null) return 'complet';
    if (entree != null) return 'incomplet';
    return 'absent';
  }
}