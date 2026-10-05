import 'package:flutter_test/flutter_test.dart';
import 'package:therefore_pointage/core/rules/stat_rules.dart';
import 'package:therefore_pointage/data/models/pointage_models.dart';

DateTime h(int heure, int minute) => DateTime(2026, 9, 1, heure, minute);

JourPointage jour(List<DateTime> pointages) => JourPointage(
      date: DateTime(2026, 9, 1),
      pointages: pointages,
      estWeekend: false,
    );

void main() {
  group('JourPointage.dureeTravaillee', () {
    test('2 pointages : durée entre arrivée et départ', () {
      expect(
        jour([h(8, 0), h(17, 0)]).dureeTravaillee,
        const Duration(hours: 9),
      );
    });

    test('4 pointages : la pause déjeuner n\'est pas comptée', () {
      expect(
        jour([h(8, 0), h(12, 0), h(13, 0), h(17, 5)]).dureeTravaillee,
        const Duration(hours: 8, minutes: 5),
      );
    });

    test('pointages reçus dans le désordre : même résultat', () {
      expect(
        jour([h(17, 5), h(8, 0), h(13, 0), h(12, 0)]).dureeTravaillee,
        const Duration(hours: 8, minutes: 5),
      );
    });

    test('nombre impair de pointages : durée non calculable', () {
      expect(jour([h(8, 0), h(12, 0), h(13, 0)]).dureeTravaillee, isNull);
    });

    test('aucun pointage : durée non calculable', () {
      expect(jour([]).dureeTravaillee, isNull);
    });
  });

  group('formatDureeTravail', () {
    test('les minutes sont toujours écrites sur 2 chiffres', () {
      expect(
        formatDureeTravail(const Duration(hours: 8, minutes: 5)),
        '8 h 05',
      );
      expect(formatDureeTravail(const Duration(hours: 9)), '9 h 00');
    });
  });
}
