import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_colors.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/shell/presentation/main_shell.dart';


const String supabaseUrl = 'https://hwczpzhtmuoltelopbes.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3Y3pwemh0bXVvbHRlbG9wYmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgxNTM5MjksImV4cCI6MjEwMzcyOTkyOX0.YPWOW9pTN_KVFeA_CYSKCNTrmDm67svFaCRkkBoxP80';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const TherefereApp());
}

// Raccourci pratique utilisé partout dans l'app pour accéder au client Supabase
final supabase = Supabase.instance.client;

class TherefereApp extends StatelessWidget {
  const TherefereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Therefore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
        ),
        fontFamily: 'Jost',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const MainShell(),
      },
    );
  }
}
