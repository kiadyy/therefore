import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gère la persistance de la session (matricule / futur token) de façon
/// chiffrée sur l'appareil. Utilisé pour rester connecté entre deux ouvertures
/// de l'app, et pour tout effacer en cas de déconnexion ou d'erreur 401.
class SessionManager {
  static const _keyMatricule = 'session_matricule';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveSession(String matricule) =>
      _storage.write(key: _keyMatricule, value: matricule);

  Future<String?> getMatricule() => _storage.read(key: _keyMatricule);

  /// À appeler à la déconnexion manuelle, ET automatiquement si l'API renvoie
  /// une erreur 401 (session expirée côté serveur) — voir le TODO dans
  /// ApiPointageRepository une fois branché.
  Future<void> clearSession() => _storage.delete(key: _keyMatricule);
}

final sessionManager = SessionManager();