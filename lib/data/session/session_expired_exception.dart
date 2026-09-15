/// Levée par les repositories (API) quand le serveur répond que le token
/// est invalide ou expiré (typiquement une erreur HTTP 401).
/// Capturée au niveau des écrans pour déclencher une déconnexion automatique.
class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException([this.message = 'Session expirée']);

  @override
  String toString() => message;
}