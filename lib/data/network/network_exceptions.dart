/// Aucune connexion internet disponible sur l'appareil.
class NoConnectionException implements Exception {
  const NoConnectionException();
}

/// Le serveur ne répond pas dans le délai imparti, ou renvoie une erreur
/// serveur (5xx) : problème côté API, pas côté appareil.
class ServerUnavailableException implements Exception {
  final int? statusCode;
  const ServerUnavailableException({this.statusCode});
}