import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/pointage_models.dart';
import '../../../data/repositories/pointage_repository_provider.dart';

class HistoryBody extends StatefulWidget {
  final String matricule;

  const HistoryBody({super.key, this.matricule = 'MAT001'});

  @override
  State<HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<HistoryBody> {
  late DateTime _dateDebut;
  late DateTime _dateFin;

  bool _isLoading = true;
  String? _errorMessage;
  List<JourPointage> _jours = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateFin = now;
    _dateDebut = now.subtract(const Duration(days: 6));
    _loadHistorique();
  }

  Future<void> _loadHistorique() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final events = await pointageRepository.getHistorique(
        widget.matricule,
        debut: _dateDebut,
        fin: _dateFin,
      );

      final Map<String, List<PointageEvent>> parJour = {};
      for (final e in events) {
        final key = DateFormat('yyyy-MM-dd').format(e.datePointage);
        parJour.putIfAbsent(key, () => []).add(e);
      }

      final jours = <JourPointage>[];
      for (var d = _dateDebut; !d.isAfter(_dateFin); d = d.add(const Duration(days: 1))) {
        final key = DateFormat('yyyy-MM-dd').format(d);
        final estWeekend = d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
        final evts = parJour[key];

        DateTime? entree;
        DateTime? sortie;
        if (evts != null && evts.isNotEmpty) {
          evts.sort((a, b) => a.datePointage.compareTo(b.datePointage));
          entree = evts.first.datePointage;
          if (evts.length > 1) sortie = evts.last.datePointage;
        }

        jours.add(JourPointage(date: d, entree: entree, sortie: sortie, estWeekend: estWeekend));
      }

      jours.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _jours = jours;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger l\'historique.';
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
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primaryGreen),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _dateDebut = result.start;
        _dateFin = result.end;
      });
      _loadHistorique();
    }
  }

  void _resetToDefault() {
    final now = DateTime.now();
    setState(() {
      _dateFin = now;
      _dateDebut = now.subtract(const Duration(days: 6));
    });
    _loadHistorique();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        Container(
          color: AppColors.primaryGreen,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              const Text(
                'Historique de pointage',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: _pickDateRange,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.date_range, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${dateFormat.format(_dateDebut)}  →  ${dateFormat.format(_dateFin)}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _resetToDefault,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.restart_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _jours.isEmpty
                      ? const Center(child: Text('Aucun pointage sur cette période.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _jours.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _JourCard(jour: _jours[index]),
                        ),
        ),
      ],
    );
  }
}

class _JourCard extends StatelessWidget {
  final JourPointage jour;

  const _JourCard({required this.jour});

  static const _joursSemaine = [
    'LUNDI', 'MARDI', 'MERCREDI', 'JEUDI', 'VENDREDI', 'SAMEDI', 'DIMANCHE'
  ];

  @override
  Widget build(BuildContext context) {
    final nomJour = _joursSemaine[jour.date.weekday - 1];
    final dateStr = DateFormat('dd/MM/yyyy').format(jour.date);

    late Color badgeColor;
    late Color cardBg;
    late Color cardBorder;
    late String badgeLabel;

    switch (jour.statut) {
      case 'complet':
        badgeColor = AppColors.success;
        cardBg = Colors.white;
        cardBorder = AppColors.success;
        badgeLabel = 'Complet';
        break;
      case 'incomplet':
        badgeColor = AppColors.incompletBorder;
        cardBg = AppColors.incompletBg;
        cardBorder = AppColors.incompletBorder;
        badgeLabel = 'Incomplet';
        break;
      case 'weekend':
        badgeColor = AppColors.weekendBorder;
        cardBg = AppColors.weekendBg;
        cardBorder = AppColors.weekendBorder;
        badgeLabel = 'Weekend';
        break;
      default:
        badgeColor = Colors.red;
        cardBg = Colors.white;
        cardBorder = Colors.red;
        badgeLabel = 'Absent';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nomJour,
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(badgeLabel, style: TextStyle(fontSize: 12, color: badgeColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          if (jour.entree != null || jour.sortie != null)
            Row(
              children: [
                if (jour.entree != null) _TimeBadge(time: jour.entree!),
                if (jour.entree != null && jour.sortie != null) const SizedBox(width: 8),
                if (jour.sortie != null) _TimeBadge(time: jour.sortie!),
              ],
            )
          else
            Text(
              jour.estWeekend ? '' : 'Aucun pointage',
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        DateFormat('H:mm').format(time),
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}