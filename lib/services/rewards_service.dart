import 'package:mukhliss/models/rewards.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class RewardsService {
  final SupabaseClient _client = Supabase.instance.client;

  // Vérifier la connectivité avant toute requête
  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Erreur lors de la vérification de la connectivité: $e');
      return false;
    }
  }

  // Récupérer reward d'un magasin avec vérification de connectivité
  Future<List<Rewards>> getRewardsByMagasin(String magasinId) async {
    print('Attempting to fetch rewards for magasinId: $magasinId');
    
    // Vérifier la connectivité d'abord
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) {
      throw ConnectivityException('Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.');
    }
    
    try {
      if (magasinId.isEmpty) {
        return [];
      }

      final response = await _client
          .from('rewards')
          .select()
          .eq('magasin_id', magasinId)
          .timeout(Duration(seconds: 10)); // Timeout de 10 secondes
          
      if (response.isEmpty) {
        print('No rewards found for magasinId: $magasinId');
        return [];
      }
      
      print('Rewards fetched successfully for magasinId: $magasinId');
      print('Response: ${response.toString()}');
      
      return response.map<Rewards>((json) => Rewards.fromJson(json)).toList();
    } on ConnectivityException {
      rethrow; // Re-lancer l'exception de connectivité
    } catch (e) {
      print('Error fetching rewards: $e');
      // Vérifier si c'est une erreur de réseau
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException') ||
          e.toString().contains('network')) {
        throw ConnectivityException('Problème de connexion réseau. Veuillez réessayer.');
      }
      rethrow;
    }
  }

  // Récupérer les nouveaux rewards avec vérification de connectivité
  Future<List<Rewards>> getRecentRewards() async {
    print('Attempting to fetch recent rewards');
    
    // Vérifier la connectivité d'abord
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) {
      throw ConnectivityException('Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.');
    }
    
    try {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final response = await _client.from('rewards')
        .select('''
          *,
          magasins:magasin_id (*)  // Jointure avec la table magasins
        ''')
        .gte('created_at', oneWeekAgo.toIso8601String())
        .order('created_at', ascending: false)
        .timeout(Duration(seconds: 15)); // Timeout de 15 secondes

      print("Recent rewards response: ${response.toString()}");
      
      if (response == null || response.isEmpty) {
        return [];
      }
      
      return response.map<Rewards>((json) => Rewards.fromJson(json)).toList();
    } on ConnectivityException {
      rethrow; // Re-lancer l'exception de connectivité
    } catch (e) {
      print('Error fetching recent rewards: $e');
      // Vérifier si c'est une erreur de réseau
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException') ||
          e.toString().contains('network')) {
        throw ConnectivityException('Problème de connexion réseau. Veuillez réessayer.');
      }
      rethrow;
    }
  }
}

// Exception personnalisée pour les problèmes de connectivité
class ConnectivityException implements Exception {
  final String message;
  
  ConnectivityException(this.message);
  
  @override
  String toString() => message;
}