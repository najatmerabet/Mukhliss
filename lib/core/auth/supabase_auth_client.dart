/// ============================================================
/// DEPRECATED - Supabase Auth Client
/// ============================================================
///
/// @deprecated Utiliser features/auth/auth.dart à la place
///
/// Migration:
/// ```dart
/// // Ancien
/// import 'package:mukhliss/core/auth/supabase_auth_client.dart';
///
/// // Nouveau
/// import 'package:mukhliss/features/auth/auth.dart';
/// ```
library;

// Réexporter depuis features/auth pour compatibilité
export 'package:mukhliss/features/auth/data/datasources/auth_remote_datasource.dart'
    show SupabaseAuthClient;
