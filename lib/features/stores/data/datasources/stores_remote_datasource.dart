/// ============================================================
/// Stores Remote DataSource - Data Layer
/// ============================================================
///
/// Source de données distante (Supabase).
/// Optimisée pour gérer des milliers de magasins avec:
/// - Pagination côté serveur
/// - Filtrage géospatial via PostGIS
/// - Calcul de distance côté serveur
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/store_model.dart';

/// Résultat paginé pour les magasins (niveau Data Layer)
class PaginatedStoresDataResult {
  final List<StoreModel> stores;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  
  PaginatedStoresDataResult({
    required this.stores,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  });
  
  bool get hasMore => (currentPage + 1) * pageSize < totalCount;
  int get totalPages => (totalCount / pageSize).ceil();
}


/// Interface pour la source de données distante
abstract class StoresRemoteDataSource {
  Future<List<StoreModel>> getStores();
  Future<StoreModel?> getStoreById(String id);
  Future<List<StoreModel>> searchStores(String query);
  Future<List<StoreModel>> getStoresByCategory(String categoryId);
  
  /// Récupère les magasins dans une zone géographique (viewport)
  Future<List<StoreModel>> getStoresInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  });
  
  /// Récupère les magasins proches triés par distance (via RPC PostGIS)
  Future<List<StoreModel>> getNearbyStoresSorted({
    required double userLat,
    required double userLng,
    int limit = 50,
    double radiusMeters = 50000,
  });
  
  /// Récupère les magasins avec pagination
  Future<PaginatedStoresDataResult> getStoresPaginated({
    int page = 0,
    int pageSize = 20,
    String? categoryId,
    String? searchQuery,
  });
}

/// Implémentation Supabase de la source de données
class StoresRemoteDataSourceImpl implements StoresRemoteDataSource {
  final SupabaseClient _client;

