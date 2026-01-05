/// ============================================================
/// MUKHLISS - Network Layer (High Traffic Ready)
/// ============================================================
///
/// Ce module exporte tous les utilitaires réseau pour gérer le high traffic.
///
/// ## Composants disponibles:
///
/// ### 1. RateLimiter
/// Limite le nombre de requêtes par seconde.
/// ```dart
/// final limiter = RateLimiter(maxRequests: 30);
/// await limiter.acquire();
/// // faire la requête
/// ```
///
/// ### 2. RetryHandler
/// Re-tentatives intelligentes avec exponential backoff.
/// ```dart
/// final result = await RetryHandler.execute(
///   action: () => apiCall(),
///   config: RetryConfig.standard,
/// );
/// ```
///
/// ### 3. CircuitBreaker
/// Protège quand le serveur est surchargé.
/// ```dart
/// final breaker = CircuitBreaker(name: 'api');
/// final result = await breaker.execute(() => apiCall());
/// ```
///
/// ### 4. RequestQueue
/// File d'attente avec priorités.
/// ```dart
/// final result = await queue.add(
///   () => apiCall(),
///   priority: RequestPriority.high,
/// );
/// ```
///
/// ### 5. ResilientClient (Recommandé)
/// Combine tous les patterns ci-dessus.
/// ```dart
/// final result = await GlobalResilientClient.execute(
///   name: 'get-users',
///   action: () => supabase.from('users').select(),
/// );
/// ```
library;

// Export all network utilities
export 'api_client.dart';
export 'circuit_breaker.dart';
export 'network_providers.dart';
export 'rate_limiter.dart';
export 'request_queue.dart';
export 'resilient_client.dart';
export 'retry_handler.dart';
