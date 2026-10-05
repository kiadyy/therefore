import 'package:flutter_test/flutter_test.dart';
import 'package:therefore_pointage/core/rules/stat_rules.dart';

DateTime h(int heure, int minute) => DateTime(2026, 9, 1, heure, minute);

void main() {
  test('accord : singulier jusqu\'à 1, pluriel au-delà', () {
    expect(accord(0, 'absent'), '0 absent');
    expect(accord(1, 'complet'), '1 complet');
    expect(accord(3, 'absent'), '3 absents');
  });

  test('formatDureeCourt : format compact pour le graphique', () {
    expect(formatDureeCourt(const Duration(hours: 8, minutes: 5)), '8h05');
    expect(formatDureeCourt(const Duration(hours: 9, minutes: 13)), '9h13');
  });

  test('fractionFrise : 7 h à gauche, 19 h à droite, bornée aux bords', () {
    expect(fractionFrise(h(7, 0)), 0.0);
    expect(fractionFrise(h(13, 0)), 0.5);
    expect(fractionFrise(h(19, 0)), 1.0);
    expect(fractionFrise(h(6, 0)), 0.0); // avant 7 h
    expect(fractionFrise(h(20, 30)), 1.0); // après 19 h
  });
}
