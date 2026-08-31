Set-Location -Path $PSScriptRoot

Write-Host "Création des dossiers..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "lib\core\constants" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\auth\presentation" | Out-Null
New-Item -ItemType Directory -Force -Path "assets\images" | Out-Null
New-Item -ItemType Directory -Force -Path "assets\icons" | Out-Null
New-Item -ItemType File -Force -Path "assets\images\.gitkeep" | Out-Null
New-Item -ItemType File -Force -Path "assets\icons\.gitkeep" | Out-Null

Write-Host "Écriture de lib/core/constants/app_colors.dart..." -ForegroundColor Cyan
@'
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryGreen = Color(0xFF1B7A1B);
  static const Color accentLime = Color(0xFFA6CE39);
  static const Color backgroundLight = Color(0xFFF4F4F4);
  static const Color fieldGrey = Color(0xFFD9DCE1);
  static const Color textDark = Color(0xFF3C3C3C);
  static const Color textGrey = Color(0xFF7A7A7A);
  static const Color success = Color(0xFF2E9E3D);
  static const Color warning = Color(0xFFE8A33D);
  static const Color cardBorder = Color(0xFFE3E3E3);
  static const Color white = Color(0xFFFFFFFF);
}
'@ | Set-Content -Path "lib\core\constants\app_colors.dart" -Encoding utf8

Write-Host "Écriture de lib/features/auth/presentation/login_page.dart..." -ForegroundColor Cyan
@'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      setState(() {
        _errorMessage = "Identifiant ou mot de passe incorrect.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),
                        _buildLogo(),
                        const Spacer(flex: 2),
                        const Text(
                          'Authentification',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildTextField(
                          controller: _idController,
                          hint: 'Identifiant ID',
                          obscure: false,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Mot de passe',
                          obscure: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textGrey,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 32),
                        _buildLoginButton(),
                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo_therefore.png',
          height: 60,
          errorBuilder: (context, error, stackTrace) => const Text(
            'Therefore',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'PEOPLE   PROCESS   INFORMATION',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.2,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: TextInputAction.next,
      inputFormatters: hint.contains('Identifiant')
          ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
          : null,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Champ requis';
        }
        return null;
      },
      style: const TextStyle(color: AppColors.textDark, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textGrey),
        filled: true,
        fillColor: AppColors.fieldGrey,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentLime,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Se connecter',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
'@ | Set-Content -Path "lib\features\auth\presentation\login_page.dart" -Encoding utf8

Write-Host "Écriture de lib/main.dart..." -ForegroundColor Cyan
@'
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'features/auth/presentation/login_page.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
        ),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
'@ | Set-Content -Path "lib\main.dart" -Encoding utf8

Write-Host "Terminé ! Structure recréée avec succès." -ForegroundColor Green
Write-Host "Lance maintenant : flutter pub get" -ForegroundColor Yellow
Write-Host "Puis : flutter run -d chrome" -ForegroundColor Yellow
