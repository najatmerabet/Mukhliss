/// ============================================================
/// Feature: Rewards - Barrel Export
/// ============================================================
///
/// Point d'entrée unique pour la feature rewards.
///
/// Usage:
/// ```dart
/// import 'package:mukhliss/features/rewards/rewards.dart';
/// ```
library;

// ============================================================
// DOMAIN LAYER
// ============================================================

// Entities
export 'domain/entities/reward_entity.dart';

// Repositories
export 'domain/repositories/rewards_repository.dart';

// Use Cases
export 'domain/usecases/rewards_usecases.dart';

// ============================================================
// DATA LAYER
// ============================================================

// Models
export 'data/models/reward_model.dart';

// DataSources
export 'data/datasources/rewards_remote_datasource.dart';

// Repositories
export 'data/repositories/rewards_repository_impl.dart';

// ============================================================
// PRESENTATION LAYER
// ============================================================

// Providers
export 'presentation/providers/rewards_provider.dart';

// Widgets
export 'presentation/widgets/reward_card.dart';

// Screens
export 'presentation/screens/rewards_screen.dart';
