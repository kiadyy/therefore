import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_colors.dart';
import '../../../data/network/network_exceptions.dart';
import '../../../data/repositories/pointage_repository.dart' show networkGuard;
import '../../../data/service/session_manager.dart';

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
      final url = Uri.parse(
          'https://therefore.inviso-group.mg/theservice/v0001/restun/GetJWTToken');
      final username = _idController.text.trim();
      final password = _passwordController.text;

      final identifiant = 'SMTP-GROUP\\$username';
      final credentials = base64Encode(utf8.encode('$identifiant:$password'));

      final responseTherefore = await networkGuard(() => http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Basic $credentials',
            },
            body: jsonEncode({}),
          ));

      if (responseTherefore.statusCode == 200) {
        final data = jsonDecode(responseTherefore.body);
        final token = data['JWTToken'];

        // Sans jeton, on ne doit jamais entrer dans l'application :
        // toutes les requêtes suivantes échoueraient en 401.
        if (token == null || token.toString().isEmpty) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Réponse inattendue du serveur, réessaie.';
          });
          return;
        }

        await SessionManager.saveSession(token.toString(), username: username);

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Identifiant ou mot de passe incorrect.';
        });
      }
    } on NoConnectionException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Pas de connexion internet. Vérifie ton réseau.';
      });
    } on ServerUnavailableException catch (e) {
      if (!mounted) return;
      setState(() {
        // Le serveur a répondu avec un code 5xx : c'est ce qu'il renvoie
        // quand l'authentification est refusée, on garde donc le message
        // d'avant. Sans code (délai dépassé), le serveur ne répond vraiment pas.
        _errorMessage = e.statusCode != null
            ? 'Identifiant ou mot de passe incorrect.'
            : 'Le serveur ne répond pas. Réessaie dans quelques instants.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Une erreur est survenue, réessaie.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
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
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildTextField(
                          controller: _idController,
                          hint: 'Identifiant AD',
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
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 32),
                        Align(
                          alignment: Alignment.center,
                          child: FractionallySizedBox(
                            widthFactor:
                                0.7, // 70% de la largeur disponible — ajuste ce chiffre
                            child: _buildLoginButton(),
                          ),
                        ),
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
        SizedBox(
          width: double
              .infinity, // même largeur que les champs (qui prennent toute la largeur dispo)
          child: Image.asset(
            'assets/images/logo_therefore.PNG',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Text(
              'Therefore',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.textGrey,
              ),
            ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
