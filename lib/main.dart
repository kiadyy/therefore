import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'data/service/session_manager.dart';
import 'data/service/biometric_service.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/biometric_lock_screen.dart';
import 'features/shell/presentation/main_shell.dart';

void main() {
  runApp(const TherefereApp());
}

class TherefereApp extends StatelessWidget {
  const TherefereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Therefore',
      debugShowCheckedModeBanner: false,
      routes: {
        '/dashboard': (context) => MainShell(),
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
        ),
        fontFamily: 'Jost',
      ),
      home: FutureBuilder<_StartupState>(
        future: _resolveStartupState(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final state = snapshot.data!;
          if (!state.loggedIn) return const LoginPage();
          if (state.biometricRequired) {
            return BiometricLockScreen(child: const MainShell());
          }
          return const MainShell();
        },
      ),
    );
  }
}

class _StartupState {
  final bool loggedIn;
  final bool biometricRequired;
  _StartupState({required this.loggedIn, required this.biometricRequired});
}

Future<_StartupState> _resolveStartupState() async {
  final loggedIn = await SessionManager.isLoggedIn();
  if (!loggedIn) {
    return _StartupState(loggedIn: false, biometricRequired: false);
  }

  // Le verrou biométrique n'est activé que si l'appareil le supporte réellement
  // (capteur présent + empreinte/visage déjà enregistré sur ce téléphone).
  final biometricAvailable = await BiometricService.isAvailable();
  return _StartupState(loggedIn: true, biometricRequired: biometricAvailable);
}
