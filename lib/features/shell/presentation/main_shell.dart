import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/presentation/dashboard_body.dart';
import '../../history/presentation/history_body.dart';

class MainShell extends StatefulWidget {
  final String matricule;

  const MainShell({super.key, this.matricule = 'MAT001'});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // 0 = Statistique (tableau de bord du mois), 1 = pointage (historique)
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          Expanded(
            // La zone de la barre d'état du téléphone est peinte en vert,
            // pour prolonger l'en-tête jusqu'en haut de l'écran ; le contenu
            // commence en dessous. Le bas est géré par la barre de navigation.
            child: ColoredBox(
              color: AppColors.primaryGreen,
              child: SafeArea(
                bottom: false,
                child: ColoredBox(
                  color: AppColors.backgroundLight,
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      DashboardBody(matricule: widget.matricule),
                      HistoryBody(matricule: widget.matricule),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _BarreNavigation(
            ongletActif: _selectedTab,
            onChanger: (index) => setState(() => _selectedTab = index),
          ),
        ],
      ),
    );
  }
}

/// Barre de navigation du bas : deux onglets, l'actif en vert citron.
/// Toucher l'onglet déjà actif ne fait rien (on reste sur la page).
class _BarreNavigation extends StatelessWidget {
  final int ongletActif;
  final ValueChanged<int> onChanger;

  const _BarreNavigation({required this.ongletActif, required this.onChanger});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: _OngletBouton(
                  icone: Icons.bar_chart_rounded,
                  libelle: 'Statistique',
                  actif: ongletActif == 0,
                  onTap: () => onChanger(0),
                ),
              ),
              const SizedBox(width: AppDimens.gap),
              Expanded(
                child: _OngletBouton(
                  icone: Icons.event_available_rounded,
                  libelle: 'Pointage',
                  actif: ongletActif == 1,
                  onTap: () => onChanger(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OngletBouton extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final bool actif;
  final VoidCallback onTap;

  const _OngletBouton({
    required this.icone,
    required this.libelle,
    required this.actif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? AppColors.textDark : AppColors.textGrey;

    return Semantics(
      selected: actif,
      button: true,
      child: Material(
        color: actif ? AppColors.accentLime : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusButton),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          onTap: actif ? null : onTap,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icone, size: 22, color: couleur),
                const SizedBox(width: 8),
                Text(
                  libelle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: actif ? FontWeight.w600 : FontWeight.w500,
                    color: couleur,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
