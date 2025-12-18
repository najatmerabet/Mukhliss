/// ============================================================
/// DEPRECATED - Auth Client Interface
/// ============================================================
///
/// @deprecated Utiliser features/auth/auth.dart à la place
///
/// Migration:
/// ```dart
/// // Ancien
/// import 'package:mukhliss/core/auth/auth_client.dart';
///
/// // Nouveau
/// import 'package:mukhliss/features/auth/auth.dart';
/// ```
library;

// Réexporter depuis features/auth pour compatibilité
export 'package:mukhliss/features/auth/data/datasources/auth_remote_datasource.dart'
    show IAuthClient, SupabaseAuthClient;
export 'package:mukhliss/features/auth/domain/entities/user_entity.dart'
    show AppUser;
