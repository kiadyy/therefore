import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/rules/stat_rules.dart' as rules;
import '../../core/theme/app_theme.dart';
import '../../data/models/pointage_models.dart';
import '../../data/repositories/pointage_repository_provider.dart';
import '../../data/service/session_manager.dart';
import '../../data/session/identite_courante.dart';
import '../auth/presentation/login_page.dart';

Future<void> handleLogout(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Se déconnecter'),
      content: const Text('Voulez-vous vraiment vous déconnecter ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Déconnexion',
            style: TextStyle(color: AppColors.absentText),
          ),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  await SessionManager.clearSession();
  IdentiteCourante.effacer();

  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

// Empêche deux déconnexions simultanées (tableau de bord et historique
// peuvent recevoir un 401 en même temps au démarrage)
bool _deconnexionEnCours = false;

Future<void> forceLogout(BuildContext context) async {
  if (_deconnexionEnCours) return;
  _deconnexionEnCours = true;

  try {
    await SessionManager.clearSession();
    IdentiteCourante.effacer();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Votre session a expiré. Veuillez vous reconnecter.'),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  } finally {
    _deconnexionEnCours = false;
  }
}

/// Identité de l'employé connecté : celle déjà chargée par le tableau de
/// bord si elle existe, sinon demandée à l'API (point d'accès des
/// statistiques). Rien n'est stocké sur l'appareil. En cas d'erreur, renvoie
/// null : le panneau affiche alors seulement l'identifiant AD.
Future<EmployeStats?> _chargerIdentite() async {
  final enMemoire = IdentiteCourante.employe.value;
  if (enMemoire != null) return enMemoire;
  try {
    final now = DateTime.now();
    // Le matricule n'est pas transmis : le serveur identifie l'employé
    // grâce au jeton.
    return await pointageRepository.getStatsEmploye(
      '',
      annee: now.year,
      mois: now.month,
    );
  } catch (_) {
    return null;
  }
}

Future<void> _showProfileSheet(BuildContext context) async {
  final identifiant = await SessionManager.getUsername();
  // Lancé une seule fois, à l'ouverture du panneau
  final identiteFuture = _chargerIdentite();

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée du panneau
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.fieldGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),
              FutureBuilder<EmployeStats?>(
                future: identiteFuture,
                builder: (context, snapshot) {
                  final chargement =
                      snapshot.connectionState != ConnectionState.done;
                  final identite = snapshot.data;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Avatar(identite: identite, taille: 72),
                      if (chargement)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      if (identite != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${identite.prenom} ${identite.nom}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          identite.societe,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            if (identite != null) ...[
                              _LigneInfo(
                                icone: Icons.badge_outlined,
                                libelle: 'Matricule',
                                valeur: identite.matricule,
                              ),
                              const Divider(
                                height: 1,
                                color: AppColors.cardBorder,
                              ),
                            ],
                            _LigneInfo(
                              icone: Icons.person_outline_rounded,
                              libelle: 'Identifiant AD',
                              valeur: identifiant ?? '—',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // ferme le panneau avec SON propre contexte
                    Navigator.pop(sheetContext);
                    // déconnecte avec le contexte de la page (toujours valide)
                    handleLogout(context);
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.absentText,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusButton),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Une ligne d'information du panneau profil (icône, libellé, valeur).
class _LigneInfo extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String valeur;

  const _LigneInfo({
    required this.icone,
    required this.libelle,
    required this.valeur,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, size: 19, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Text(
            libelle,
            style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valeur,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar rond : initiales de l'employé si son identité est connue,
/// sinon une icône de personne.
class _Avatar extends StatelessWidget {
  final EmployeStats? identite;
  final double taille;

  const _Avatar({required this.identite, required this.taille});

  @override
  Widget build(BuildContext context) {
    final id = identite;
    return Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        shape: BoxShape.circle,
      ),
      child: id == null
          ? Icon(Icons.person_rounded, color: Colors.white, size: taille * 0.5)
          : Text(
              rules.initiales(id.prenom, id.nom),
              style: TextStyle(
                color: Colors.white,
                fontSize: taille * 0.36,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

/// Bouton de l'en-tête qui ouvre le menu profil : initiales de l'employé
/// une fois son identité chargée, sinon une icône de personne.
class ProfileIconButton extends StatelessWidget {
  const ProfileIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Menu profil',
      child: Material(
        color: const Color(0x29FFFFFF),
        shape: const CircleBorder(
          side: BorderSide(color: Color(0x80FFFFFF), width: 2),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _showProfileSheet(context),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Center(
              child: ValueListenableBuilder<EmployeStats?>(
                valueListenable: IdentiteCourante.employe,
                builder: (context, identite, _) {
                  if (identite == null) {
                    return const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 22,
                    );
                  }
                  return Text(
                    rules.initiales(identite.prenom, identite.nom),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
