/// Core exports for Mukhliss application.
library;

// ============================================================
// MUKHLISS - Exports Core
// ============================================================
//
// Import unique pour tout le core de l'application:
// ```dart
// import 'package:mukhliss/core/core.dart';
// ```

// Authentification
export 'auth/auth.dart';

// Dependency Injection
export 'di/injection_container.dart';

// Gestion des erreurs
export 'errors/failures.dart';
export 'errors/result.dart';
export 'errors/global_error_handler.dart';

// Logger
export 'logger/app_logger.dart';

// Theme
export 'theme/theme_utils.dart';

// Constantes
export 'constants/app_constants.dart';

// Network
export 'network/api_client.dart';
export 'network/network_providers.dart';

// Storage
export 'storage/local_storage.dart';

// Providers
export 'providers/providers.dart';
