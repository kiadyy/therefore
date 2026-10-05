import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'logout_action.dart';

/// En-tête vert commun aux deux écrans : titre, sous-titre, avatar du menu
/// profil à droite, puis une ligne de contrôles (filtre de période...).
/// Le bas arrondi est recouvert par les cartes (effet de superposition).
class EnTeteVert extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final Widget controles;

  const EnTeteVert({
    super.key,
    required this.titre,
    this.sousTitre,
    required this.controles,
  });

  @override
  Widget build(BuildContext context) {
    final sous = sousTitre;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 76),
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: AppText.titre.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sous != null && sous.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        sous,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xE0FFFFFF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ProfileIconButton(),
            ],
          ),
          const SizedBox(height: 18),
          controles,
        ],
      ),
    );
  }
}

/// Bouton-pastille translucide de l'en-tête vert (filtre de période,
/// réinitialisation...). Sans [libelle], c'est un bouton icône seul.
class PastilleEnTete extends StatelessWidget {
  final IconData icone;
  final String? libelle;
  final bool chevron;
  final String? infobulle;
  final VoidCallback onTap;

  const PastilleEnTete({
    super.key,
    required this.icone,
    this.libelle,
    this.chevron = false,
    this.infobulle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final texte = libelle;
    Widget bouton = Material(
      color: const Color(0x29FFFFFF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 40,
          constraints: const BoxConstraints(minWidth: 44),
          padding: EdgeInsets.only(
            left: texte == null ? 0 : 12,
            right: texte == null ? 0 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: Colors.white, size: 18),
              if (texte != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    texte,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (chevron) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    final message = infobulle;
    if (message != null) {
      bouton = Tooltip(message: message, child: bouton);
    }
    return bouton;
  }
}

/// Carte blanche aux coins arrondis, base de tous les blocs de contenu.
class CarteBlanche extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CarteBlanche({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

/// Icône dans un carré aux coins arrondis, sur fond teinté.
class IconeTuile extends StatelessWidget {
  final IconData icone;
  final Color fond;
  final Color encre;

  const IconeTuile({
    super.key,
    required this.icone,
    this.fond = AppColors.primaryTint,
    this.encre = AppColors.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(AppDimens.radiusIcon),
      ),
      child: Icon(icone, size: 21, color: encre),
    );
  }
}

/// Pastille de statut : point coloré + texte, sur fond teinté.
class PastilleStatut extends StatelessWidget {
  final String texte;
  final Color point;
  final Color fond;

  const PastilleStatut({
    super.key,
    required this.texte,
    required this.point,
    required this.fond,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: point, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(texte, style: AppText.pastille),
        ],
      ),
    );
  }
}
