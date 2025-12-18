/// Client réseau pour Mukhliss.
library;

// ============================================================
// MUKHLISS - Client Réseau
// ============================================================
//
// Wrapper autour de SupabaseClient pour centraliser les appels API.
// Gère automatiquement les erreurs, le logging et la conversion.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/failures.dart';
import '../errors/result.dart';
import '../logger/app_logger.dart';

/// Client API centralisé pour toutes les requêtes Supabase
class ApiClient {
  final SupabaseClient _client;

  ApiClient({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Accès direct au client Supabase si nécessaire
  SupabaseClient get supabase => _client;

  // ============================================================
  // REQUÊTES SELECT
  // ============================================================

  /// Récupère une liste d'éléments d'une table
  Future<Result<List<Map<String, dynamic>>>> getAll(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      AppLogger.network('GET $table');

      // Construction de la requête de base
      PostgrestFilterBuilder query = _client.from(table).select(select ?? '*');

      // Appliquer les filtres
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      // Exécution avec options
      List<dynamic> response;
      if (orderBy != null && limit != null) {
        response = await query
            .order(orderBy, ascending: ascending)
            .limit(limit);
      } else if (orderBy != null) {
        response = await query.order(orderBy, ascending: ascending);
      } else if (limit != null) {
        response = await query.limit(limit);
      } else {
        response = await query;
      }

      AppLogger.network('GET $table → ${response.length} résultats');
      return Result.success(List<Map<String, dynamic>>.from(response));
    } on PostgrestException catch (e) {
      AppLogger.network('Erreur GET $table', level: LogLevel.error, error: e);
      return Result.failure(_mapPostgrestException(e));
    } catch (e) {
      AppLogger.network(
        'Erreur inattendue GET $table',
        level: LogLevel.error,
        error: e,
      );
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  /// Récupère un élément par ID
  Future<Result<Map<String, dynamic>>> getById(
    String table,
    String id, {
    String? select,
    String idColumn = 'id',
  }) async {
    try {
      AppLogger.network('GET $table/$id');

      final response =
          await _client
              .from(table)
              .select(select ?? '*')
              .eq(idColumn, id)
              .maybeSingle();

      if (response == null) {
        return Result.failure(NotFoundFailure('$table avec id=$id non trouvé'));
      }

      return Result.success(response);
    } on PostgrestException catch (e) {
      return Result.failure(_mapPostgrestException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  /// Récupère le premier élément correspondant aux filtres
  Future<Result<Map<String, dynamic>?>> getFirst(
    String table, {
    String? select,
    required Map<String, dynamic> filters,
  }) async {
    try {
      PostgrestFilterBuilder query = _client.from(table).select(select ?? '*');

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      final response = await query.maybeSingle();
      return Result.success(response);
    } on PostgrestException catch (e) {
      return Result.failure(_mapPostgrestException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  // ============================================================
  // REQUÊTES INSERT
  // ============================================================

  /// Insère un nouvel élément
  Future<Result<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.network('INSERT $table');

      final response = await _client.from(table).insert(data).select().single();

      AppLogger.network('INSERT $table → succès');
      return Result.success(response);
    } on PostgrestException catch (e) {
      AppLogger.network(
        'Erreur INSERT $table',
        level: LogLevel.error,
        error: e,
      );
      return Result.failure(_mapPostgrestException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  /// Insère plusieurs éléments
  Future<Result<List<Map<String, dynamic>>>> insertMany(
    String table,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      AppLogger.network('INSERT MANY $table (${data.length} éléments)');

      final response = await _client.from(table).insert(data).select();

      return Result.success(List<Map<String, dynamic>>.from(response));
    } on PostgrestException catch (e) {
      return Result.failure(_mapPostgrestException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  // ============================================================
  // REQUÊTES UPDATE
  // ============================================================

  /// Met à jour un élément par ID
  Future<Result<Map<String, dynamic>>> update(
    String table,
    String id,
    Map<String, dynamic> data, {
    String idColumn = 'id',
  }) async {
    try {
      AppLogger.network('UPDATE $table/$id');

      final response =
          await _client
              .from(table)
              .update(data)
              .eq(idColumn, id)
              .select()
              .single();

      AppLogger.network('UPDATE $table/$id → succès');
      return Result.success(response);
    } on PostgrestException catch (e) {
      AppLogger.network(
        'Erreur UPDATE $table',
        level: LogLevel.error,
        error: e,
      );
      return Result.failure(_mapPostgrestException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  /// Met à jour plusieurs éléments avec des filtres
  Future<Result<List<Map<String, dynamic>>>> updateWhere(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      PostgrestFilterBuilder query = _client.from(table).update(data);

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      final response = await query.select();
      return Result.success(List<Map<String, dynamic>>.from(response));
    } on PostgrestException catch (e) {
      return Result.failure(_mapPostgrestException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  // ============================================================
  // REQUÊTES DELETE
  // ============================================================

  /// Supprime un élément par ID
  Future<Result<void>> delete(
    String table,
    String id, {
    String idColumn = 'id',
  }) async {
    try {
      AppLogger.network('DELETE $table/$id');

      await _client.from(table).delete().eq(idColumn, id);

      AppLogger.network('DELETE $table/$id → succès');
      return const Result.success(null);
    } on PostgrestException catch (e) {
      AppLogger.network(
        'Erreur DELETE $table',
        level: LogLevel.error,
        error: e,
      );
      return Result.failure(_mapPostgrestException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  /// Supprime plusieurs éléments avec des filtres
  Future<Result<void>> deleteWhere(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      PostgrestFilterBuilder query = _client.from(table).delete();

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      await query;
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(_mapPostgrestException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  // ============================================================
  // REQUÊTES RPC
  // ============================================================

  /// Appelle une fonction RPC Supabase
  Future<Result<T>> rpc<T>(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    try {
      AppLogger.network('RPC $functionName');

      final response = await _client.rpc(functionName, params: params);

      return Result.success(response as T);
    } on PostgrestException catch (e) {
      AppLogger.network(
        'Erreur RPC $functionName',
        level: LogLevel.error,
        error: e,
      );
      return Result.failure(_mapPostgrestException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Convertit une PostgrestException en Failure
  Failure _mapPostgrestException(PostgrestException e) {
    final code = e.code;

    if (code == '23505') {
      return ValidationFailure('Cet élément existe déjà');
    }
    if (code == '23503') {
      return ValidationFailure('Référence invalide');
    }
    if (code == '42501') {
      return UnauthorizedFailure('Action non autorisée');
    }
    if (code == 'PGRST116') {
      return NotFoundFailure('Élément non trouvé');
    }

    return ServerFailure(e.message);
  }
}
