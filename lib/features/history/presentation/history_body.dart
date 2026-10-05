import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/pointage_models.dart';
import '../../../data/repositories/pointage_repository_provider.dart';
import '../../../data/session/session_expired_exception.dart';
import '../../shared/logout_action.dart';
import '../../shared/error_state_view.dart';

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

  Future<void> _loadHistorique() async {
    setState(() {
      _isLoading = true;
      _lastError = null;
    });

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

        jours.add(JourPointage(
            date: d, pointages: pointages, estWeekend: estWeekend));
      }

      jours.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _jours = jours;
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
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: AppColors.primaryGreen),
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
          height: 70,
          color: AppColors.primaryGreen,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: _pickDateRange,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.date_range,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${dateFormat.format(_dateDebut)} → ${dateFormat.format(_dateFin)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
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
                        child: const Icon(Icons.restart_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
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
                  ? ErrorStateView(error: _lastError!, onRetry: _loadHistorique)
                  : _jours.isEmpty
                      ? const Center(
                          child: Text('Aucun pointage sur cette période.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _jours.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _JourCard(jour: _jours[index]),
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
    'LUNDI',
    'MARDI',
    'MERCREDI',
    'JEUDI',
    'VENDREDI',
    'SAMEDI',
    'DIMANCHE'
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
        borderRadius: BorderRadius.circular(25),
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
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: badgeColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(badgeLabel,
                      style: TextStyle(
                          fontSize: 12,
                          color: badgeColor,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          if (jour.pointages.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: jour.pointages.map((h) => _TimeBadge(time: h)).toList(),
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
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
