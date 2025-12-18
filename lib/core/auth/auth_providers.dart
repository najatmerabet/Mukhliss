/// ============================================================
/// DEPRECATED - Auth Providers
/// ============================================================
///
/// @deprecated Utiliser features/auth/auth.dart à la place
///
/// Migration:
/// ```dart
/// // Ancien
/// import 'package:mukhliss/core/auth/auth_providers.dart';
///
/// // Nouveau
/// import 'package:mukhliss/features/auth/auth.dart';
/// ```
library;

// Réexporter depuis features/auth pour compatibilité
export 'package:mukhliss/features/auth/presentation/providers/auth_providers.dart';
