import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/network/network_exceptions.dart';

/// Affiche un message et une icône adaptés au type d'erreur reçu, avec
/// un bouton "Réessayer". Remplace le simple Text(_errorMessage!) utilisé
/// jusqu'ici dans dashboard_body.dart et history_body.dart.
class ErrorStateView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorStateView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    late IconData icon;
    late String message;

    if (error is NoConnectionException) {
      icon = Icons.wifi_off;
      message = 'Pas de connexion internet.\nVérifie ton réseau et réessaie.';
    } else if (error is ServerUnavailableException) {
      icon = Icons.cloud_off;
      message =
          'Le serveur ne répond pas pour le moment.\nRéessaie dans quelques instants.';
    } else {
      icon = Icons.error_outline;
      message =
          'Une erreur est survenue.\nRéessaie, ou contacte le support si ça persiste.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textGrey),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
