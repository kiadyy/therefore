import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/rules/stat_rules.dart' as rules;
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/pointage_repository_provider.dart';
import '../../../data/session/identite_courante.dart';
import '../../../data/session/session_expired_exception.dart';
import '../../shared/composants.dart';
import '../../shared/error_state_view.dart';
import '../../shared/logout_action.dart';
import '../../shared/skeleton.dart';

const List<String> _moisNoms = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

/// Base mensuelle d'heures ouvrables (valeur de la maquette d'origine).
const double _heuresOuvrables = 184;

class DashboardBody extends StatefulWidget {
  final String matricule;

  const DashboardBody({super.key, this.matricule = 'MAT001'});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  late int _selectedYear;
  late int _selectedMonth;

  bool _isLoading = true;
  Object? _lastError;

  String _heureArrivee = '--:--:--';
  String _heureDepart = '--:--:--';
  double _heureRealisee = 0;
  int _nbRetards = 0;
  int _classementIndex = 0;
  int _classementTotal = 0;
  double _dureeMoyenneRetardMin = 0;
  double _dureeMoyenneTravailH = 0;
  String _prenom = '';
  String _societe = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadDashboardData();
  }

  /// Charge les données du mois sélectionné.
  /// [silencieux] : utilisé par « tirer pour actualiser ». Les cartes restent
  /// affichées pendant le rechargement, au lieu d'être remplacées par le
  /// squelette.
  Future<void> _loadDashboardData({bool silencieux = false}) async {
    if (!silencieux) {
      setState(() {
        _isLoading = true;
        _lastError = null;
      });
    }

    try {
      final pointageJour = await pointageRepository.getPointageDuJour(
        widget.matricule,
        annee: _selectedYear,
        mois: _selectedMonth,
      );
      final totalHeures = await pointageRepository.getTotalHeures(
        widget.matricule,
        annee: _selectedYear,
        mois: _selectedMonth,
      );
      final stats = await pointageRepository.getStatsEmploye(
        widget.matricule,
        annee: _selectedYear,
        mois: _selectedMonth,
      );

      // Partage l'identité avec l'avatar et le menu profil (mémoire vive
      // uniquement, rien n'est stocké sur le téléphone)
      IdentiteCourante.employe.value = stats;

      if (!mounted) return;
      setState(() {
        _heureArrivee = pointageJour.entree ?? '--:--:--';
        _heureDepart = pointageJour.sortie ?? '--:--:--';
        _heureRealisee = totalHeures.totalHeures;
        _nbRetards = stats.nbRetards;
        _classementIndex = stats.classementIndex;
        _classementTotal = stats.classementTotal;
        _dureeMoyenneRetardMin = rules.hmsToMinutes(stats.dureeMoyenneRetard);
        _dureeMoyenneTravailH =
            rules.hmsToMinutes(stats.dureeMoyenneTravail) / 60;
        _prenom = rules.prenomUsuel(stats.prenom);
        _societe = stats.societe;
        _lastError = null;
        _isLoading = false;
      });
    } catch (e) {
      if (e is SessionExpiredException) {
        if (mounted) forceLogout(context);
        return;
      }
      if (!mounted) return;
      setState(() {
        _lastError = e;
        _isLoading = false;
      });
    }
  }

  String _formatMinutesToHms(double minutes) {
    final totalSeconds = (minutes * 60).round();
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _openMonthPicker() async {
    final now = DateTime.now();
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final canGoNextYear = tempYear < now.year;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Choisir le mois',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Année précédente',
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () => setModalState(() {
                          tempYear--;
                          if (tempYear == now.year && tempMonth > now.month) {
                            tempMonth = now.month;
                          }
                        }),
                      ),
                      Text(
                        '$tempYear',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Année suivante',
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: canGoNextYear
                            ? () => setModalState(() => tempYear++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (i) {
                      final month = i + 1;
                      final isFuture =
                          tempYear == now.year && month > now.month;
                      final selected = month == tempMonth;
                      return ChoiceChip(
                        label: Text(_moisNoms[i]),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: AppColors.primaryGreen,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textDark,
                        ),
                        onSelected: isFuture
                            ? null
                            : (_) => setModalState(() => tempMonth = month),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusButton),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedYear = tempYear;
                          _selectedMonth = tempMonth;
                        });
                        Navigator.pop(context);
                        _loadDashboardData();
                      },
                      child: const Text(
                        'Valider',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget contenu;
    if (_isLoading) {
      contenu = const DashboardSkeleton();
    } else if (_lastError != null) {
      contenu = CarteBlanche(
        child: ErrorStateView(error: _lastError!, onRetry: _loadDashboardData),
      );
    } else {
      contenu = _buildCartes();
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () => _loadDashboardData(silencieux: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          EnTeteVert(
            titre: _prenom.isEmpty ? 'Bonjour' : 'Bonjour, $_prenom',
            sousTitre: _societe,
            controles: PastilleEnTete(
              icone: Icons.calendar_month_rounded,
              libelle: '${_moisNoms[_selectedMonth - 1]} $_selectedYear',
              chevron: true,
              onTap: _openMonthPicker,
            ),
          ),
          // Les cartes remontent sur l'en-tête vert (effet de superposition)
          Transform.translate(
            offset: const Offset(0, -56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingScreen,
              ),
              child: contenu,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartes() {
    final progression = (_heureRealisee / _heuresOuvrables).clamp(0.0, 1.0);

    return Column(
      children: [
        // Carte principale : heures réalisées
        CarteBlanche(
          child: Row(
            children: [
              _AnneauProgression(valeur: progression),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Heures réalisées', style: AppText.secondaire),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        rules.formatHeures(_heureRealisee),
                        style: AppText.chiffreFort,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'sur ${_heuresOuvrables.toInt()} h ouvrables',
                      style: AppText.secondaire,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.gap),

        // Horaires d'arrivée et de départ
        CarteBlanche(
          child: Row(
            children: [
              Expanded(
                child: _ValeurAvecIcone(
                  icone: Icons.login_rounded,
                  libelle: 'Arrivée moyenne',
                  valeur: _heureArrivee,
                ),
              ),
              const SizedBox(width: AppDimens.gap),
              Expanded(
                child: _ValeurAvecIcone(
                  icone: Icons.logout_rounded,
                  libelle: 'Départ moyen',
                  valeur: _heureDepart,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.gap),

        // Retards et classement
        _CarteRetards(
          nbRetards: _nbRetards,
          rang: _classementIndex,
          total: _classementTotal,
        ),
        const SizedBox(height: AppDimens.gap),

        // Durées moyennes
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TuileDuree(
                  icone: Icons.timer_outlined,
                  libelle: 'Retard moyen',
                  valeur: _formatMinutesToHms(_dureeMoyenneRetardMin),
                  couleur: rules.dureeRetardColor(_dureeMoyenneRetardMin),
                  appreciation: rules.dureeRetardLabel(_dureeMoyenneRetardMin),
                ),
              ),
              const SizedBox(width: AppDimens.gap),
              Expanded(
                child: _TuileDuree(
                  icone: Icons.work_outline_rounded,
                  libelle: 'Travail moyen / jour',
                  valeur: _formatMinutesToHms(_dureeMoyenneTravailH * 60),
                  couleur: rules.dureeTravailColor(_dureeMoyenneTravailH),
                  appreciation: rules.dureeTravailLabel(_dureeMoyenneTravailH),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Composants de l'écran
// ---------------------------------------------------------------------------

/// Fond clair et couleur d'encre associés à une couleur de règle
/// (vert, orange ou rouge), pour les icônes et les pastilles.
({Color fond, Color encre}) _teintePour(Color couleurRegle) {
  if (couleurRegle == Colors.red) {
    return (fond: AppColors.absentTint, encre: AppColors.absentText);
  }
  if (couleurRegle == AppColors.incompletBorder) {
    return (fond: AppColors.incompletBg, encre: AppColors.incompletText);
  }
  return (fond: AppColors.primaryTint, encre: AppColors.primaryGreen);
}

/// Anneau de progression des heures réalisées, animé une seule fois à
/// l'arrivée des données (animation désactivée si le téléphone le demande).
class _AnneauProgression extends StatelessWidget {
  final double valeur; // entre 0 et 1

  const _AnneauProgression({required this.valeur});

  @override
  Widget build(BuildContext context) {
    final sansAnimation = MediaQuery.of(context).disableAnimations;
    final couleur = AppColors.progressColorFor(valeur);

    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: valeur),
            duration: sansAnimation
                ? Duration.zero
                : const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => SizedBox(
              width: 112,
              height: 112,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 11,
                strokeCap: StrokeCap.round,
                backgroundColor: AppColors.fieldGrey,
                color: couleur,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(valeur * 100).round()} %',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const Text(
                'du mois',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValeurAvecIcone extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String valeur;

  const _ValeurAvecIcone({
    required this.icone,
    required this.libelle,
    required this.valeur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconeTuile(icone: icone),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(libelle, style: AppText.libelle),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valeur, style: AppText.valeur),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Carte des retards : nombre de retards, rang dans le département et
/// position visuelle sur une barre (du moins au plus en retard).
class _CarteRetards extends StatelessWidget {
  final int nbRetards;
  final int rang;
  final int total;

  const _CarteRetards({
    required this.nbRetards,
    required this.rang,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = rules.classementColor(nbRetards);
    final teinte = _teintePour(couleur);
    final aUnClassement = total > 0 && rang > 0;
    // Position du marqueur entre 0 (moins de retards) et 1 (plus de retards)
    final position =
        total > 1 ? ((rang - 1) / (total - 1)).clamp(0.0, 1.0) : 0.0;

    return CarteBlanche(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconeTuile(
                icone: Icons.leaderboard_rounded,
                fond: teinte.fond,
                encre: teinte.encre,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Retards du mois', style: AppText.libelle),
                    Text(rules.libelleRetards(nbRetards),
                        style: AppText.valeur),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    aUnClassement
                        ? '${rules.libelleRang(rang)} sur $total'
                        : 'Pas de données',
                    style: AppText.valeur,
                  ),
                  if (aUnClassement)
                    const Text('dans le département', style: AppText.libelle),
                ],
              ),
            ],
          ),
          if (aUnClassement) ...[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                const tailleMarqueur = 16.0;
                final x = position * (constraints.maxWidth - tailleMarqueur);
                return SizedBox(
                  height: tailleMarqueur,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 4,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.trackGrey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        left: x,
                        child: Container(
                          width: tailleMarqueur,
                          height: tailleMarqueur,
                          decoration: BoxDecoration(
                            color: couleur,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Moins de retards', style: AppText.libelle),
                Text('Plus de retards', style: AppText.libelle),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Tuile d'une durée moyenne, avec sa pastille d'appréciation colorée
/// (couleur et libellé calculés par les règles de stat_rules.dart).
class _TuileDuree extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String valeur;
  final Color couleur;
  final String appreciation;

  const _TuileDuree({
    required this.icone,
    required this.libelle,
    required this.valeur,
    required this.couleur,
    required this.appreciation,
  });

  @override
  Widget build(BuildContext context) {
    final teinte = _teintePour(couleur);

    return CarteBlanche(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconeTuile(icone: icone, fond: teinte.fond, encre: teinte.encre),
          const SizedBox(height: 12),
          Text(libelle, style: AppText.libelle),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valeur,
              style: AppText.valeur.copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(height: 10),
          PastilleStatut(
            texte: appreciation,
            point: couleur,
            fond: teinte.fond,
          ),
        ],
      ),
    );
  }
}
