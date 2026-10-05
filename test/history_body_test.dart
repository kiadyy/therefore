import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:therefore_pointage/data/models/pointage_models.dart';
import 'package:therefore_pointage/data/network/network_exceptions.dart';
import 'package:therefore_pointage/data/repositories/pointage_repository_provider.dart';
import 'package:therefore_pointage/data/session/session_expired_exception.dart';
import 'package:therefore_pointage/features/history/presentation/history_body.dart';

import 'helpers/fake_pointage_repository.dart';

Widget _ecran() => const MaterialApp(home: Scaffold(body: HistoryBody()));

/// Agrandit l'écran de test pour que les 7 cartes soient toutes affichées
/// (une liste n'affiche que les éléments visibles).
void _agrandirEcran(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Les 7 jours affichés par défaut : aujourd'hui et les 6 jours précédents.
List<DateTime> _septDerniersJours() {
  final now = DateTime.now();
  return List.generate(7, (i) {
    final d = now.subtract(Duration(days: i));
    return DateTime(d.year, d.month, d.day);
  });
}

bool _estWeekend(DateTime d) =>
    d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

DateTime _heure(DateTime jour, int h, int m) =>
    DateTime(jour.year, jour.month, jour.day, h, m);

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'jeton-de-test'});
  });

  testWidgets('statuts des journées et horaires pointés', (tester) async {
    _agrandirEcran(tester);

    // Sur 7 jours consécutifs, il y a toujours exactement 1 samedi et 1 dimanche
    final ouvres = _septDerniersJours().where((d) => !_estWeekend(d)).toList();
    final jourComplet = ouvres[0];
    final jourIncomplet = ouvres[1];

    pointageRepository = FakePointageRepository(evenements: [
      PointageEvent(datePointage: _heure(jourComplet, 8, 0)),
      PointageEvent(datePointage: _heure(jourComplet, 12, 0)),
      PointageEvent(datePointage: _heure(jourComplet, 13, 0)),
      PointageEvent(datePointage: _heure(jourComplet, 17, 5)),
      PointageEvent(datePointage: _heure(jourIncomplet, 8, 30)),
    ]);

    await tester.pumpWidget(_ecran());
    await tester.pumpAndSettle();

    expect(find.text('Complet'), findsOneWidget); // 4 pointages
    expect(find.text('Incomplet'), findsOneWidget); // 1 pointage
    expect(find.text('Weekend'), findsNWidgets(2));
    expect(find.text('Absent'), findsNWidgets(3)); // 5 jours ouvrés - 2

    for (final h in ['8:00', '12:00', '13:00', '17:05', '8:30']) {
      expect(find.text(h), findsOneWidget);
    }
  });

  testWidgets(
      'serveur indisponible : message sans faux « Absent », puis « Réessayer »',
      (tester) async {
    _agrandirEcran(tester);
    final fake =
        FakePointageRepository(erreur: const ServerUnavailableException());
    pointageRepository = fake;

    await tester.pumpWidget(_ecran());
    await tester.pumpAndSettle();

    expect(find.textContaining('Le serveur ne répond pas'), findsOneWidget);
    expect(find.text('Absent'), findsNothing);

    fake.erreur = null; // le serveur répond de nouveau
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Le serveur ne répond pas'), findsNothing);
    expect(find.text('Weekend'), findsNWidgets(2));
  });

  testWidgets('jeton refusé (401) : retour à l\'écran de connexion',
      (tester) async {
    pointageRepository =
        FakePointageRepository(erreur: const SessionExpiredException());

    await tester.pumpWidget(_ecran());
    await tester.pumpAndSettle();

    expect(find.text('Authentification'), findsOneWidget);
  });
}