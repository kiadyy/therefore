import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../main.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  String? _errorMessage;

  String _heureArrivee = '--:--:--';
  String _heureDepart = '--:--:--';

  double _heureRealisee = 0;
  int _nbRetards = 0;
  int _classement = 0;
  int _totalEmployes = 0;
  double _dureeMoyenneRetardMin = 0;
  double _dureeMoyenneTravailH = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final firstDayOfMonth = DateFormat('yyyy-MM-dd')
          .format(DateTime(DateTime.now().year, DateTime.now().month, 1));

      final pointageToday = await supabase
          .from('pointages')
          .select()
          .eq('employee_id', userId)
          .eq('date', today)
          .maybeSingle();

      final statsMois = await supabase
          .from('v_stats_mensuelles')
          .select()
          .eq('employee_id', userId)
          .eq('mois', firstDayOfMonth)
          .maybeSingle();

      final classementData = await supabase
          .from('v_classement_retards')
          .select()
          .eq('employee_id', userId)
          .eq('mois', firstDayOfMonth)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        if (pointageToday != null) {
          _heureArrivee = pointageToday['heure_arrivee']?.toString() ?? '--:--:--';
          _heureDepart = pointageToday['heure_depart']?.toString() ?? '--:--:--';
        }
        if (statsMois != null) {
          _heureRealisee = (statsMois['heure_realisee_totale'] as num?)?.toDouble() ?? 0;
          _nbRetards = (statsMois['nb_retards'] as num?)?.toInt() ?? 0;
          _dureeMoyenneRetardMin =
              (statsMois['duree_moyenne_retard_min'] as num?)?.toDouble() ?? 0;
          _dureeMoyenneTravailH =
              (statsMois['duree_moyenne_travail_h'] as num?)?.toDouble() ?? 0;
        }
        if (classementData != null) {
          _classement = (classementData['classement'] as num?)?.toInt() ?? 0;
          _totalEmployes = (classementData['total_employes'] as num?)?.toInt() ?? 0;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger les données.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 70,
              color: AppColors.primaryGreen,
              width: double.infinity,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : Padding(
                          // Padding identique sur les 4 côtés pour la symétrie
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
                                        caption: 'Moyenne',
                                        dotColor: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _StatCard(
                                        label: 'HEURE DE DÉPART',
                                        value: _heureDepart,
                                        caption: 'Moyenne',
                                        dotColor: AppColors.success,
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
                                        value: '${_heureRealisee.toStringAsFixed(2)}h',
                                        caption: 'Sur 184h (Jours ouvrables)',
                                        dotColor: AppColors.success,
                                        showProgressBar: true,
                                        progressValue: (_heureRealisee / 184).clamp(0, 1),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _StatCard(
                                        label: 'CLASSEMENT RETARDS',
                                        value: '$_nbRetards retard(s)',
                                        caption: _totalEmployes > 0
                                            ? '${_classement}e sur $_totalEmployes (Département)'
                                            : 'Pas de données',
                                        dotColor: AppColors.warning,
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
                                        value: _formatMinutesToHms(_dureeMoyenneRetardMin),
                                        caption: 'Moyenne',
                                        dotColor: AppColors.success,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _StatCard(
                                        label: 'DURÉE MOYENNE TRAVAIL',
                                        value: _formatMinutesToHms(_dureeMoyenneTravailH * 60),
                                        caption: 'Moyenne',
                                        dotColor: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _BottomButton(
                      icon: Icons.bar_chart,
                      label: 'Statistique',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BottomButton(
                      icon: Icons.calendar_today,
                      label: 'pointage',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color dotColor;
  final bool showProgressBar;
  final double progressValue;

  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.dotColor,
    this.showProgressBar = false,
    this.progressValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight;
        final valueFontSize = (cardHeight * 0.16).clamp(18.0, 30.0);
        final labelFontSize = (cardHeight * 0.075).clamp(9.0, 12.0);
        final captionFontSize = (cardHeight * 0.07).clamp(9.0, 11.0);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardHeight * 0.1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.success, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Icon(Icons.info_outline, size: labelFontSize + 2, color: AppColors.success),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              if (showProgressBar)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 6,
                    backgroundColor: AppColors.fieldGrey,
                    valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  ),
                ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      caption,
                      style: TextStyle(fontSize: captionFontSize, color: AppColors.textGrey),
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

class _BottomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );
  }
}