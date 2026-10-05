import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Fait « respirer » doucement son contenu (variation d'opacité) pour
/// signaler un chargement en cours, à la place d'un indicateur qui tourne.
class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacite = Tween<double>(begin: 0.45, end: 1.0)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacite, child: widget.child);
  }
}

/// Bloc gris arrondi qui tient la place d'un texte pendant le chargement.
class SkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;

  const SkeletonBlock({super.key, this.width, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.fieldGrey,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Squelette du tableau de bord : 3 rangées de 2 cartes, avec la même
/// disposition, les mêmes marges et le même rayon que les vraies cartes.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget carte() {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.cardBorder, width: 1.4),
          ),
          child: const Column(
            children: [
              SkeletonBlock(width: 90, height: 10), // libellé
              Expanded(
                child: Center(
                  child: SkeletonBlock(width: 110, height: 24), // valeur
                ),
              ),
              SkeletonBlock(width: 70, height: 8), // légende
            ],
          ),
        ),
      );
    }

    Widget rangee() {
      return Expanded(
        child: Row(
          children: [carte(), const SizedBox(width: 16), carte()],
        ),
      );
    }

    return SkeletonPulse(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            rangee(),
            const SizedBox(height: 16),
            rangee(),
            const SizedBox(height: 16),
            rangee(),
          ],
        ),
      ),
    );
  }
}

/// Squelette de l'historique : quelques cartes de jour avec la même forme
/// que les vraies (nom du jour, statut, date, pastilles d'horaires).
class HistorySkeleton extends StatelessWidget {
  const HistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBlock(width: 70, height: 10), // nom du jour
                  SkeletonBlock(width: 60, height: 10), // statut
                ],
              ),
              SizedBox(height: 8),
              SkeletonBlock(width: 120, height: 18), // date
              SizedBox(height: 12),
              Row(
                children: [
                  SkeletonBlock(width: 44, height: 20), // horaire
                  SizedBox(width: 8),
                  SkeletonBlock(width: 44, height: 20), // horaire
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
