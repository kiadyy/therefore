import 'package:flutter_test/flutter_test.dart';
import 'package:therefore_pointage/core/rules/stat_rules.dart';

void main() {
  group('prenomUsuel', () {
    test('garde le premier prénom, avec une majuscule', () {
      expect(prenomUsuel('KIADY VALENTINO'), 'Kiady');
    });
    test('prénom composé : majuscule à chaque partie', () {
      expect(prenomUsuel('JEAN-MARC PAUL'), 'Jean-Marc');
    });
    test('prénom vide : chaîne vide', () {
      expect(prenomUsuel('  '), '');
    });
  });

  test('initiales : première lettre du prénom et du nom', () {
    expect(initiales('Kiady Valentino', 'RANDRIANARIMANANA'), 'KR');
    expect(initiales('', ''), '');
  });

  test('formatHeures : virgule française et unité', () {
    expect(formatHeures(150.66), '150,66 h');
    expect(formatHeures(8), '8,00 h');
  });

  test('libelleRetards : accord au singulier et au pluriel', () {
    expect(libelleRetards(0), '0 retard');
    expect(libelleRetards(1), '1 retard');
    expect(libelleRetards(2), '2 retards');
  });

  test('libelleRang : 1er puis 2e, 3e...', () {
    expect(libelleRang(1), '1er');
    expect(libelleRang(7), '7e');
  });
}
