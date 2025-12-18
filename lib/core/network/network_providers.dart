/// Providers réseau pour Mukhliss.
library;

// ============================================================
// MUKHLISS - Providers Network
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Provider pour le client API
///
/// Utilisation:
/// ```dart
/// final api = ref.read(apiClientProvider);
/// final result = await api.getAll('clients');
/// ```
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
