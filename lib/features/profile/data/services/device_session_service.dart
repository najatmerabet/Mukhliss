import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mukhliss/features/profile/data/models/user_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SessionManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _currentSessionToken;
  Timer? _sessionCheckTimer;

  // Générer un token de session unique
  String _generateSessionToken() {
    final uuid = const Uuid();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${uuid.v4()}_$timestamp';
  }

  // Créer une nouvelle session
  Future<String?> createSession(String deviceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      _currentSessionToken = _generateSessionToken();

      await _supabase.from('user_sessions').insert({
        'user_id': user.id,
        'device_id': deviceId,
        'session_token': _currentSessionToken,
        'is_active': true,
        'force_logout': false,
      });

      // Démarrer la vérification périodique des sessions
      _startSessionCheck();

      debugPrint('🔹 [SessionService] Session créée: $_currentSessionToken');
      return _currentSessionToken;
    } catch (e) {
      debugPrint('❌ [SessionService] Erreur création session: $e');
      return null;
    }
  }

  // Mettre à jour l'activité de la session
  Future<void> updateSessionActivity() async {
    if (_currentSessionToken == null) return;

    try {
      await _supabase
          .from('user_sessions')
          .update({
            'last_activity': DateTime.now().toIso8601String(),
          })
          .eq('session_token', _currentSessionToken!);
    } catch (e) {
      debugPrint('❌ [SessionService] Erreur mise à jour session: $e');
    }
  }

  // Vérifier si la session doit être fermée
  Future<bool> checkForceLogout() async {
    if (_currentSessionToken == null) return false;

    try {
      final session = await _supabase
          .from('user_sessions')
          .select()
          .eq('session_token', _currentSessionToken!)
          .maybeSingle();

      return session?['force_logout'] == true;
    } catch (e) {
      debugPrint('❌ [SessionService] Erreur vérification logout: $e');
      return false;
    }
  }

  // Forcer la déconnexion d'un appareil
  Future<bool> forceLogoutDevice(String deviceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Marquer toutes les sessions de cet appareil pour déconnexion
      await _supabase
          .from('user_sessions')
          .update({
            'force_logout': true,
            'is_active': false,
          })
          .eq('user_id', user.id)
          .eq('device_id', deviceId);

      // Marquer l'appareil comme déconnecté
      await _supabase
          .from('user_devices')
          .update({
            'force_logout': true,
            'logout_requested_at': DateTime.now().toIso8601String(),
            'is_active': false,
          })
          .eq('user_id', user.id)
          .eq('device_id', deviceId);

      debugPrint('🔹 [SessionService] Déconnexion forcée pour appareil: $deviceId');
      return true;
    } catch (e) {
      debugPrint('❌ [SessionService] Erreur déconnexion forcée: $e');
      return false;
    }
  }

  // Obtenir toutes les sessions actives
  Future<List<UserSession>> getActiveSessions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('user_sessions')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('last_activity', ascending: false);

      return response
          .map<UserSession>((session) => UserSession.fromJson(session))
          .toList();
    } catch (e) {
      debugPrint('❌ [SessionService] Erreur récupération sessions: $e');
      return [];
    }
  }

  // Démarrer la vérification périodique des sessions
  void _startSessionCheck() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await updateSessionActivity();
      
      // Vérifier si on doit se déconnecter
      final shouldLogout = await checkForceLogout();
      if (shouldLogout) {
        debugPrint('🔹 [SessionService] Déconnexion forcée détectée');
        await _handleForcedLogout();
      }
    });
  }

  // Gérer la déconnexion forcée
  Future<void> _handleForcedLogout() async {
    try {
      _sessionCheckTimer?.cancel();
      _currentSessionToken = null;
      
      // Déconnecter l'utilisateur
      await _supabase.auth.signOut();
      
      // Rediriger vers l'écran de connexion ou afficher un message
      // Ceci dépend de votre architecture de navigation
    } catch (e) {
      debugPrint('❌ [SessionService] Erreur lors de la déconnexion forcée: $e');
    }
  }

  // Nettoyer les sessions
  void dispose() {
    _sessionCheckTimer?.cancel();
  }
}
