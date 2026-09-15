import 'package:flutter/material.dart';

import '../../data/service/session_manager.dart';
import '../auth/presentation/login_page.dart';

/// Déconnexion MANUELLE (avec confirmation), déclenchée par l'utilisateur
/// via le bouton dans les bandeaux verts.
Future<void> handleLogout(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Se déconnecter'),
      content: const Text('Voulez-vous vraiment vous déconnecter ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  await SessionManager.clearSession();

  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

/// Déconnexion AUTOMATIQUE (pas de confirmation), déclenchée quand l'API
/// détecte un token invalide ou expiré (401).
Future<void> forceLogout(BuildContext context) async {
  await SessionManager.clearSession();

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Votre session a expiré. Veuillez vous reconnecter.')),
  );

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

/// Même style visuel que les autres boutons ronds des bandeaux verts.
class LogoutIconButton extends StatelessWidget {
  const LogoutIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => handleLogout(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.logout, color: Colors.white, size: 20),
      ),
    );
  }
}