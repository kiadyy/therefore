import '../models/pointage_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import "../service/session_manager.dart";
import '../session/session_expired_exception.dart';
import 'dart:async';
import 'dart:io';
import '../network/network_exceptions.dart';

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
// À ajouter en haut de pointage_repository.dart :
// import 'dart:async';
// import 'dart:io';
// import '../network/network_exceptions.dart';

/// Enveloppe un appel réseau : convertit les erreurs bas niveau (pas de
/// connexion, délai dépassé, erreur serveur) en exceptions dédiées que
/// l'interface sait afficher clairement. Utilisation :
///
///   final response = await networkGuard(() => http.get(url, headers: ...));
///
Future<http.Response> networkGuard(
  Future<http.Response> Function() call, {
  Duration timeout = const Duration(seconds: 12),
}) async {
  try {
    final response = await call().timeout(timeout);
    if (response.statusCode >= 500) {
      throw ServerUnavailableException(statusCode: response.statusCode);
    }
    return response;
  } on SocketException {
    // Pas de réseau, ou serveur totalement injoignable (DNS, etc.)
    throw const NoConnectionException();
  } on TimeoutException {
    // Le serveur met trop de temps à répondre
    throw const ServerUnavailableException();
  }
  // Les autres erreurs (401, 404, erreurs de format JSON...) remontent
  // telles quelles, elles sont déjà gérées ailleurs (ex: SessionExpiredException).
}

class MockPointageRepository implements PointageRepository {
  @override
  Future<PointageJour> getPointageDuJour(
    String matricule, {
    required int annee,
    required int mois,
  }) async {
    final token = await SessionManager.getToken();

    final url = Uri.parse(
      'https://pointeuse-backend.inviso-group.mg/user/heure-arrivee'
      '?mois=$mois&annee=$annee',
    );
    final response = await networkGuard(() => http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ));

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
      throw const SessionExpiredException();
    } else {
      throw Exception(
        'Erreur lors de la récupération du pointage (${response.statusCode})',
      );
    }
  }

  @override
  Future<TotalHeures> getTotalHeures(
    String matricule, {
    required int annee,
    required int mois,
  }) async {
    final token = await SessionManager.getToken();

    final url = Uri.parse(
      'https://pointeuse-backend.inviso-group.mg/user/heure-realise'
      '?mois=$mois&annee=$annee',
    );
    final response = await networkGuard(() => http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return TotalHeures(
          totalHeures: data['total_heures'], annee: data['annee']);
    } else if (response.statusCode == 401) {
      // Token expiré ou invalide
      throw const SessionExpiredException();
    } else {
      throw Exception(
        'Erreur lors de la récupération du pointage (${response.statusCode})',
      );
    }
  }

  @override
  Future<EmployeStats> getStatsEmploye(
    String matricule, {
    required int annee,
    required int mois,
  }) async {
    final token = await SessionManager.getToken();

    final url = Uri.parse(
      'https://pointeuse-backend.inviso-group.mg/user/my-retards'
      '?mois=$mois&annee=$annee&order=asc',
    );
    final response = await networkGuard(() => http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ));
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
      throw const SessionExpiredException();
    } else {
      throw Exception(
        'Erreur lors de la récupération du pointage (${response.statusCode})',
      );
    }
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
      'https://pointeuse-backend.inviso-group.mg/presence/historique'
      '?date_debut=$date_debut&date_fin=$date_fin',
    );
    final response = await networkGuard(() => http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      for (var pointage in data) {
        DateTime formatted =
            DateFormat('yyyy-MM-dd HH:mm:ss').parse(pointage['date_pointage']);
        events.add(PointageEvent(datePointage: formatted));
      }
    }
    await Future.delayed(const Duration(milliseconds: 400));

    return events;
  }
}
