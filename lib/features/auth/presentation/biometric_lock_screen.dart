import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/service/biometric_service.dart';
import '../../shared/logout_action.dart';

/// Écran de verrouillage affiché au démarrage quand un jeton existe et que
/// le téléphone dispose d'un capteur biométrique configuré.
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
      backgroundColor: AppColors.loginBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    size: 60,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Déverrouillage requis',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Confirmez votre identité pour accéder à vos données de pointage.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.textGrey),
                ),
                const SizedBox(height: 28),
                if (_checking)
                  const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.absentText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _tryUnlock,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text(
                        'Déverrouiller',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.gap),
                  // Porte de sortie si la biométrie échoue durablement :
                  // l'employé se déconnecte et se reconnecte avec son
                  // identifiant AD.
                  TextButton(
                    onPressed: () => handleLogout(context),
                    child: const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
