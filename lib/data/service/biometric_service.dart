import 'package:local_auth/local_auth.dart';

/// Encapsule local_auth. Le verrouillage biométrique protège l'ACCÈS à
/// l'application (donnée locale au téléphone) — ça n'a rien à voir avec
/// le système de pointage par empreinte de l'entreprise.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Renvoie true seulement si l'appareil a un capteur biométrique
  /// ET qu'au moins une empreinte/visage y est déjà enregistré.
  /// Sur un appareil sans capteur (ou en test sur navigateur), on renvoie
  /// false pour ne jamais bloquer l'utilisateur inutilement.
  static Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Déclenche l'écran natif du système (empreinte / visage).
  /// Renvoie true si l'utilisateur est authentifié, false sinon
  /// (échec, annulation, ou capteur indisponible).
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Confirmez votre identité pour accéder à Therefore',
        options: const AuthenticationOptions(
          biometricOnly: false, // autorise le repli sur le code PIN du téléphone
          stickyAuth: true, // ne réinitialise pas la demande si l'app passe en arrière-plan
        ),
      );
    } catch (_) {
      return false;
    }
  }
}