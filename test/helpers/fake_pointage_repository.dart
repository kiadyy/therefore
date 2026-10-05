import 'package:therefore_pointage/data/models/pointage_models.dart';
import 'package:therefore_pointage/data/repositories/pointage_repository.dart';

/// Faux repository utilisé uniquement dans les tests.
/// Il renvoie des données fixes (valeurs fictives, au format de l'API),
/// ou lève l'erreur demandée, sans aucun appel réseau.
class FakePointageRepository implements PointageRepository {
  /// Si non nul, toutes les méthodes lèvent cette erreur.
  /// Peut être remis à null en cours de test pour simuler un retour à la normale.
  Object? erreur;

  /// Événements renvoyés par getHistorique.
  final List<PointageEvent> evenements;

  FakePointageRepository({this.erreur, this.evenements = const []});

  void _leverErreurSiDemandee() {
    final e = erreur;
    if (e != null) throw e;
  }

  @override
  Future<PointageJour> getPointageDuJour(
    String matricule, {
    required int annee,
    required int mois,
  }) async {
    _leverErreurSiDemandee();
    return PointageJour(
      entree: '08:10:14',
      sortie: '17:32:27',
      annee: annee,
      mois: mois,
    );
  }

  @override
  Future<TotalHeures> getTotalHeures(
    String matricule, {
    required int annee,
    required int mois,
  }) async {
    _leverErreurSiDemandee();
    return TotalHeures(totalHeures: 150.66, annee: annee);
  }

  @override
  Future<EmployeStats> getStatsEmploye(
    String matricule, {
    required int annee,
    required int mois,
  }) async {
    _leverErreurSiDemandee();
    return EmployeStats(
      matricule: '0000',
      nom: 'TEST',
      prenom: 'Employe',
      societe: 'SOCIETE TEST',
      dureeMoyenneRetard: '01:42:14',
      dureeMoyenneTravail: '08:04:11',
      nbRetards: 2,
      classementIndex: 7,
      classementTotal: 10,
    );
  }

  @override
  Future<List<PointageEvent>> getHistorique(
    String matricule, {
    required DateTime debut,
    required DateTime fin,
  }) async {
    _leverErreurSiDemandee();
    return evenements;
  }
}