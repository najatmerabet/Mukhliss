/// ============================================================
/// MUKHLISS - Pattern Result (Either)
/// ============================================================
///
/// Utilise ce pattern au lieu de try/catch et return null.
///
/// EXEMPLE:
/// ```dart
/// // Au lieu de:
/// Future<User?> getUser() async {
///   try { return user; } catch (e) { return null; }
/// }
///
/// // Utiliser:
/// Future<Result<User>> getUser() async {
///   try { return Success(user); } catch (e) { return Failure(error); }
/// }
/// ```
library;

import 'failures.dart';

/// Type Result: contient soit un succès (T), soit une erreur (Failure)
sealed class Result<T> {
  const Result();

  /// Crée un résultat de succès
  const factory Result.success(T value) = Success<T>;

  /// Crée un résultat d'échec
  const factory Result.failure(Failure failure) = Error<T>;

  /// Exécute une fonction selon le résultat
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  });

  /// Map: transforme la valeur si succès
  Result<R> map<R>(R Function(T value) transform);

  /// FlatMap: enchaîne avec une autre opération Result
  Result<R> flatMap<R>(Result<R> Function(T value) transform);

  /// Retourne true si succès
  bool get isSuccess;

  /// Retourne true si erreur
  bool get isFailure;

  /// Retourne la valeur ou null
  T? get valueOrNull;

  /// Retourne l'erreur ou null
  Failure? get failureOrNull;

  /// Retourne la valeur ou une valeur par défaut
  T getOrElse(T defaultValue);

  /// Retourne la valeur ou exécute une fonction
  T getOrElseGet(T Function() orElse);
}

/// Résultat de succès
class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) => success(value);

  @override
  Result<R> map<R>(R Function(T value) transform) =>
      Result.success(transform(value));

  @override
  Result<R> flatMap<R>(Result<R> Function(T value) transform) =>
      transform(value);

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  T? get valueOrNull => value;

  @override
  Failure? get failureOrNull => null;

  @override
  T getOrElse(T defaultValue) => value;

  @override
  T getOrElseGet(T Function() orElse) => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Résultat d'erreur
class Error<T> extends Result<T> {
  final Failure failure;

  const Error(this.failure);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) => failure(this.failure);

  @override
  Result<R> map<R>(R Function(T value) transform) => Result.failure(failure);

  @override
  Result<R> flatMap<R>(Result<R> Function(T value) transform) =>
      Result.failure(failure);

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  T? get valueOrNull => null;

  @override
  Failure? get failureOrNull => failure;

  @override
  T getOrElse(T defaultValue) => defaultValue;

  @override
  T getOrElseGet(T Function() orElse) => orElse();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Error($failure)';
}

/// Extensions utiles pour Result
extension ResultExtensions<T> on Result<T> {
  /// Exécute une action si succès (sans retourner de valeur)
  void onSuccess(void Function(T value) action) {
    if (this is Success<T>) {
      action((this as Success<T>).value);
    }
  }

  /// Exécute une action si erreur (sans retourner de valeur)
  void onFailure(void Function(Failure failure) action) {
    if (this is Error<T>) {
      action((this as Error<T>).failure);
    }
  }
}
