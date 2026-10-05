import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:therefore_pointage/features/auth/presentation/login_page.dart';

/// Écran de test assez haut pour que tout le formulaire soit visible
/// (sinon le bouton peut se trouver hors de l'écran et ne pas recevoir le tap).
void _grandEcran(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets("L'écran de connexion affiche le titre, les champs et le bouton",
      (WidgetTester tester) async {
    _grandEcran(tester);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('Authentification'), findsOneWidget);
    expect(find.text('Identifiant AD'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets(
      "Le bouton de connexion est bloqué tant que les champs sont vides",
      (WidgetTester tester) async {
    _grandEcran(tester);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    // On tape le bouton sans rien saisir : la validation doit refuser
    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(find.text('Champ requis'), findsWidgets);
  });

  testWidgets("La touche Entrée du mot de passe lance la connexion",
      (WidgetTester tester) async {
    _grandEcran(tester);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    // Champs vides + Entrée sur le mot de passe : la validation se déclenche
    await tester.tap(find.byType(TextFormField).last);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Champ requis'), findsWidgets);
  });

  testWidgets("L'icône œil affiche puis masque le mot de passe",
      (WidgetTester tester) async {
    _grandEcran(tester);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Afficher le mot de passe'), findsOneWidget);
    await tester.tap(find.byTooltip('Afficher le mot de passe'));
    await tester.pump();
    expect(find.byTooltip('Masquer le mot de passe'), findsOneWidget);
  });
}
