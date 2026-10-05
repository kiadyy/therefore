import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/pointage_repository_provider.dart';
import '../../shared/logout_action.dart';
import '../../../data/session/session_expired_exception.dart';
import '../../../core/rules/stat_rules.dart' as rules;
import '../../shared/error_state_view.dart';

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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _lastError = null;
    });

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  const Text('Choisir le mois',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setModalState(() {
                          tempYear--;
                          if (tempYear == now.year && tempMonth > now.month) {
                            tempMonth = now.month;
                          }
                        }),
                      ),
                      Text('$tempYear',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: canGoNextYear
                            ? () => setModalState(() => tempYear++)
                            : null,
                        color: canGoNextYear
                            ? null
                            : AppColors.textGrey.withOpacity(0.4),
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
                        selectedColor: AppColors.primaryGreen,
                        backgroundColor: isFuture
                            ? AppColors.fieldGrey.withOpacity(0.5)
                            : null,
                        labelStyle: TextStyle(
                          color: isFuture
                              ? AppColors.textGrey.withOpacity(0.5)
                              : (selected ? Colors.white : AppColors.textDark),
                        ),
                        onSelected: isFuture
                            ? null
                            : (_) => setModalState(() => tempMonth = month),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentLime,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedYear = tempYear;
                          _selectedMonth = tempMonth;
                        });
                        Navigator.pop(context);
                        _loadDashboardData();
                      },
                      child: const Text('Valider'),
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
    return Column(
      children: [
        Container(
          height: 70,
          color: AppColors.primaryGreen,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _openMonthPicker,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${_moisNoms[_selectedMonth - 1]} $_selectedYear',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const ProfileIconButton(),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _lastError != null
                  ? ErrorStateView(
                      error: _lastError!, onRetry: _loadDashboardData)
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'HEURE D\'ARRIVÉE',
                                    value: _heureArrivee,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
                                    label: 'HEURE DE DÉPART',
                                    value: _heureDepart,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'HEURE RÉALISÉE',
                                    value:
                                        '${_heureRealisee.toStringAsFixed(2)}h',
                                    caption: 'Sur 184h (Jours ouvrables)',
                                    showDot: false,
                                    showProgressBar: true,
                                    progressValue:
                                        (_heureRealisee / 184).clamp(0, 1),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
                                    label: 'CLASSEMENT RETARDS',
                                    value: '$_nbRetards retard(s)',
                                    caption: _classementTotal > 0
                                        ? '${_classementIndex}e sur $_classementTotal (Département)'
                                        : 'Pas de données',
                                    dotColor: rules.classementColor(_nbRetards),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'DURÉE MOYENNE RETARD',
                                    value: _formatMinutesToHms(
                                        _dureeMoyenneRetardMin),
                                    caption: rules.dureeRetardLabel(
                                        _dureeMoyenneRetardMin),
                                    dotColor: rules.dureeRetardColor(
                                        _dureeMoyenneRetardMin),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
                                    label: 'DURÉE MOYENNE TRAVAIL',
                                    value: _formatMinutesToHms(
                                        _dureeMoyenneTravailH * 60),
                                    caption: rules.dureeTravailLabel(
                                        _dureeMoyenneTravailH),
                                    dotColor: rules.dureeTravailColor(
                                        _dureeMoyenneTravailH),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final bool showDot;
  final Color? dotColor;
  final bool showProgressBar;
  final double progressValue;

  const _StatCard({
    required this.label,
    required this.value,
    this.caption,
    this.showDot = true,
    this.dotColor,
    this.showProgressBar = false,
    this.progressValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight;
        final valueFontSize = (cardHeight * 0.18).clamp(20.0, 32.0);
        final labelFontSize = (cardHeight * 0.08).clamp(10.0, 12.0);
        final captionFontSize = (cardHeight * 0.075).clamp(9.0, 11.0);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: cardHeight * 0.06, vertical: cardHeight * 0.06),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.success, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Label toujours en haut, centré horizontalement
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                  letterSpacing: 0.3,
                ),
              ),

              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),

              if (showProgressBar) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 6,
                    backgroundColor: AppColors.fieldGrey,
                    valueColor: AlwaysStoppedAnimation(
                        AppColors.progressColorFor(progressValue)),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              if (caption != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showDot) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: dotColor ?? AppColors.success,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        caption!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: captionFontSize,
                            color: AppColors.textGrey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
