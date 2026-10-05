class PointageJour {
  final String? entree;
  final String? sortie;
  final int annee;
  final int mois;

  PointageJour(
      {this.entree, this.sortie, required this.annee, required this.mois});

  factory PointageJour.fromJson(Map<String, dynamic> json) => PointageJour(
        entree: json['entree'] as String?,
        sortie: json['sortie'] as String?,
        annee: json['annee'] as int,
        mois: json['mois'] as int,
      );
}

class TotalHeures {
  final double totalHeures;
  final int annee;

  TotalHeures({required this.totalHeures, required this.annee});

  factory TotalHeures.fromJson(Map<String, dynamic> json) => TotalHeures(
        totalHeures: (json['total_heures'] as num).toDouble(),
        annee: json['annee'] as int,
      );
}

class EmployeStats {
  final String matricule;
  final String nom;
  final String prenom;
  final String societe;
  final String dureeMoyenneRetard;
  final String dureeMoyenneTravail;
  final int nbRetards;
  final int classementIndex;
  final int classementTotal;

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
        dureeMoyenneRetard: emp['duree_moyenne_retard'].toString(),
        dureeMoyenneTravail: emp['duree_moyenne_travail'].toString(),
        nbRetards: (emp['nb_retards'] as num).toInt(),
        classementIndex: index,
        classementTotal: length,
      );
}

class PointageEvent {
  final DateTime datePointage;
  final String? refDemande;

  PointageEvent({required this.datePointage, this.refDemande});

  factory PointageEvent.fromJson(Map<String, dynamic> json) => PointageEvent(
        datePointage: DateTime.parse(json['date_pointage'] as String),
        refDemande: json['ref_demande'] as String?,
      );
}

class JourPointage {
  final DateTime date;
  final List<DateTime> pointages;
  final bool estWeekend;

  JourPointage({
    required this.date,
    required this.pointages,
    required this.estWeekend,
  });

  String get statut {
    if (estWeekend) return 'weekend';
    if (pointages.isEmpty) return 'absent';
    if (pointages.length.isOdd) return 'incomplet';
    return 'complet';
  }

  /// Temps travaillé dans la journée : somme des intervalles entre les
  /// pointages pris deux à deux (arrivée -> départ, ou arrivée -> pause
  /// puis retour -> départ). La pause déjeuner n'est donc pas comptée.
  /// Renvoie null si le nombre de pointages est nul ou impair : la durée
  /// ne peut alors pas être calculée de façon fiable.
  Duration? get dureeTravaillee {
    if (pointages.isEmpty || pointages.length.isOdd) return null;
    final tries = [...pointages]..sort();
    var total = Duration.zero;
    for (var i = 0; i < tries.length; i += 2) {
      total += tries[i + 1].difference(tries[i]);
    }
    return total;
  }
}
