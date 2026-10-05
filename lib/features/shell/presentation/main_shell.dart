import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  DashboardBody(matricule: widget.matricule),
                  HistoryBody(matricule: widget.matricule),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      icon: Icons.bar_chart,
                      label: 'Statistique',
                      isActive: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TabButton(
                      icon: Icons.calendar_today,
                      label: 'pointage',
                      isActive: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
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

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isActive ? null : onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isActive ? AppColors.accentLime : AppColors.primaryGreen,
          disabledBackgroundColor: AppColors.accentLime,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );
  }
}
