/// ============================================================
/// Feature: Stores - Barrel Export
/// ============================================================
///
/// Point d'entrée unique pour la feature stores.
///
/// Usage:
/// ```dart
/// import 'package:mukhliss/features/stores/stores.dart';
/// ```
library;

// ============================================================
// DOMAIN LAYER
// ============================================================

// Entities
export 'domain/entities/store_entity.dart';
export 'domain/entities/category_entity.dart';

// Repositories (interfaces)
export 'domain/repositories/stores_repository.dart';
export 'domain/repositories/categories_repository.dart';

// Use Cases
export 'domain/usecases/get_stores.dart';
export 'domain/usecases/get_categories.dart';

// ============================================================
// DATA LAYER
// ============================================================

// Models
export 'data/models/store_model.dart';
export 'data/models/category_model.dart';

// DataSources
export 'data/datasources/stores_remote_datasource.dart';
export 'data/datasources/categories_remote_datasource.dart';

// Repositories (implementations)
export 'data/repositories/stores_repository_impl.dart';
export 'data/repositories/categories_repository_impl.dart';

// Services
export 'data/services/client_store_service.dart';
export 'data/services/categories_service.dart';

// ============================================================
// PRESENTATION LAYER
// ============================================================

export 'presentation/presentation.dart';
