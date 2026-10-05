import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_colors.dart';
import '../../../data/network/network_exceptions.dart';
import '../../../data/repositories/pointage_repository.dart' show networkGuard;
import '../../../data/service/session_manager.dart';

/// Version affichée en bas de l'écran (à garder identique à pubspec.yaml).
const String _versionApp = '1.0.0';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
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
        'https://therefore.inviso-group.mg/theservice/v0001/restun/GetJWTToken',
      );
      final username = _idController.text.trim();
      final password = _passwordController.text;

      final identifiant = 'SMTP-GROUP\\$username';
      final credentials = base64Encode(utf8.encode('$identifiant:$password'));

      final responseTherefore = await networkGuard(
        () => http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Basic $credentials',
          },
          body: jsonEncode({}),
        ),
      );

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
      backgroundColor: AppColors.loginBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 2),
                          _buildLogo(),
                          const SizedBox(height: 48),
                          const Text(
                            'Authentification',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _ChampSaisie(
                            libelle: 'Identifiant AD',
                            indication: 'Votre identifiant AD',
                            controller: _idController,
                            icone: Icons.person_outline_rounded,
                            autofill: AutofillHints.username,
                            action: TextInputAction.next,
                            sansEspaces: true,
                            onValider: (_) => _passwordFocus.requestFocus(),
                          ),
                          const SizedBox(height: 18),
                          _ChampSaisie(
                            libelle: 'Mot de passe',
                            indication: 'Votre mot de passe',
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            icone: Icons.lock_outline_rounded,
                            autofill: AutofillHints.password,
                            masque: _obscurePassword,
                            action: TextInputAction.done,
                            // La touche Entrée du clavier lance la connexion
                            onValider: (_) {
                              if (!_isLoading) _handleLogin();
                            },
                            suffixe: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Afficher le mot de passe'
                                  : 'Masquer le mot de passe',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textGrey,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: AppColors.absentText,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.absentText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 28),
                          _buildLoginButton(),
                          const Spacer(flex: 3),
                          const Padding(
                            padding: EdgeInsets.only(top: 24, bottom: 16),
                            child: Text(
                              'Therefore · version $_versionApp',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
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
    return Image.asset(
      'assets/images/logo_therefore.PNG',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Text(
        'Therefore',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: AppColors.textGrey,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryGreen,
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

/// Champ de saisie de l'écran de connexion : libellé au-dessus, icône à
/// gauche, bordure verte quand le champ est actif.
class _ChampSaisie extends StatelessWidget {
  final String libelle;
  final String indication;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final IconData icone;
  final String autofill;
  final bool masque;
  final bool sansEspaces;
  final TextInputAction action;
  final ValueChanged<String> onValider;
  final Widget? suffixe;

  const _ChampSaisie({
    required this.libelle,
    required this.indication,
    required this.controller,
    this.focusNode,
    required this.icone,
    required this.autofill,
    this.masque = false,
    this.sansEspaces = false,
    required this.action,
    required this.onValider,
    this.suffixe,
  });

  OutlineInputBorder _bordure(Color couleur, double epaisseur) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: couleur, width: epaisseur),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          libelle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: masque,
          textInputAction: action,
          onFieldSubmitted: onValider,
          autofillHints: [autofill],
          inputFormatters: sansEspaces
              ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
              : null,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Champ requis';
            }
            return null;
          },
          style: const TextStyle(color: AppColors.textDark, fontSize: 16),
          decoration: InputDecoration(
            hintText: indication,
            hintStyle: const TextStyle(color: AppColors.textGrey),
            filled: true,
            fillColor: AppColors.white,
            prefixIcon: Icon(icone),
            prefixIconColor: WidgetStateColor.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? AppColors.primaryGreen
                  : AppColors.textGrey,
            ),
            suffixIcon: suffixe,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: _bordure(AppColors.fieldGrey, 1),
            enabledBorder: _bordure(AppColors.fieldGrey, 1),
            focusedBorder: _bordure(AppColors.primaryGreen, 2),
            errorBorder: _bordure(AppColors.absentText, 1),
            focusedErrorBorder: _bordure(AppColors.absentText, 2),
            errorStyle: const TextStyle(color: AppColors.absentText),
          ),
        ),
      ],
    );
  }
}
