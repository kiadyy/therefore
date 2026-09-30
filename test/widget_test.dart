import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:therefore_pointage/features/auth/presentation/login_page.dart';

void main() {
  testWidgets("L'écran de connexion affiche le titre et le bouton",
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('Authentification'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.byType(TextFormField),
        findsNWidgets(2)); // identifiant + mot de passe
  });

  testWidgets(
      "Le bouton de connexion est bloqué tant que les champs sont vides",
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    // On tape le bouton sans rien saisir : la validation doit refuser
    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(find.text('Champ requis'), findsWidgets);
  });
}
