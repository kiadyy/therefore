import 'pointage_repository.dart';

// ⚠️ SEULE LIGNE À CHANGER quand l'API de l'entreprise sera prête :
// PointageRepository pointageRepository = ApiPointageRepository(dio);
PointageRepository pointageRepository = MockPointageRepository();