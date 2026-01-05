/// ============================================================
/// Guest Mode Provider
/// ============================================================
///
/// Gère l'état du mode invité (navigation sans compte).
/// Requis pour la conformité App Store (Guideline 5.1.1).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clé de stockage pour le mode invité
const String _guestModeKey = 'is_guest_mode';

/// Provider pour le mode invité
final guestModeProvider = StateNotifierProvider<GuestModeNotifier, bool>((ref) {
  return GuestModeNotifier();
});

/// Notifier pour gérer le mode invité
class GuestModeNotifier extends StateNotifier<bool> {
  GuestModeNotifier() : super(false) {
    _loadGuestMode();
  }

  /// Charger l'état du mode invité depuis le stockage
  Future<void> _loadGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_guestModeKey) ?? false;
  }

  /// Activer le mode invité
  Future<void> enableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, true);
    state = true;
  }

  /// Désactiver le mode invité (après connexion)
  Future<void> disableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, false);
    state = false;
  }

  /// Vérifier si l'utilisateur est en mode invité
  bool get isGuestMode => state;
}

/// Provider pour savoir si l'utilisateur peut accéder à une fonctionnalité
/// Retourne true si l'utilisateur est connecté OU est en mode invité
final canAccessAppProvider = Provider<bool>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedForGuestProvider);
  final isGuest = ref.watch(guestModeProvider);
  return isAuthenticated || isGuest;
});

/// Provider simple pour vérifier l'authentification (évite import circulaire)
final isAuthenticatedForGuestProvider = Provider<bool>((ref) {
  // Ce sera mis à jour par le auth provider
  return false;
});
