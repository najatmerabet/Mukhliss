/// ============================================================
/// Feature: Auth - Barrel Export
/// ============================================================
///
/// Point d'entrée unique pour tout ce qui concerne l'authentification.
///
/// Usage:
/// ```dart
/// import 'package:mukhliss/features/auth/auth.dart';
/// ```
library;

// ============================================================
// DOMAIN LAYER
// ============================================================

// Entities
export 'domain/entities/user_entity.dart';
export 'domain/entities/auth_types.dart';

// Use Cases
export 'domain/usecases/auth_usecases.dart';

// ============================================================
// DATA LAYER
// ============================================================

// DataSources (interface + implémentation)
export 'data/datasources/auth_remote_datasource.dart';

// ============================================================
// PRESENTATION LAYER
// ============================================================

// Providers
export 'presentation/providers/auth_providers.dart';

// Screens
export 'presentation/screens/auth_screens.dart';

// Widgets
export 'presentation/widgets/auth_widgets.dart';

// ============================================================
// CORE (re-exports pour compatibilité)
// ============================================================

// Errors
export 'package:mukhliss/core/errors/failures.dart';
export 'package:mukhliss/core/errors/result.dart';
