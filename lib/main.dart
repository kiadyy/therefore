import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'data/service/session_manager.dart';
import 'features/auth/presentation/login_page.dart';
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
      home: FutureBuilder<bool>(
        future: SessionManager.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Le matricule n'est pas utilisé par les appels API (le backend
          // identifie l'utilisateur via le token), donc une valeur fixe suffit ici.
          final bool connecte = snapshot.data ?? false;
          return connecte ? const MainShell() : const LoginPage();
        },
      ),
    );
  }
}