  StoresRemoteDataSourceImpl({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<List<StoreModel>> getStores() async {
    // Limiter le chargement initial pour éviter les problèmes de performance
    final response = await _client
        .from('magasins')
        .select()
        .order('nom_enseigne')
        .limit(100); // Limite pour l'affichage initial

    final stores =
        (response as List).map((json) {
          return StoreModel.fromJson(json);
        }).toList();

    debugPrint('📦 Chargé ${stores.length} magasins (limité à 100)');
    return stores;
  }

  @override
  Future<StoreModel?> getStoreById(String id) async {
    final response =
        await _client.from('magasins').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return StoreModel.fromJson(response);
  }

  @override
  Future<List<StoreModel>> searchStores(String query) async {
    final response = await _client
        .from('magasins')
        .select()
        .ilike('nom_enseigne', '%$query%')
        .limit(30);

    return (response as List).map((json) => StoreModel.fromJson(json)).toList();
  }

  @override
  Future<List<StoreModel>> getStoresByCategory(String categoryId) async {
    final response = await _client
        .from('magasins')
        .select()
        .eq('Categorieid', int.parse(categoryId))
        .order('nom_enseigne')
        .limit(100);

    return (response as List).map((json) => StoreModel.fromJson(json)).toList();
  }

  @override
  Future<List<StoreModel>> getStoresInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    debugPrint('📍 Loading stores in bounds: lat[$minLat-$maxLat] lng[$minLng-$maxLng]');
    
    final response = await _client
        .from('magasins')
        .select()
        .gte('latitude', minLat)
        .lte('latitude', maxLat)
        .gte('longitude', minLng)
        .lte('longitude', maxLng)
        .limit(150); // Limite pour les performances de la carte

    final stores = (response as List).map((json) => StoreModel.fromJson(json)).toList();
    debugPrint('📍 Found ${stores.length} stores in bounds');
    
    return stores;
  }

  @override
  Future<List<StoreModel>> getNearbyStoresSorted({
    required double userLat,
    required double userLng,
    int limit = 50,
    double radiusMeters = 50000,
  }) async {
    debugPrint('📍 Loading nearby stores via RPC from ($userLat, $userLng)');
    
    try {
      // Utiliser la fonction RPC PostGIS pour le calcul côté serveur
      final response = await _client.rpc(
        'get_nearby_stores',
        params: {
          'user_lat': userLat,
          'user_lng': userLng,
          'radius_meters': radiusMeters,
          'max_results': limit,
        },
      );

      final stores = (response as List).map((json) {
        // La RPC retourne aussi distance_meters
        final storeJson = Map<String, dynamic>.from(json);
        return StoreModel.fromJson(storeJson);
      }).toList();
      
      debugPrint('📍 RPC returned ${stores.length} nearby stores');
      return stores;
    } catch (e) {
      debugPrint('⚠️ RPC get_nearby_stores failed: $e, falling back to client-side calculation');
      // Fallback: calcul côté client si la RPC échoue
      return _getNearbyStoresFallback(userLat, userLng, limit);
    }
  }

  /// Fallback pour le calcul de distance côté client
  Future<List<StoreModel>> _getNearbyStoresFallback(
    double userLat,
    double userLng,
    int limit,
  ) async {
    final response = await _client
        .from('magasins')
        .select()
        .limit(500); // Limite pour le fallback

    final stores = (response as List).map((json) => StoreModel.fromJson(json)).toList();
    
    // Trier par distance côté client
    stores.sort((a, b) {
      final distA = _calculateDistance(userLat, userLng, a.latitude, a.longitude);
      final distB = _calculateDistance(userLat, userLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });
    
    return stores.take(limit).toList();
  }

  @override
  Future<PaginatedStoresDataResult> getStoresPaginated({
    int page = 0,
    int pageSize = 20,
    String? categoryId,
    String? searchQuery,
  }) async {
    debugPrint('📦 Loading page $page with pageSize $pageSize');
    
    try {
      // Utiliser la fonction RPC pour la pagination
      final response = await _client.rpc(
        'get_stores_paginated',
        params: {
          'page_number': page,
          'page_size': pageSize,
          if (categoryId != null) 'category_filter': int.parse(categoryId),
          if (searchQuery != null && searchQuery.isNotEmpty) 'search_query': searchQuery,
        },
      );

      final List<Map<String, dynamic>> data = (response as List).cast<Map<String, dynamic>>();
      
      if (data.isEmpty) {
        return PaginatedStoresDataResult(
          stores: [],
          totalCount: 0,
          currentPage: page,
          pageSize: pageSize,
        );
      }

      // Le total_count est retourné dans chaque ligne
      final totalCount = data.first['total_count'] as int? ?? 0;
      
      final stores = data.map((json) {
        final storeJson = Map<String, dynamic>.from(json);
        storeJson.remove('total_count'); // Supprimer le champ ajouté
        return StoreModel.fromJson(storeJson);
      }).toList();

      debugPrint('📦 Page $page: ${stores.length} stores (total: $totalCount)');
      
      return PaginatedStoresDataResult(
        stores: stores,
        totalCount: totalCount,
        currentPage: page,
        pageSize: pageSize,
      );
    } catch (e) {
      debugPrint('⚠️ RPC get_stores_paginated failed: $e, falling back to range query');
      // Fallback: pagination manuelle
      return _getStoresPaginatedFallback(page, pageSize, categoryId, searchQuery);
    }
  }

  /// Fallback pour la pagination manuelle
  Future<PaginatedStoresDataResult> _getStoresPaginatedFallback(
    int page,
    int pageSize,
    String? categoryId,
    String? searchQuery,
  ) async {
    var query = _client.from('magasins').select();
    
    if (categoryId != null) {
      query = query.eq('Categorieid', int.parse(categoryId));
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('nom_enseigne', '%$searchQuery%');
    }
    
    // Compter le total (dans une requête séparée)
    final countQuery = _client.from('magasins').select('id');
    if (categoryId != null) {
      countQuery.eq('Categorieid', int.parse(categoryId));
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      countQuery.ilike('nom_enseigne', '%$searchQuery%');
    }
    final countResponse = await countQuery;
    final totalCount = (countResponse as List).length;
    
    // Récupérer la page
    final response = await query
        .order('nom_enseigne')
        .range(page * pageSize, (page + 1) * pageSize - 1);

    final stores = (response as List).map((json) => StoreModel.fromJson(json)).toList();
    
    return PaginatedStoresDataResult(
      stores: stores,
      totalCount: totalCount,
      currentPage: page,
      pageSize: pageSize,
    );
  }

  /// Calcule la distance en km entre deux points (formule Haversine)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180;
}
