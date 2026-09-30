import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/service/biometric_service.dart';

class BiometricLockScreen extends StatefulWidget {
  final Widget child; // l'écran à afficher une fois déverrouillé (MainShell)

  const BiometricLockScreen({super.key, required this.child});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _unlocked = false;
  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryUnlock();
  }

  Future<void> _tryUnlock() async {
    setState(() {
      _checking = true;
      _error = null;
    });

    final success = await BiometricService.authenticate();

    if (!mounted) return;
    setState(() {
      _unlocked = success;
      _checking = false;
      _error = success ? null : 'Authentification annulée ou échouée.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fingerprint, size: 72, color: AppColors.primaryGreen),
              const SizedBox(height: 20),
              const Text(
                'Déverrouillage requis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              if (_checking)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: CircularProgressIndicator(),
                )
              else ...[
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ),
                ElevatedButton.icon(
                  onPressed: _tryUnlock,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}