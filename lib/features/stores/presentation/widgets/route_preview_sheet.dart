/// ============================================================
/// Route Preview Sheet - Style Google Maps
/// ============================================================
///
/// Bottom sheet pour prévisualiser et lancer la navigation
/// avec sélection du mode de transport style Google Maps.
library;

import 'package:flutter/material.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import '../../domain/entities/store_entity.dart';
import 'package:mukhliss/features/location/data/services/osrm_service.dart';

/// Bottom sheet de prévisualisation de route style Google Maps
class RoutePreviewSheet extends StatefulWidget {
  final StoreEntity destination;
  final Map<String, dynamic>? routeInfo;
  final TransportMode selectedMode;
  final ValueChanged<TransportMode> onModeChanged;
  final VoidCallback onStartNavigation;
  final VoidCallback onClose;

  const RoutePreviewSheet({
    super.key,
    required this.destination,
    this.routeInfo,
    required this.selectedMode,
    required this.onModeChanged,
    required this.onStartNavigation,
    required this.onClose,
  });

  @override
  State<RoutePreviewSheet> createState() => _RoutePreviewSheetState();
}

class _RoutePreviewSheetState extends State<RoutePreviewSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Sélection du mode de transport
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildModeButton(
                      TransportMode.driving,
                      Icons.directions_car,
                      l10n?.voiture ?? 'Voiture',
                    ),
                    _buildModeButton(
                      TransportMode.cycling,
                      Icons.directions_bike,
                      l10n?.velo ?? 'Vélo',
                    ),
                    _buildModeButton(
                      TransportMode.walking,
                      Icons.directions_walk,
                      l10n?.marche ?? 'À pied',
                    ),
                  ],
                ),
              );
            },
          ),

          // Informations de route
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Temps et distance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _formatDuration(
                                widget.routeInfo?['duration'] as double?),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _getModeColor(widget.selectedMode),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  l10n?.lePlusRapide ?? 'Le plus rapide',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDistance(
                            widget.routeInfo?['distance'] as double?),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Icône de mode
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getModeColor(widget.selectedMode)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getModeIcon(widget.selectedMode),
                    color: _getModeColor(widget.selectedMode),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Destination
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.place, color: Colors.red.shade400, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.destination.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (widget.destination.address != null)
                        Text(
                          widget.destination.address!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Bouton démarrer navigation
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                // Bouton fermer
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),

                // Bouton démarrer
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return ElevatedButton.icon(
                        onPressed: widget.onStartNavigation,
                        icon: const Icon(Icons.navigation, color: Colors.white),
                        label: Text(
                          l10n?.demarrer ?? 'Démarrer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getModeColor(widget.selectedMode),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(TransportMode mode, IconData icon, String label) {
    final isSelected = widget.selectedMode == mode;
    final color = _getModeColor(mode);

    return GestureDetector(
      onTap: () => widget.onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getModeColor(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving:
        return Colors.blue.shade600;
      case TransportMode.cycling:
        return Colors.orange.shade600;
      case TransportMode.walking:
        return Colors.green.shade600;
    }
  }

  IconData _getModeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving:
        return Icons.directions_car;
      case TransportMode.cycling:
        return Icons.directions_bike;
      case TransportMode.walking:
        return Icons.directions_walk;
    }
  }

  String _formatDuration(double? seconds) {
    if (seconds == null) return '--';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '--';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

/// Widget pour afficher la navigation en cours (mini barre en bas)
class ActiveNavigationBar extends StatelessWidget {
  final String destination;
  final String? eta;
  final String? distance;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const ActiveNavigationBar({
    super.key,
    required this.destination,
    this.eta,
    this.distance,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade600,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade200,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.navigation, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        eta ?? l10n?.navigationEnCours ?? 'Navigation en cours',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                  Text(
                    '$distance • $destination',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
