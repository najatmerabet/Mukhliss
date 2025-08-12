import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/l10n/l10n.dart';
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/services/osrm_service.dart';

import 'package:mukhliss/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';

class RouteBottomSheet extends ConsumerWidget {
  final Store shop;
  final Position? currentPosition;
  final TransportMode selectedMode;
  final Map<String, dynamic>? routeInfo;
  final bool showTransportModes;
  final Function(TransportMode) onModeChanged;
  final Function() onRecenter;
  final Function() onCancel;
  final VoidCallback onShowShopDetails;
  final VoidCallback? onStartNavigation;

  const RouteBottomSheet({
    super.key,
    required this.shop,
    required this.currentPosition,
    required this.selectedMode,
    required this.routeInfo,
    required this.showTransportModes,
    required this.onModeChanged,
    required this.onRecenter,
    required this.onCancel,
    required this.onShowShopDetails,
    this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.light;
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.35,
      maxChildSize: 0.7,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Column(
            children: [
              // Handle avec couleur d'accent
              // Container(
              //   margin: const EdgeInsets.only(top: 8, bottom: 8),
              //   width: 60,
              //   height: 6,
              //   decoration: BoxDecoration(
              //     color: isDarkMode
              //                 ? Colors.grey.shade700
              //                 : Colors.grey.shade400,
              //     borderRadius: BorderRadius.circular(3),
              //   ),
              // ),
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [                        
                        const SizedBox(height: 16),
                        
                        if (showTransportModes) ...[
                          _buildTransportSection(context, AppColors.primary, AppColors.secondary),
                          const SizedBox(height: 16),
                        ],
                        
                        if (routeInfo != null) _buildRouteInfoSection(context, AppColors.success, AppColors.accent),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Fixed action buttons at bottom
              _buildBottomActionBar(context, ref, AppColors.primary, AppColors.error, AppColors.lightSecondary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransportSection(BuildContext context, Color primaryColor, Color secondaryColor) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.1), secondaryColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.mode ?? 'CHOISISSEZ VOTRE MOYEN DE TRANSPORT',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: secondaryColor,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTransportModeButton(
                  context, 
                  TransportMode.driving, 
                  Icons.directions_car, 
                  l10n?.voiture ?? 'Voiture',
                 AppColors.lightPrimary, // Bleu pour la voiture
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTransportModeButton(
                  context, 
                  TransportMode.walking, 
                  Icons.directions_walk, 
                  l10n?.marche ?? 'Marche',
                 AppColors.success, // Vert pour la marche
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTransportModeButton(
                  context, 
                  TransportMode.cycling, 
                  Icons.directions_bike, 
                  l10n?.velo ?? 'Vélo',
                 AppColors.warning, // Orange pour le vélo
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransportModeButton(
    BuildContext context, 
    TransportMode mode, 
    IconData icon, 
    String label,
    Color buttonColor,
  ) {
    final isSelected = selectedMode == mode;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected ? [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: OutlinedButton(
        onPressed: () => onModeChanged(mode),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? buttonColor : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: isSelected ? buttonColor : buttonColor.withOpacity(0.5),
            width: isSelected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoSection(BuildContext context, Color successColor, Color accentColor) {
    final l10n = AppLocalizations.of(context);
    final distance = routeInfo?['distance']?.toDouble() ?? 0.0;
    final duration = routeInfo?['duration']?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [successColor.withOpacity(0.05), accentColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: successColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: successColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.route,
                  color: successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n?.detailsiterinaire ??  'DÉTAILS DE L\'ITINÉRAIRE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: successColor,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildRouteDetailItem(
                    context,
                    Icons.straighten,
                    l10n?.distance ?? 'Distance',
                    OSRMRoutingService().formatDistance(distance),
                    const Color(0xFF4361EE), // Bleu
                  ),
                ),
                VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: successColor.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildRouteDetailItem(
                    context,
                    Icons.access_time,
                    l10n?.duree ?? 'Durée',
                    OSRMRoutingService().formatDuration(duration),
                   AppColors.secondary, // Bleu foncé
                  ),
                ),
                VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: successColor.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildRouteDetailItem(
                    context,
                    _getModeIcon(selectedMode),
                    l10n?.mode ?? 'Mode',
                    _getModeName(selectedMode),
                    _getModeColor(selectedMode), // Couleur spécifique au mode
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetailItem(
    BuildContext context, 
    IconData icon, 
    String title, 
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildBottomActionBar(
  BuildContext context, 
  WidgetRef ref,
  Color primaryColor, 
  Color errorColor,
  Color accentColor,
) {
  final l10n = AppLocalizations.of(context);
  final themeMode = ref.watch(themeProvider);
  final isDarkMode = themeMode == AppThemeMode.light;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
      border: Border(
        top: BorderSide(
          color: primaryColor.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, -5),
        )
      ],
    ),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          // Bouton Recentrer
          _buildRecenterButton(l10n, primaryColor),
          
          const SizedBox(width: 12),
          
          // Bouton principal de navigation
          _buildNavigationButton(l10n, accentColor),
          
          const SizedBox(width: 12),
          
          // Bouton Annuler
          _buildCancelButton(l10n, errorColor),
        ],
      ),
    ),
  );
}

  String _getModeName(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving: return 'Voiture';
      case TransportMode.walking: return 'Marche';
      case TransportMode.cycling: return 'Vélo';
    }
  }

  IconData _getModeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving: return Icons.directions_car;
      case TransportMode.walking: return Icons.directions_walk;
      case TransportMode.cycling: return Icons.directions_bike;
    }
  }

  Color _getModeColor(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving: return const Color(0xFF4895EF); // Bleu
      case TransportMode.walking: return const Color(0xFF38B000); // Vert
      case TransportMode.cycling: return const Color(0xFFFF9E00); // Orange
    }
  }

  Widget _buildRecenterButton(AppLocalizations? l10n, Color primaryColor) {
  return Tooltip(
    message: l10n?.recenter ?? 'Recentrer la carte',
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onRecenter,
        icon: Icon(Icons.my_location, color: Colors.white),
        style: IconButton.styleFrom(
          backgroundColor: primaryColor,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(12),
        ),
      ),
    ),
  );
}

Widget _buildNavigationButton(AppLocalizations? l10n, Color accentColor) {
  return Expanded(
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onStartNavigation,
        icon: const Icon(Icons.navigation, size: 20, color: Colors.white),
        label: Text(
          l10n?.navigation ?? 'LANCER LA NAVIGATION',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
        ),
      ),
    ),
  );
}

Widget _buildCancelButton(AppLocalizations? l10n, Color errorColor) {
  return Tooltip(
    message: l10n?.cancel ?? 'Annuler',
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: errorColor.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onCancel,
        icon: const Icon(Icons.close, color: Colors.white),
        style: IconButton.styleFrom(
          backgroundColor: errorColor,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(12),
        ),
      ),
    ),
  );
}
}