import 'package:mukhliss/core/logger/app_logger.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class GeolocationService {
  Position? _lastPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamController<Position>? _currentController;

  Future<Position> determinePosition() async {
    // Gérer les permissions d'abord
    await handleLocationPermissions();

    try {
      // 1. Tenter d'obtenir la position actuelle avec une précision haute
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      AppLogger.debug('Échec de la haute précision ou timeout: $e. Essai avec précision moyenne...');
      
      try {
        // 2. Tenter avec une précision moyenne si la haute échoue (plus rapide en intérieur)
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e2) {
        AppLogger.debug('Échec de la précision moyenne: $e2. Récupération de la dernière position connue...');
        
        // 3. En dernier recours, essayer d'obtenir la dernière position connue
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          AppLogger.debug('Dernière position connue récupérée avec succès.');
          return lastKnown;
        }
        
        // Si tout échoue, on lance une exception explicative
        if (e is TimeoutException) {
          throw Exception('Le délai d\'attente est dépassé. Assurez-vous d\'être dans un endroit dégagé ou que votre GPS est bien activé.');
        }
        throw Exception('Impossible d\'obtenir la position: $e');
      }
    }
  }

   Stream<Position> trackPositionWithThreshold({
    double distanceThreshold = 0.2,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async* {
    try {
      // Vérifier les permissions avant de commencer le tracking
      await handleLocationPermissions();
      
      // Nettoyer les ressources existantes
      _cleanup();
      
      // Réinitialiser la dernière position
      _lastPosition = null;
      
      // Obtenir une position initiale
      try {
        final initialPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
          timeLimit: const Duration(seconds: 15),
        );
        _lastPosition = initialPosition;
        yield initialPosition;
      } catch (e) {
        AppLogger.debug('Erreur lors de l\'obtention de la position initiale: $e. Tentative avec la dernière position connue...');
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _lastPosition = lastKnown;
          yield lastKnown;
        }
      }

      // Créer le stream de positions
      await for (Position newPosition in Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: 0, // On gère le filtre nous-mêmes
          timeLimit: Duration(seconds: 60), // Timeout pour chaque position
        ),
      )) {
        if (_shouldUpdatePosition(newPosition, distanceThreshold)) {
          _lastPosition = newPosition;
          yield newPosition;
        }
      }
    } catch (e) {
      AppLogger.debug('Erreur dans trackPositionWithThreshold: $e');
      throw Exception('Erreur de tracking: $e');
    }
  }

 bool _shouldUpdatePosition(Position newPosition, double threshold) {
    // Si c'est la première position, on l'accepte
    if (_lastPosition == null) return true;
    
    // Calcule la distance depuis la dernière position
    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    
    AppLogger.debug('Distance calculée: ${distance.toStringAsFixed(2)}m (seuil: ${threshold}m)');
    
    // Mise à jour seulement si le seuil est dépassé
    return distance >= threshold;
  }



  // Méthode pour obtenir une position unique avec timeout
  Future<Position> getCurrentPositionWithTimeout({
    Duration timeout = const Duration(seconds: 15),
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout,
      );
    } catch (e) {
      AppLogger.debug('Erreur lors de l\'obtention de la position: $e');
      rethrow;
    }
  }

  // Méthode pour vérifier les permissions
  Future<LocationPermission> checkPermissions() async {
    return await Geolocator.checkPermission();
  }

  // Méthode pour demander les permissions
  Future<LocationPermission> requestPermissions() async {
    return await Geolocator.requestPermission();
  }

  // Méthode pour vérifier si les services de localisation sont activés
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<bool> handleLocationPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si les services de localisation sont activés
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Les services de localisation sont désactivés. Veuillez les activer dans les paramètres.');
    }

    // Vérifier les permissions actuelles
    permission = await Geolocator.checkPermission();
    AppLogger.debug('Permission actuelle: $permission');

    if (permission == LocationPermission.denied) {
      // Demander les permissions
      permission = await Geolocator.requestPermission();
      AppLogger.debug('Permission après demande: $permission');
      
      if (permission == LocationPermission.denied) {
        throw Exception('Les permissions de localisation ont été refusées.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Les permissions de localisation sont refusées définitivement. Veuillez les activer manuellement dans les paramètres de l\'application.');
    }

    return true;
  }

void _cleanup() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    
    if (_currentController != null && !_currentController!.isClosed) {
      _currentController!.close();
    }
    _currentController = null;
  }

  // Méthode pour arrêter le tracking actuel
  void stopTracking() {
    _cleanup();
  }

  // Dispose de toutes les ressources
  void dispose() {
    _cleanup();
    _lastPosition = null;
  }

  // Méthode pour ouvrir les paramètres de localisation
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Méthode pour ouvrir les paramètres de l'application
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // Méthode pour obtenir le statut détaillé des permissions
  Future<Map<String, dynamic>> getLocationStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    
    return {
      'serviceEnabled': serviceEnabled,
      'permission': permission.toString(),
      'canRequest': permission == LocationPermission.denied,
      'needsManualAction': permission == LocationPermission.deniedForever,
    };
  }

  // Méthode utilitaire pour obtenir une description lisible de la permission
  String getPermissionDescription(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Permission refusée - peut être demandée à nouveau';
      case LocationPermission.deniedForever:
        return 'Permission refusée définitivement - activation manuelle requise';
      case LocationPermission.whileInUse:
        return 'Permission accordée pendant l\'utilisation';
      case LocationPermission.always:
        return 'Permission accordée en permanence';
      default:
        return 'Statut de permission inconnu';
    }
  }
}