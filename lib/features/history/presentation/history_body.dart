import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/rules/stat_rules.dart' as rules;
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pointage_models.dart';
import '../../../data/repositories/pointage_repository_provider.dart';
import '../../../data/session/session_expired_exception.dart';
import '../../shared/composants.dart';
import '../../shared/error_state_view.dart';
import '../../shared/logout_action.dart';
import '../../shared/skeleton.dart';

const _joursCourts = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
const _joursGraphique = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];

class HistoryBody extends StatefulWidget {
  final String matricule;

  const HistoryBody({super.key, this.matricule = 'MAT001'});

  @override
  State<HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<HistoryBody> {
  late DateTime _dateDebut;
  late DateTime _dateFin;
  bool _periodeParDefaut = true;

  bool _isLoading = true;
  Object? _lastError;
  List<JourPointage> _jours = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateFin = now;
    _dateDebut = now.subtract(const Duration(days: 6));
    _loadHistorique();
  }

  /// Charge l'historique de la période sélectionnée.
  /// [silencieux] : utilisé par « tirer pour actualiser ». Le contenu reste
  /// affiché pendant le rechargement, au lieu d'être remplacé par le squelette.
  Future<void> _loadHistorique({bool silencieux = false}) async {
    if (!silencieux) {
      setState(() {
        _isLoading = true;
        _lastError = null;
      });
    }

    try {
      final events = await pointageRepository.getHistorique(
        widget.matricule,
        debut: _dateDebut,
        fin: _dateFin,
      );

      final Map<String, List<DateTime>> parJour = {};
      for (final e in events) {
        final key = DateFormat('yyyy-MM-dd').format(e.datePointage);
        parJour.putIfAbsent(key, () => []).add(e.datePointage);
      }
      for (final list in parJour.values) {
        list.sort();
      }

      final jours = <JourPointage>[];
      for (var d = _dateDebut;
          !d.isAfter(_dateFin);
          d = d.add(const Duration(days: 1))) {
        final key = DateFormat('yyyy-MM-dd').format(d);
        final estWeekend =
            d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
        final pointages = parJour[key] ?? [];

        jours.add(
          JourPointage(date: d, pointages: pointages, estWeekend: estWeekend),
        );
      }

      jours.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _jours = jours;
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

  Future<void> _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _dateDebut, end: _dateFin),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primaryGreen),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _dateDebut = result.start;
        _dateFin = result.end;
        _periodeParDefaut = false;
      });
      _loadHistorique();
    }
  }

  void _resetToDefault() {
    final now = DateTime.now();
    setState(() {
      _dateFin = now;
      _dateDebut = now.subtract(const Duration(days: 6));
      _periodeParDefaut = true;
    });
    _loadHistorique();
  }

  int get _nombreDeJours =>
      DateUtils.dateOnly(_dateFin)
          .difference(DateUtils.dateOnly(_dateDebut))
          .inDays +
      1;

  @override
  Widget build(BuildContext context) {
    final Widget contenu;
    if (_isLoading) {
      contenu = const HistorySkeleton();
    } else if (_lastError != null) {
      contenu = CarteBlanche(
        child: ErrorStateView(error: _lastError!, onRetry: _loadHistorique),
      );
    } else if (_jours.isEmpty) {
      contenu = const CarteBlanche(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('Aucun pointage sur cette période.')),
        ),
      );
    } else {
      contenu = _buildContenu();
    }

    final format = DateFormat('dd/MM');
    final formatAnnee = DateFormat('dd/MM/yyyy');

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () => _loadHistorique(silencieux: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          EnTeteVert(
            titre: 'Mon pointage',
            sousTitre: _periodeParDefaut
                ? '7 derniers jours'
                : rules.accord(_nombreDeJours, 'jour'),
            controles: Row(
              children: [
                Flexible(
                  child: PastilleEnTete(
                    icone: Icons.date_range_rounded,
                    libelle:
                        '${format.format(_dateDebut)} → ${formatAnnee.format(_dateFin)}',
                    chevron: true,
                    onTap: _pickDateRange,
                  ),
                ),
                const SizedBox(width: 8),
                PastilleEnTete(
                  icone: Icons.restart_alt_rounded,
                  infobulle: 'Revenir aux 7 derniers jours',
                  onTap: _resetToDefault,
                ),
              ],
            ),
          ),
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

  Widget _buildContenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CarteResume(jours: _jours),
        const SizedBox(height: AppDimens.gap),
        // Le graphique se lit de gauche (plus ancien) à droite (plus récent)
        _CarteGraphique(jours: _jours.reversed.toList()),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Détail par jour',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text('frise de 7 h à 19 h', style: AppText.libelle),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final jour in _jours) ...[
          _JourCard(jour: jour),
          const SizedBox(height: AppDimens.gap),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Apparence de chaque statut
// ---------------------------------------------------------------------------

class _StyleStatut {
  final String libelle;
  final Color fond;
  final Color bordure;
  final Color point;
  final Color encre;
  final Color piste;

  const _StyleStatut({
    required this.libelle,
    required this.fond,
    required this.bordure,
    required this.point,
    required this.encre,
    required this.piste,
  });

  static _StyleStatut pour(String statut) {
    switch (statut) {
      case 'complet':
        return const _StyleStatut(
          libelle: 'Complet',
          fond: AppColors.white,
          bordure: AppColors.primaryGreen,
          point: AppColors.primaryGreen,
          encre: AppColors.primaryGreen,
          piste: AppColors.trackGrey,
        );
      case 'incomplet':
        return const _StyleStatut(
          libelle: 'Incomplet',
          fond: AppColors.incompletBg,
          bordure: AppColors.incompletBorder,
          point: AppColors.incompletBorder,
          encre: AppColors.incompletText,
          piste: Color(0xCCFFFFFF),
        );
      case 'weekend':
        return const _StyleStatut(
          libelle: 'Week-end',
          fond: AppColors.weekendBg,
          bordure: AppColors.weekendBorder,
          point: AppColors.weekendBorder,
          encre: AppColors.weekendBorder,
          piste: Color(0xCCFFFFFF),
        );
      default:
        return const _StyleStatut(
          libelle: 'Absent',
          fond: AppColors.white,
          bordure: AppColors.absentRed,
          point: AppColors.absentRed,
          encre: AppColors.absentText,
          piste: AppColors.trackGrey,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Résumé de la période
// ---------------------------------------------------------------------------

class _CarteResume extends StatelessWidget {
  final List<JourPointage> jours;

  const _CarteResume({required this.jours});

  @override
  Widget build(BuildContext context) {
    var total = Duration.zero;
    var complets = 0;
    var incomplets = 0;
    var absents = 0;
    for (final j in jours) {
      total += j.dureeTravaillee ?? Duration.zero;
      switch (j.statut) {
        case 'complet':
          complets++;
          break;
        case 'incomplet':
          incomplets++;
          break;
        case 'absent':
          absents++;
          break;
      }
    }

    return CarteBlanche(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Temps travaillé sur la période',
              style: AppText.secondaire),
          const SizedBox(height: 2),
          Text(rules.formatDureeTravail(total), style: AppText.chiffreFort),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PastilleStatut(
                texte: rules.accord(complets, 'complet'),
                point: AppColors.primaryGreen,
                fond: AppColors.primaryTint,
              ),
              PastilleStatut(
                texte: rules.accord(incomplets, 'incomplet'),
                point: AppColors.incompletBorder,
                fond: AppColors.incompletBg,
              ),
              PastilleStatut(
                texte: rules.accord(absents, 'absent'),
                point: AppColors.absentRed,
                fond: AppColors.absentTint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Graphique des heures travaillées par jour
// ---------------------------------------------------------------------------

class _CarteGraphique extends StatelessWidget {
  /// Jours du plus ancien au plus récent.
  final List<JourPointage> jours;

  const _CarteGraphique({required this.jours});

  static const double _hauteurMaxBarre = 110;
  static const double _largeurMinColonne = 40;

  @override
  Widget build(BuildContext context) {
    // Échelle : au moins 10 h, ou la plus longue journée de la période
    var heuresMax = 10.0;
    for (final j in jours) {
      final d = j.dureeTravaillee;
      if (d != null) heuresMax = math.max(heuresMax, d.inMinutes / 60);
    }
    final aujourdhui = DateUtils.dateOnly(DateTime.now());

    return CarteBlanche(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Heures travaillées par jour', style: AppText.secondaire),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final largeurColonne = math.max(
                _largeurMinColonne,
                constraints.maxWidth / jours.length,
              );
              final colonnes = Row(
                children: [
                  for (final j in jours)
                    SizedBox(
                      width: largeurColonne,
                      child: _ColonneJour(
                        jour: j,
                        heuresMax: heuresMax,
                        hauteurMax: _hauteurMaxBarre,
                        estAujourdhui: DateUtils.dateOnly(j.date) == aujourdhui,
                      ),
                    ),
                ],
              );
              // Longue période : le graphique défile horizontalement,
              // en partant des jours les plus récents (à droite).
              if (largeurColonne * jours.length > constraints.maxWidth) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: colonnes,
                );
              }
              return colonnes;
            },
          ),
        ],
      ),
    );
  }
}

class _ColonneJour extends StatelessWidget {
  final JourPointage jour;
  final double heuresMax;
  final double hauteurMax;
  final bool estAujourdhui;

  const _ColonneJour({
    required this.jour,
    required this.heuresMax,
    required this.hauteurMax,
    required this.estAujourdhui,
  });

  @override
  Widget build(BuildContext context) {
    final duree = jour.dureeTravaillee;
    final statut = jour.statut;

    String? valeur;
    Color couleurValeur = AppColors.textDark;
    double hauteur = 3;
    Color couleurBarre = AppColors.fieldGrey;

    if (duree != null) {
      valeur = rules.formatDureeCourt(duree);
      hauteur = math.max(4.0, duree.inMinutes / 60 / heuresMax * hauteurMax);
      couleurBarre = AppColors.primaryGreen;
    } else if (statut == 'incomplet') {
      valeur = '—';
      couleurValeur = AppColors.incompletText;
      couleurBarre = AppColors.incompletBorder;
    } else if (statut == 'absent') {
      valeur = '0';
      couleurValeur = AppColors.absentText;
      couleurBarre = AppColors.absentRed;
    }

    final libelleJour =
        '${_joursGraphique[jour.date.weekday - 1]} ${DateFormat('dd').format(jour.date)}';

    return SizedBox(
      height: hauteurMax + 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 16,
            child: valeur == null
                ? null
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      valeur,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: couleurValeur,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 22,
            height: hauteur,
            decoration: BoxDecoration(
              color: couleurBarre,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
                bottom: Radius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 16,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                libelleJour,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: estAujourdhui ? FontWeight.w600 : FontWeight.w400,
                  color: jour.estWeekend
                      ? AppColors.weekendBorder
                      : (estAujourdhui
                          ? AppColors.textDark
                          : AppColors.textGrey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte d'un jour
// ---------------------------------------------------------------------------

class _JourCard extends StatelessWidget {
  final JourPointage jour;

  const _JourCard({required this.jour});

  @override
  Widget build(BuildContext context) {
    final style = _StyleStatut.pour(jour.statut);
    final duree = jour.dureeTravaillee;
    final String? dureeAffichee = duree != null
        ? rules.formatDureeTravail(duree)
        : (jour.statut == 'incomplet' ? '—' : null);
    // Un week-end sans pointage s'affiche en version compacte
    final compact = jour.estWeekend && jour.pointages.isEmpty;

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 12 : 14),
      decoration: BoxDecoration(
        color: style.fond,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: style.bordure),
      ),
      child: Row(
        crossAxisAlignment:
            compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          // Bloc date : numéro du jour + jour abrégé
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(jour.date),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  _joursCourts[jour.date.weekday - 1],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: style.point,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        style.libelle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: style.encre,
                        ),
                      ),
                    ),
                    if (dureeAffichee != null)
                      Text(
                        dureeAffichee,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: style.encre,
                        ),
                      ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 10),
                  _Frise(jour: jour, style: style),
                  const SizedBox(height: 10),
                  if (jour.pointages.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: jour.pointages
                          .map((h) => _TimeBadge(time: h))
                          .toList(),
                    )
                  else
                    const Text('Aucun pointage', style: AppText.libelle),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Frise de la journée (7 h → 19 h) : les plages travaillées entre deux
/// pointages sont dessinées en couleur ; un pointage sans sa paire
/// (journée incomplète) est marqué par un point.
class _Frise extends StatelessWidget {
  final JourPointage jour;
  final _StyleStatut style;

  const _Frise({required this.jour, required this.style});

  @override
  Widget build(BuildContext context) {
    final tries = [...jour.pointages]..sort();
    const tailleMarqueur = 14.0;

    return Semantics(
      label: 'Frise des plages travaillées de 7 h à 19 h',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largeur = constraints.maxWidth;
          final elements = <Widget>[
            Positioned(
              left: 0,
              right: 0,
              top: 2,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: style.piste,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ];

          // Plages travaillées : pointages pris deux par deux
          var i = 0;
          for (; i + 1 < tries.length; i += 2) {
            final debut = rules.fractionFrise(tries[i]) * largeur;
            final fin = rules.fractionFrise(tries[i + 1]) * largeur;
            elements.add(
              Positioned(
                left: debut,
                top: 2,
                child: Container(
                  width: math.max(4.0, fin - debut),
                  height: 10,
                  decoration: BoxDecoration(
                    color: style.point,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            );
          }

          // Pointage restant sans sa paire
          if (i < tries.length) {
            final double borneMax = math.max(0.0, largeur - tailleMarqueur);
            final double x =
                (rules.fractionFrise(tries[i]) * largeur - tailleMarqueur / 2)
                    .clamp(0.0, borneMax)
                    .toDouble();
            elements.add(
              Positioned(
                left: x,
                top: 0,
                child: Container(
                  width: tailleMarqueur,
                  height: tailleMarqueur,
                  decoration: BoxDecoration(
                    color: style.point,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            );
          }

          return SizedBox(
              height: tailleMarqueur, child: Stack(children: elements));
        },
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final DateTime time;

  const _TimeBadge({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        DateFormat('H:mm').format(time),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
