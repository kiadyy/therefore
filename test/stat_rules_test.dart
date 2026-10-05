import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:therefore_pointage/core/rules/stat_rules.dart';
import 'package:therefore_pointage/core/constants/app_colors.dart';

void main() {
  group('classementColor', () {
    test('12 retards ou moins : vert', () {
      expect(classementColor(0), AppColors.success);
      expect(classementColor(12), AppColors.success);
    });
    test('entre 13 et 15 retards : orange', () {
      expect(classementColor(13), const Color(0xFFF09517));
      expect(classementColor(15), const Color(0xFFF09517));
    });
    test('16 retards ou plus : rouge', () {
      expect(classementColor(16), Colors.red);
      expect(classementColor(30), Colors.red);
    });
  });

  group('dureeRetardColor et dureeRetardLabel', () {
    test('moins de 30 min : vert, libellé Moyenne', () {
      expect(dureeRetardColor(20), AppColors.success);
      expect(dureeRetardLabel(20), 'Moyenne');
    });
    test('entre 30 min et 2h : orange, libellé Moyenne', () {
      expect(dureeRetardColor(60), const Color(0xFFF09517));
      expect(dureeRetardLabel(60), 'Moyenne');
    });
    test('plus de 2h : rouge, libellé Faible', () {
      expect(dureeRetardColor(150), Colors.red);
      expect(dureeRetardLabel(150), 'Faible');
    });
  });

  group('dureeTravailColor et dureeTravailLabel', () {
    test('4h ou moins : rouge, libellé Faible', () {
      expect(dureeTravailColor(4), Colors.red);
      expect(dureeTravailLabel(4), 'Faible');
    });
    test('entre 4h et 7h : orange, libellé Moyenne', () {
      expect(dureeTravailColor(5.5), const Color(0xFFF09517));
      expect(dureeTravailLabel(5.5), 'Moyenne');
    });
    test('plus de 7h : vert, libellé Élevé', () {
      expect(dureeTravailColor(8.07), AppColors.success);
      expect(dureeTravailLabel(8.07), 'Élevé');
    });
  });

  group('hmsToMinutes', () {
    test('convertit correctement un format HH:mm:ss', () {
      expect(hmsToMinutes('01:42:14'), closeTo(102.23, 0.01));
      expect(hmsToMinutes('00:30:00'), 30.0);
      expect(hmsToMinutes('02:00:00'), 120.0);
    });
    test('renvoie 0 pour un format invalide plutôt que de planter', () {
      expect(hmsToMinutes(''), 0);
      expect(hmsToMinutes('abc'), 0);
    });
  });
}
