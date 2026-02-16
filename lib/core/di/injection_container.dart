/// ============================================================
/// Dependency Injection Container
/// ============================================================
///
/// Point central d'initialisation de l'application.
/// Toute la configuration est ici, main.dart reste minimal.
///
/// Usage:
/// ```dart
/// import 'package:mukhliss/core/di/injection_container.dart' as di;
/// await di.init();
/// ```
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../errors/global_error_handler.dart';
import '../services/logo_cache_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Variable globale pour accéder au client Supabase
/// Évite d'appeler Supabase.instance.client partout
late final SupabaseClient supabaseClient;

/// Flag pour éviter double initialisation
bool _initialized = false;

/// Initialise toutes les dépendances de l'application
///
/// Doit être appelé une seule fois au démarrage de l'app
/// Throws [StateError] si appelé plusieurs fois
Future<void> init() async {
  if (_initialized) {
    debugPrint('⚠️ DI already initialized, skipping...');
    return;
  }

  debugPrint('🚀 Initializing dependencies...');

  try {
    // 1. Configuration environnement
    await _initConfig();

    // 2. Services externes (Supabase)
    await _initExternalServices();

    // 3. Gestionnaire d'erreurs global
    _initErrorHandling();

    // 4. Cache des logos
    await _initCacheServices();

    // 5. Push Notifications (OneSignal)
    _initOneSignal();

    _initialized = true;
    debugPrint('✅ All dependencies initialized successfully');
  } catch (e, stack) {
    debugPrint('❌ Failed to initialize dependencies: $e');
    debugPrint('Stack: $stack');
    rethrow;
  }
}

/// Charge les variables d'environnement depuis .env
Future<void> _initConfig() async {
  await dotenv.load(fileName: '.env');

  // Valider que les variables requises sont présentes
  final requiredVars = ['SUPABASE_URL', 'SUPABASE_KEY'];
  for (final varName in requiredVars) {
    if (dotenv.env[varName] == null || dotenv.env[varName]!.isEmpty) {
      throw StateError('Missing required environment variable: $varName');
    }
  }

  debugPrint('📋 Environment loaded (${dotenv.env.length} variables)');
}

/// Initialise Supabase et autres services externes
Future<void> _initExternalServices() async {
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseKey = dotenv.env['SUPABASE_KEY']!;

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      timeout: Duration(seconds: 30),
    ),
  );

  // Stocker la référence globale
  supabaseClient = Supabase.instance.client;

  debugPrint('🔌 Supabase initialized');
  debugPrint('   URL: ${supabaseUrl.substring(0, 30)}...');
}

/// Configure le gestionnaire d'erreurs global
void _initErrorHandling() {
  GlobalErrorHandler.initialize();
  GlobalErrorHandler.setupSupabaseAuthListener();
  debugPrint('🛡️ Error handling configured');
}

/// Initialise les services de cache
Future<void> _initCacheServices() async {
  try {
    await LogoCacheService.instance.initialize();
    debugPrint('📦 Logo cache service initialized');
  } catch (e) {
    debugPrint('⚠️ Logo cache init failed (non-critical): $e');
    // Continue même si le cache échoue
  }
}

/// Initialise OneSignal pour les push notifications
void _initOneSignal() {
  try {
    // Activer le mode verbose en debug
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialiser avec l'App ID OneSignal
    OneSignal.initialize('e51ca46d-b9bf-4600-bb54-873d549d8275');

    // Demander la permission pour les notifications
    OneSignal.Notifications.requestPermission(true);

    debugPrint('🔔 OneSignal initialized');
  } catch (e) {
    debugPrint('⚠️ OneSignal init failed (non-critical): $e');
  }
}

/// Réinitialise le conteneur (utile pour les tests)
@visibleForTesting
void reset() {
  _initialized = false;
  debugPrint('🔄 DI container reset');
}

/// Vérifie si le conteneur est initialisé
bool get isInitialized => _initialized;
