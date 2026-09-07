import '../models/pointage_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import "../service/session_manager.dart";

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
    final token = await SessionManager.getToken();

    final url = Uri.parse(
      'http://10.114.0.16:8000/user/heure-arrivee'
      '?mois=$mois&annee=$annee',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return PointageJour(
        entree: data['entree'],
        sortie: data['sortie'],
        annee: data['annee'],
        mois: data['mois'],
      );
    } else if (response.statusCode == 401) {
      // Token expiré ou invalide
      throw Exception('Session expirée, veuillez vous reconnecter');
    } else {
      throw Exception(
        'Erreur lors de la récupération du pointage (${response.statusCode})',
      );
    }
    // await Future.delayed(const Duration(milliseconds: 400));
    // return PointageJour(
    //     entree: '08:10:14', sortie: '17:32:27', annee: annee, mois: mois);
  }

  @override
  Future<TotalHeures> getTotalHeures(
    String matricule, {
    required int annee,
    required int mois,
  }) async {
    final token = await SessionManager.getToken();

    final url = Uri.parse(
      'http://10.114.0.16:8000/user/heure-realise'
      '?mois=$mois&annee=$annee',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return TotalHeures(
          totalHeures: data['total_heures'], annee: data['annee']);
    } else if (response.statusCode == 401) {
      // Token expiré ou invalide
      throw Exception('Session expirée, veuillez vous reconnecter');
    } else {
      throw Exception(
        'Erreur lors de la récupération du pointage (${response.statusCode})',
      );
    }
    // await Future.delayed(const Duration(milliseconds: 400));
    // return TotalHeures(totalHeures: 30.66, annee: annee);
  }

  @override
  Future<EmployeStats> getStatsEmploye(
    String matricule, {
    required int annee,
    required int mois,
  }) async {
    final token = await SessionManager.getToken();

    final url = Uri.parse(
      'http://10.114.0.16:8000/user/my-retards'
      '?mois=$mois&annee=$annee',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return EmployeStats.fromJson(
        {
          'MATRICULE': data['emp']['MATRICULE'],
          'NOM': data['emp']['NOM'],
          'PRENOM': data['emp']['PRENOM'],
          'SOCIETE': data['emp']['SOCIETE'],
          'duree_moyenne_retard': data['emp']['duree_moyenne_retard'],
          'duree_moyenne_travail': data['emp']['duree_moyenne_travail'],
          'nb_retards': data['emp']['nb_retards'],
        },
        index: data['index'],
        length: data['length'],
      );
    } else if (response.statusCode == 401) {
      // Token expiré ou invalide
      throw Exception('Session expirée, veuillez vous reconnecter');
    } else {
      throw Exception(
        'Erreur lors de la récupération du pointage (${response.statusCode})',
      );
    }
    // await Future.delayed(const Duration(milliseconds: 400));
    // return EmployeStats.fromJson(
    //   {
    //     'MATRICULE': matricule,
    //     'NOM': 'RAKOTO',
    //     'PRENOM': 'Jean',
    //     'SOCIETE': 'INVISO GROUP',
    //     'duree_moyenne_retard': 150.0,
    //     'duree_moyenne_travail': 3.07,
    //     'nb_retards': 17,
    //   },
    //   index: 7,
    //   length: 10,
    // );
  }

  @override
  Future<List<PointageEvent>> getHistorique(
    String matricule, {
    required DateTime debut,
    required DateTime fin,
  }) async {
    final events = <PointageEvent>[];
    final token = await SessionManager.getToken();
    final date_debut = DateFormat('yyyy-MM-dd').format(debut);
    final date_fin = DateFormat('yyyy-MM-dd').format(fin);
    final url = Uri.parse(
      'http://10.114.0.16:8000/presence/historique'
      '?date_debut=$date_debut&date_fin=$date_fin',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      for (var pointage in data) {
        DateTime formatted =
            DateFormat('yyyy-MM-dd HH:mm:ss').parse(pointage['date_pointage']);
        events.add(PointageEvent(datePointage: formatted));
      }
      // for (var d = debut; !d.isAfter(fin); d = d.add(const Duration(days: 1))) {
      // if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday)
      //   continue;

      // // Simule un oubli de pointage de sortie le 2 du mois (pour tester "Incomplet")
      // if (d.day != 2) {
      //   events.add(PointageEvent(
      //       datePointage: DateTime(d.year, d.month, d.day, 17, 8)));
      // }
      // }
    }
    await Future.delayed(const Duration(milliseconds: 400));

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
