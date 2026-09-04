import '../models/pointage_models.dart';

/// Contrat que l'app utilise partout. Peu importe la source réelle des données
/// (mock aujourd'hui, API de l'entreprise demain), le reste du code ne change pas.
abstract class PointageRepository {
  Future<PointageJour> getPointageDuJour(String matricule,
      {required int annee, required int mois});
  Future<TotalHeures> getTotalHeures(String matricule,
      {required int annee, required int mois});
  Future<EmployeStats> getStatsEmploye(String matricule,
      {required int annee, required int mois});
  Future<List<PointageEvent>> getHistorique(
    String matricule, {
    required DateTime debut,
    required DateTime fin,
  });
}

/// Implémentation FACTICE pour développer et tester l'app en attendant l'accès
/// réel à l'API de l'entreprise. À supprimer/remplacer par ApiPointageRepository
/// une fois leur API disponible (voir TODO en bas du fichier).
class MockPointageRepository implements PointageRepository {
  @override
  Future<PointageJour> getPointageDuJour(
    String matricule, {
    required int annee,
    required int mois,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return PointageJour(
        entree: '08:10:14', sortie: '17:32:27', annee: annee, mois: mois);
  }

  @override
  Future<TotalHeures> getTotalHeures(
    String matricule, {
    required int annee,
    required int mois,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return TotalHeures(totalHeures: 30.66, annee: annee);
  }

  @override
  Future<EmployeStats> getStatsEmploye(
    String matricule, {
    required int annee,
    required int mois,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return EmployeStats.fromJson(
      {
        'MATRICULE': matricule,
        'NOM': 'RAKOTO',
        'PRENOM': 'Jean',
        'SOCIETE': 'INVISO GROUP',
        'duree_moyenne_retard': 150.0,
        'duree_moyenne_travail': 3.07,
        'nb_retards': 17,
      },
      index: 7,
      length: 10,
    );
  }

  @override
  Future<List<PointageEvent>> getHistorique(
    String matricule, {
    required DateTime debut,
    required DateTime fin,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final events = <PointageEvent>[];
    for (var d = debut; !d.isAfter(fin); d = d.add(const Duration(days: 1))) {
      if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday)
        continue;
      events.add(
          PointageEvent(datePointage: DateTime(d.year, d.month, d.day, 8, 4)));
      // Simule un oubli de pointage de sortie le 2 du mois (pour tester "Incomplet")
      if (d.day != 2) {
        events.add(PointageEvent(
            datePointage: DateTime(d.year, d.month, d.day, 17, 8)));
      }
    }
    return events;
  }
}

// ⚠️ ÉTAPE FINALE (à faire une fois l'API de l'entreprise disponible) :
//
// class ApiPointageRepository implements PointageRepository {
//   final Dio _dio; // ou http.Client
//   ApiPointageRepository(this._dio);
//
//   @override
//   Future<PointageJour> getPointageDuJour(String matricule, {required int annee, required int mois}) async {
//     final res = await _dio.get('/pointage/jour', queryParameters: {
//       'matricule': matricule, 'annee': annee, 'mois': mois,
//     });
//     return PointageJour.fromJson(res.data);
//   }
//   // ... etc pour les autres méthodes, même logique.
// }
//
// Puis dans pointage_repository_provider.dart, remplacer :
//   PointageRepository pointageRepository = MockPointageRepository();
// par :
//   PointageRepository pointageRepository = ApiPointageRepository(dio);
// Aucun autre fichier de l'app n'a besoin de changer.
