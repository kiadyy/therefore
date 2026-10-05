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

/// Squelette de l'écran Statistique : mêmes cartes, mêmes hauteurs et
/// même rayon que le contenu réel (carte principale, horaires, retards,
/// deux tuiles de durées moyennes).
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  Widget _carte({required double hauteur, required Widget child}) {
    return Container(
      height: hauteur,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Column(
        children: [
          // Carte principale : anneau + textes
          _carte(
            hauteur: 152,
            child: const Row(
              children: [
                SkeletonBlock(width: 112, height: 112),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 110, height: 12),
                      SizedBox(height: 10),
                      SkeletonBlock(width: 140, height: 28),
                      SizedBox(height: 10),
                      SkeletonBlock(width: 120, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Horaires
          _carte(
            hauteur: 76,
            child: const Row(
              children: [
                Expanded(child: SkeletonBlock(height: 38)),
                SizedBox(width: 16),
                Expanded(child: SkeletonBlock(height: 38)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Retards
          _carte(
            hauteur: 124,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 160, height: 40),
                Spacer(),
                SkeletonBlock(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Durées moyennes
          Row(
            children: [
              Expanded(
                child: _carte(
                  hauteur: 150,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 40, height: 40),
                      Spacer(),
                      SkeletonBlock(width: 100, height: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _carte(
                  hauteur: 150,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 40, height: 40),
                      Spacer(),
                      SkeletonBlock(width: 100, height: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Squelette de l'écran Pointage : résumé, graphique et cartes de jour,
/// avec les mêmes formes et le même rayon que le contenu réel.
class HistorySkeleton extends StatelessWidget {
  const HistorySkeleton({super.key});

  Widget _carte({required double hauteur, required Widget child}) {
    return Container(
      height: hauteur,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }

  Widget _jour() {
    return _carte(
      hauteur: 108,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: 40, height: 40), // date
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 90, height: 12), // statut
                SizedBox(height: 12),
                SkeletonBlock(height: 10), // frise
                SizedBox(height: 12),
                Row(
                  children: [
                    SkeletonBlock(width: 44, height: 20),
                    SizedBox(width: 6),
                    SkeletonBlock(width: 44, height: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Column(
        children: [
          // Résumé de la période
          _carte(
            hauteur: 118,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 170, height: 12),
                SizedBox(height: 10),
                SkeletonBlock(width: 120, height: 30),
                Spacer(),
                Row(
                  children: [
                    SkeletonBlock(width: 86, height: 24),
                    SizedBox(width: 8),
                    SkeletonBlock(width: 86, height: 24),
                    SizedBox(width: 8),
                    SkeletonBlock(width: 70, height: 24),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Graphique
          _carte(
            hauteur: 200,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 160, height: 12),
                Spacer(),
                SkeletonBlock(height: 100),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _jour(),
          const SizedBox(height: 12),
          _jour(),
          const SizedBox(height: 12),
          _jour(),
        ],
      ),
    );
  }
}
