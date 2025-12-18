/// ============================================================
/// Feature: Offers - Barrel Export
/// ============================================================
///
/// Point d'entrée unique pour la feature offers.
///
/// Usage:
/// ```dart
/// import 'package:mukhliss/features/offers/offers.dart';
/// ```
library;

// ============================================================
// DOMAIN LAYER
// ============================================================

// Entities
export 'domain/entities/offer_entity.dart';
export 'domain/entities/claimed_offer_entity.dart';

// Repositories
export 'domain/repositories/offers_repository.dart';

// Use Cases
export 'domain/usecases/offers_usecases.dart';

// ============================================================
// DATA LAYER
// ============================================================

// Services
export 'data/services/offres_service.dart';
export 'data/services/client_offer_service.dart';

// Models
export 'data/models/offer_model.dart';

// ============================================================
// PRESENTATION LAYER
// ============================================================

// Providers
export 'presentation/providers/offers_provider.dart';
export 'presentation/providers/client_offer_provider.dart';

// Widgets
export 'presentation/widgets/offer_card.dart';

// Screens
export 'presentation/screens/offers_screen.dart';
