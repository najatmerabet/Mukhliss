import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class QrcodeService {
  final SupabaseClient client = Supabase.instance.client;
  static const String _qrCacheKey = 'cached_qr_data';
  static const String _lastUserIdKey = 'last_user_id';
  final Connectivity _connectivity = Connectivity();

  // Vérifier la connexion internet avec test DNS
  Future<bool> get isConnected async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Test de connectivité réelle avec DNS lookup
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Méthode pour gérer l'authentification avec gestion d'erreur
  Future<User?> _getCurrentUserSafely() async {
    try {
      // Vérifier d'abord la session locale
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      // Vérifier si la session est expirée
      final session = client.auth.currentSession;
      if (session == null || session.expiresAt == null) {
        return null;
      }

      // Vérifier l'expiration
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (session.expiresAt! <= now) {
        // Session expirée, essayer de la rafraîchir seulement si en ligne
        if (await isConnected) {
          try {
            await client.auth.refreshSession();
            return client.auth.currentUser;
          } catch (e) {
            // Impossible de rafraîchir, mais on peut continuer avec les données en cache
            print('Failed to refresh session: $e');
            return currentUser; // Retourner l'utilisateur expiré pour accéder au cache
          }
        }
      }

      return currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      // Retourner null si impossible d'obtenir l'utilisateur
      return null;
    }
  }

  // Récupérer les données du client avec gestion d'erreur améliorée
  Future<Map<String, dynamic>> _getClientData() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Obtenir l'utilisateur de manière sécurisée
      final user = await _getCurrentUserSafely();
      if (user == null) {
        // Pas d'utilisateur, essayer d'utiliser les dernières données en cache
        final cachedData = prefs.getString(_qrCacheKey);
        if (cachedData != null) {
          final data = jsonDecode(cachedData);
          data['_isCached'] = true;
          data['_isOffline'] = true;
          return data;
        }
        throw Exception('User not authenticated and no cached data available');
      }

      // Sauvegarder l'ID utilisateur pour référence future
      await prefs.setString(_lastUserIdKey, user.id);

      // Si pas de connexion, utiliser les données en cache
      if (!await isConnected) {
        final cachedData = prefs.getString(_qrCacheKey);
        if (cachedData != null) {
          final data = jsonDecode(cachedData);
          data['_isCached'] = true;
          data['_isOffline'] = true;
          return data;
        }
        throw Exception('No internet connection and no cached data available');
      }

      // Essayer de récupérer depuis Supabase avec timeout court
      final response = await client
          .from('clients')
          .select()
          .eq('id', user.id)
          .single()
          .timeout(const Duration(seconds: 8)); // Timeout réduit
      
      // Mettre en cache les données avec métadonnées
      response['_isCached'] = false;
      response['_isOffline'] = false;
      response['_lastUpdate'] = DateTime.now().toIso8601String();
      await prefs.setString(_qrCacheKey, jsonEncode(response));
      
      return response;

    } on SocketException catch (e) {
      return _handleFallbackToCache(prefs, 'Network error: ${e.message}');
    } on TimeoutException {
      return _handleFallbackToCache(prefs, 'Request timeout');
    } on PostgrestException catch (e) {
      return _handleFallbackToCache(prefs, 'Database error: ${e.message}');
    } on AuthException catch (e) {
      return _handleFallbackToCache(prefs, 'Authentication error: ${e.message}');
    } catch (e) {
      return _handleFallbackToCache(prefs, 'Unexpected error: $e');
    }
  }

  // Méthode pour gérer le fallback vers le cache
  Future<Map<String, dynamic>> _handleFallbackToCache(
      SharedPreferences prefs, String error) async {
    print('Falling back to cache due to: $error');
    
    final cachedData = prefs.getString(_qrCacheKey);
    if (cachedData != null) {
      final data = jsonDecode(cachedData);
      data['_isCached'] = true;
      data['_isOffline'] = true;
      data['_error'] = error;
      return data;
    }
    
    throw Exception('$error and no cached data available');
  }

  // Créer un QR code pour le client  
  String _getQrCodeData(Map<String, dynamic> clientData) {
    final secureData = {
      'user_id': clientData['id'],
      'nom': clientData['nom'],
      'prenom': clientData['prenom'],
      'email': clientData['email'],
      'address': clientData['adr'],
      'phone': clientData['tel'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'is_cached': clientData['_isCached'] ?? false,
      'is_offline': clientData['_isOffline'] ?? false,
      'version': '1.0'
    };
    return jsonEncode(secureData);
  }
  
  Future<Widget> generateUserQR() async {
    try {
      final userData = await _getClientData();
      final qrData = _getQrCodeData(userData);

      return Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.blue,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
           
           
          ],
        ),
      );
    } catch (e) {
      return _buildErrorWidget(e.toString());
    }
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> getQRDataString() async {
    try {
      final userData = await _getClientData();
      return _getQrCodeData(userData);
    } catch (e) {
      throw Exception('Failed to get QR data: $e');
    }
  }

  // Méthode pour nettoyer le cache si nécessaire
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_qrCacheKey);
    await prefs.remove(_lastUserIdKey);
  }

  // Méthode pour vérifier l'état du cache
  Future<bool> hasCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_qrCacheKey);
  }
}