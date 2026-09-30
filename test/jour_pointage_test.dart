import 'package:flutter_test/flutter_test.dart';
import 'package:therefore_pointage/data/models/pointage_models.dart';

DateTime h(int heure, int minute) => DateTime(2026, 9, 1, heure, minute);

void main() {
  group('JourPointage.statut', () {
    test('4 pointages : journée complète', () {
      final j = JourPointage(
        date: DateTime(2026, 9, 1),
        pointages: [h(8, 0), h(12, 0), h(13, 0), h(17, 0)],
        estWeekend: false,
      );
      expect(j.statut, 'complet');
    });

    test('2 pointages : journée complète', () {
      final j = JourPointage(
        date: DateTime(2026, 9, 1),
        pointages: [h(8, 0), h(17, 0)],
        estWeekend: false,
      );
      expect(j.statut, 'complet');
    });

    test('3 pointages : journée incomplète', () {
      final j = JourPointage(
        date: DateTime(2026, 9, 1),
        pointages: [h(8, 0), h(12, 0), h(13, 0)],
        estWeekend: false,
      );
      expect(j.statut, 'incomplet');
    });

    test('1 pointage : journée incomplète', () {
      final j = JourPointage(
        date: DateTime(2026, 9, 1),
        pointages: [h(8, 0)],
        estWeekend: false,
      );
      expect(j.statut, 'incomplet');
    });

    test('aucun pointage un jour ouvré : absent', () {
      final j = JourPointage(date: DateTime(2026, 9, 1), pointages: [], estWeekend: false);
      expect(j.statut, 'absent');
    });

    test('samedi ou dimanche, même sans pointage : week-end', () {
      final j = JourPointage(date: DateTime(2026, 9, 5), pointages: [], estWeekend: true);
      expect(j.statut, 'weekend');
    });

    test('week-end prioritaire même avec des pointages', () {
      final j = JourPointage(
        date: DateTime(2026, 9, 5),
        pointages: [h(9, 0), h(12, 0)],
        estWeekend: true,
      );
      expect(j.statut, 'weekend');
    });
  });
}