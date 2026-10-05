import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:therefore_pointage/data/network/network_exceptions.dart';
import 'package:therefore_pointage/data/repositories/pointage_repository_provider.dart';
import 'package:therefore_pointage/data/service/session_manager.dart';
import 'package:therefore_pointage/data/session/identite_courante.dart';
import 'package:therefore_pointage/data/session/session_expired_exception.dart';
import 'package:therefore_pointage/features/dashboard/presentation/dashboard_body.dart';
import 'package:therefore_pointage/features/shared/skeleton.dart';

import 'helpers/fake_pointage_repository.dart';

Widget _ecran() => const MaterialApp(home: Scaffold(body: DashboardBody()));

void main() {
  setUp(() {
    // Stockage sécurisé simulé : un jeton est présent, comme après une connexion
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'jeton-de-test',
      'username': 'identifiant.test',
    });
    // L'identité en mémoire ne doit pas passer d'un test à l'autre
    IdentiteCourante.effacer();
  });

  testWidgets('affiche les indicateurs du mois avec les données reçues',
      (tester) async {
    pointageRepository = FakePointageRepository();

    await tester.pumpWidget(_ecran());
    await tester.pumpAndSettle();

    // En-tête personnalisé
    expect(find.text('Bonjour, Employe'), findsOneWidget);
    expect(find.text('SOCIETE TEST'), findsOneWidget);
    expect(find.text('ET'), findsOneWidget); // initiales de l'avatar

    // Indicateurs
    expect(find.text('150,66 h'), findsOneWidget); // heures réalisées
    expect(find.text('82 %'), findsOneWidget); // 150,66 / 184
    expect(find.text('08:10:14'), findsOneWidget); // arrivée
    expect(find.text('17:32:27'), findsOneWidget); // départ
    expect(find.text('2 retards'), findsOneWidget);
    expect(find.text('7e sur 10'), findsOneWidget);
    expect(find.text('01:42:14'), findsOneWidget); // retard moyen
    expect(find.text('Moyenne'), findsOneWidget); // entre 30 min et 2 h
    expect(find.text('08:04:11'), findsOneWidget); // travail moyen
    expect(find.text('Élevé'), findsOneWidget); // plus de 7 h
  });

  testWidgets(
      'sans connexion : message clair, puis « Réessayer » recharge les données',
      (tester) async {
    final fake = FakePointageRepository(erreur: const NoConnectionException());
    pointageRepository = fake;

    await tester.pumpWidget(_ecran());
    await tester.pumpAndSettle();

    expect(find.textContaining('Pas de connexion internet'), findsOneWidget);
    expect(find.text('08:10:14'), findsNothing);

    fake.erreur = null; // la connexion revient
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pas de connexion internet'), findsNothing);
    expect(find.text('08:10:14'), findsOneWidget);
  });

  testWidgets('jeton refusé (401) : session effacée et retour à la connexion',
      (tester) async {
    pointageRepository =
        FakePointageRepository(erreur: const SessionExpiredException());

    await tester.pumpWidget(_ecran());
    await tester.pumpAndSettle();

    expect(find.text('Authentification'), findsOneWidget);
    expect(await SessionManager.getToken(), isNull);
  });

  testWidgets('menu profil : identité, matricule et identifiant AD',
      (tester) async {
    pointageRepository = FakePointageRepository();

    await tester.pumpWidget(_ecran());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menu profil'));
    await tester.pumpAndSettle();

    expect(find.text('Employe TEST'), findsOneWidget);
    expect(find.text('SOCIETE TEST'), findsWidgets); // en-tête + panneau
    expect(find.text('0000'), findsOneWidget); // matricule
    expect(find.text('identifiant.test'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);
  });

  testWidgets('menu profil sans réseau : seul l\'identifiant AD est affiché',
      (tester) async {
    pointageRepository =
        FakePointageRepository(erreur: const NoConnectionException());

    await tester.pumpWidget(_ecran());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menu profil'));
    await tester.pumpAndSettle();

    expect(find.text('SOCIETE TEST'), findsNothing);
    expect(find.text('Matricule'), findsNothing);
    expect(find.text('identifiant.test'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);
  });

  testWidgets('pendant le chargement : squelette à la place du rond qui tourne',
      (tester) async {
    pointageRepository = FakePointageRepository();

    await tester.pumpWidget(_ecran());
    // Première image : les données ne sont pas encore arrivées
    expect(find.byType(DashboardSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(DashboardSkeleton), findsNothing);
    expect(find.text('08:10:14'), findsOneWidget);
  });
}
