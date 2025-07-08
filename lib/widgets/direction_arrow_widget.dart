import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:mukhliss/models/store.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/screen/layout/main_navigation_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/theme/app_theme.dart';

class NavigationArrowWidget extends ConsumerStatefulWidget {
  final Position? currentPosition;
  final Store? selectedShop;
  final bool isNavigating;
  final double? currentBearing;
  final Function() onStopNavigation;
  final Function(Position) onPositionUpdate;
  final Function(Position, double?) updateCameraPosition;

  const NavigationArrowWidget({
    Key? key,
    required this.currentPosition,
    required this.selectedShop,
    required this.isNavigating,
    required this.currentBearing,
    required this.onStopNavigation,
    required this.onPositionUpdate,
    required this.updateCameraPosition,
  }) : super(key: key);

  @override
  ConsumerState<NavigationArrowWidget> createState() => _NavigationArrowWidgetState();
}

class _NavigationArrowWidgetState extends ConsumerState<NavigationArrowWidget> {
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    if (widget.isNavigating) {
      _startPositionUpdates();
    }
  }

  @override
  void didUpdateWidget(NavigationArrowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNavigating && !oldWidget.isNavigating) {
      _startPositionUpdates();
    } else if (!widget.isNavigating && oldWidget.isNavigating) {
      _stopPositionUpdates();
    }
  }

  @override
  void dispose() {
    _stopPositionUpdates();
    super.dispose();
  }

  void _startPositionUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!widget.isNavigating) return;
      _handlePositionUpdate(position);
    });
  }

  void _stopPositionUpdates() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void _handlePositionUpdate(Position newPosition) {
    if (widget.selectedShop == null) {
      debugPrint('No shop selected - cannot calculate bearing');
      return;
    }

    final bearing = Geolocator.bearingBetween(
      newPosition.latitude,
      newPosition.longitude,
      widget.selectedShop!.latitude,
      widget.selectedShop!.longitude,
    );

    widget.onPositionUpdate(newPosition);
    widget.updateCameraPosition(newPosition, bearing);
    _checkArrival(newPosition);
  }

  void _checkArrival(Position position) {
    if (widget.selectedShop == null) return;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.selectedShop!.latitude,
      widget.selectedShop!.longitude,
    );

    if (distance < 50) {
      _showArrivalNotification();
      widget.onStopNavigation();
    }
  }

  void _showArrivalNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vous êtes arrivé à ${widget.selectedShop?.nom_enseigne}'),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  @override
 
  Widget build(BuildContext context) {
     final l10n = AppLocalizations.of(context);
      final themeMode = ref.watch(themeProvider);
      final isDarkMode = themeMode == AppThemeMode.light;
    if (!widget.isNavigating || 
        widget.selectedShop == null || 
        widget.currentPosition == null || 
        widget.currentBearing == null) {
      return const SizedBox.shrink();
    }

    final distance = Geolocator.distanceBetween(
      widget.currentPosition!.latitude,
      widget.currentPosition!.longitude,
      widget.selectedShop!.latitude,
      widget.selectedShop!.longitude,
    );

    return Column(
      children: [
        // Flèche directionnelle
        GestureDetector(
          onTap: widget.onStopNavigation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? AppColors.darkSurface :AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            width: 50,
            height: 50,
            child: Center(
              child: Transform.rotate(
                angle: (widget.currentBearing! * 3.1415926535) / 180,
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Info de distance
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkSurface,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
           l10n!.distance+ ': ${distance < 1000 ? '${distance.toStringAsFixed(0)} m' : '${(distance / 1000).toStringAsFixed(1)} km'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color:isDarkMode ? AppColors.surface : AppColors.darkSurface,
            ),
          ),
        ),
      ],
    );
  }
}