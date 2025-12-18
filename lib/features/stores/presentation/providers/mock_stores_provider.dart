/// ============================================================
/// Mock Stores Provider - Pour Tests de Charge
/// ============================================================
/// 
/// Génère des milliers de magasins fake pour tester les performances
/// sans affecter la base de données Supabase.
library;

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/store_entity.dart';

/// Active/désactive le mode test avec mock data
/// ⚠️ METTRE À TRUE POUR TESTER LES PERFORMANCES
/// ⚠️ METTRE À FALSE EN PRODUCTION
const bool useMockStores = false; // false = Production, true = STRESS TEST
const int mockStoreCount = 50000; // Nombre de magasins pour le test


/// Provider pour le mode test
final mockModeProvider = StateProvider<bool>((ref) => useMockStores);

/// Provider pour les magasins mockés
final mockStoresProvider = FutureProvider<List<StoreEntity>>((ref) async {
  final useMock = ref.watch(mockModeProvider);
  if (!useMock) return [];
  
  // Simuler un délai réseau
  await Future.delayed(const Duration(milliseconds: 500));
  
  return _generateMockStores(mockStoreCount);
});

/// Génère N magasins de test autour d'une position
List<StoreEntity> _generateMockStores(int count) {
  final random = Random(42); // Seed fixe pour résultats reproductibles
  final stores = <StoreEntity>[];
  
  // Centre: Rabat, Maroc
  const centerLat = 33.9716;
  const centerLng = -6.8498;
  
  // Catégories de test
  const categories = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  const categoryNames = [
    'Restaurant', 'Café', 'Supermarché', 'Pharmacie', 'Station',
    'Banque', 'Hotel', 'Boutique', 'Boulangerie', 'Sport'
  ];
  
  for (int i = 0; i < count; i++) {
    // Position aléatoire dans un rayon de ~20km
    final lat = centerLat + (random.nextDouble() - 0.5) * 0.4;
    final lng = centerLng + (random.nextDouble() - 0.5) * 0.4;
    
    final categoryIndex = i % categories.length;
    
    stores.add(StoreEntity(
      id: 'mock_$i',
      name: '${categoryNames[categoryIndex]} Test $i',
      address: 'Rue Test $i, Rabat 10000',
      phone: '+212600${i.toString().padLeft(6, '0')}',
      description: 'Magasin de test #$i pour stress testing',
      latitude: lat,
      longitude: lng,
      categoryId: categories[categoryIndex],
      logoUrl: null,
      createdAt: DateTime.now(),
    ));
  }
  
  return stores;
}

/// Provider combiné: Mock OU Supabase selon le mode
final combinedStoresProvider = Provider<AsyncValue<List<StoreEntity>>>((ref) {
  final useMock = ref.watch(mockModeProvider);
  
  if (useMock) {
    return ref.watch(mockStoresProvider);
  }
  
  // Import normal des stores depuis Supabase si mock désactivé
  // Ce provider doit être utilisé à la place de storesProvider
  return const AsyncValue.loading();
});

/// Statistiques de performance
class PerformanceStats {
  final int totalStores;
  final int visibleStores;
  final int clusters;
  final double loadTimeMs;
  final double renderTimeMs;
  
  const PerformanceStats({
    required this.totalStores,
    required this.visibleStores,
    required this.clusters,
    required this.loadTimeMs,
    required this.renderTimeMs,
  });
  
  @override
  String toString() => '''
📊 Performance Stats:
   Total: $totalStores stores
   Visible: $visibleStores stores  
   Clusters: $clusters
   Load: ${loadTimeMs.toStringAsFixed(1)}ms
   Render: ${renderTimeMs.toStringAsFixed(1)}ms
''';
}

/// Provider pour les stats de performance
final performanceStatsProvider = StateProvider<PerformanceStats?>((ref) => null);
