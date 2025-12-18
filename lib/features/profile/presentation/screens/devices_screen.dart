import 'package:mukhliss/core/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/app_localizations.dart';

import 'package:mukhliss/features/profile/profile.dart';
import 'package:mukhliss/core/providers/theme_provider.dart';

import 'package:mukhliss/core/theme/app_theme.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _DevicesScreenContent();
  }
}

class _DevicesScreenContent extends ConsumerStatefulWidget {
  const _DevicesScreenContent();

  @override
  ConsumerState<_DevicesScreenContent> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<_DevicesScreenContent> {
  final DeviceManagementService _deviceService = DeviceManagementService();

  List<UserDevice> _devices = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Charger currentDeviceId depuis Supabase
    await _deviceService.initCurrentDeviceFromSession();
    // Charger la liste des appareils
    await _loadDevices();
  }

  Future<void> _loadDevices() async {
    if (!mounted) return; // <- garde avant le premier setState
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final devices = await _deviceService.getUserDevices();
      final stats = await _deviceService.getDeviceStats();

      if (!mounted) return; // <- garde avant le setState final
      setState(() {
        _devices = devices;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // <- garde avant le setState d’erreur
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _disconnectDeviceRemotely(UserDevice device) async {
    debugPrint('🔹 [DevicesScreen] =============');
    debugPrint(
      '🔹 [DevicesScreen] Tentative déconnexion: ${device.deviceName}',
    );
    debugPrint('🔹 [DevicesScreen] Device ID: ${device.deviceId}');
    debugPrint(
      '🔹 [DevicesScreen] Current Device ID: ${_deviceService.currentDeviceId}',
    );
    debugPrint('🔹 [DevicesScreen] Device isActive: ${device.isActive}');
    debugPrint('🔹 [DevicesScreen] =============');

    // ✅ Vérification de sécurité supplémentaire
    if (device.deviceId == _deviceService.currentDeviceId) {
      debugPrint(
        '❌ [DevicesScreen] Tentative de déconnexion de l\'appareil actuel - INTERDIT',
      );
      _showErrorSnackBar('Impossible de déconnecter votre appareil actuel');
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Déconnecter à distance',
      'Êtes-vous sûr de vouloir déconnecter "${device.deviceName}" à distance ?\n\nL\'appareil sera déconnecté automatiquement.',
    );

    if (confirmed) {
      // ✅ Afficher un indicateur de progression

      try {
        debugPrint('🔹 [DevicesScreen] Démarrage déconnexion à distance...');

        // ✅ Vérifier l'état de l'appareil avant déconnexion
        final deviceStatus = await _deviceService.getDeviceStatus(
          device.deviceId,
        );
        debugPrint(
          '🔹 [DevicesScreen] État appareil avant déconnexion: $deviceStatus',
        );

        final success = await _deviceService.disconnectDeviceRemotely(
          device.deviceId,
        );

        // Fermer le dialog de progression
        if (mounted) Navigator.of(context).pop();

        if (success) {
          debugPrint('✅ [DevicesScreen] Déconnexion à distance réussie');
          _showSuccessSnackBar(
            'Appareil déconnecté à distance - Il sera déconnecté dans quelques secondes',
          );

          // ✅ Forcer une synchronisation
          await _deviceService.forceSyncDevices();

          // ✅ Attendre un peu avant de recharger
          await Future.delayed(const Duration(milliseconds: 1500));
          await _loadDevices();

          // ✅ Vérifier l'état après déconnexion
          final statusAfter = await _deviceService.getDeviceStatus(
            device.deviceId,
          );
          debugPrint(
            '🔹 [DevicesScreen] État appareil après déconnexion: $statusAfter',
          );
        } else {
          debugPrint('❌ [DevicesScreen] Échec déconnexion à distance');
          _showErrorSnackBar(
            'Erreur lors de la déconnexion - Veuillez réessayer',
          );
        }
      } catch (e) {
        // Fermer le dialog de progression en cas d'erreur
        if (mounted) Navigator.of(context).pop();

        debugPrint('❌ [DevicesScreen] Exception: $e');
        _showErrorSnackBar('Erreur: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = themeMode == AppThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF0A0E27) : AppColors.surface,
      appBar: AppBar(
        title: Text(
          l10n?.mesappariels ?? 'Mes Appareils',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? Color(0xFF0A0E27) : AppColors.primary,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadDevices,
              tooltip: 'Actualiser',
            ),
          ),
        ],
        // shape: const RoundedRectangleBorder(
        //   borderRadius: BorderRadius.vertical(
        //     bottom: Radius.circular(32),
        //   ),
        // ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDevices,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDevices,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(),
            const SizedBox(height: 20),
            _buildDevicesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_stats.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final thememode = ref.watch(themeProvider);
    final isDarkMode = thememode == AppThemeMode.light;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Color.fromARGB(255, 3, 9, 43) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.statistiques ?? 'Statistiques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  l10n?.total ?? 'Total',
                  _stats['total']?.toString() ?? '0',
                  const Color(0xFF3B82F6),
                  Icons.devices,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  l10n?.active ?? 'Actifs',
                  _stats['active']?.toString() ?? '0',
                  const Color(0xFF10B981),
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  l10n?.inactifs ?? 'Inactifs',
                  _stats['inactive']?.toString() ?? '0',
                  const Color(0xFFF59E0B),
                  Icons.pause_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color, IconData icon) {
    final thememode = ref.watch(themeProvider);
    final isDarkMode = thememode == AppThemeMode.light;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? Colors.white : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesSection() {
    final l10n = AppLocalizations.of(context);
    final thememode = ref.watch(themeProvider);
    final isDarkMode = thememode == AppThemeMode.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.apparielsconnecte ?? 'Appareils connectés',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),

        if (_devices.isEmpty)
          _buildEmptyState()
        else
          ..._devices.map((device) => _buildDeviceCard(device)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.devices, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucun appareil enregistré',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos appareils connectés apparaîtront ici',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Modifiez la méthode _buildDeviceCard comme suit :
  Widget _buildDeviceCard(UserDevice device) {
    final isCurrent = device.deviceId == _deviceService.currentDeviceId;
    final isActive = device.isActive;
    final thememode = ref.watch(themeProvider);
    final isDarkMode = thememode == AppThemeMode.light;
    final L10n = AppLocalizations.of(context);
    AppLogger.debug(' is active ${_deviceService.currentDeviceId}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Color.fromARGB(255, 7, 14, 54) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            isCurrent
                ? Border.all(color: const Color(0xFF10B981), width: 2)
                : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
                isCurrent
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : isActive
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getDeviceIcon(device.deviceType, device.platform),
            color:
                isCurrent
                    ? const Color(0xFF10B981)
                    : isActive
                    ? const Color(0xFF3B82F6)
                    : Colors.grey,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                device.deviceName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color:
                      isDarkMode
                          ? (isActive ? Colors.white : Colors.grey)
                          : (isActive ? Colors.grey[800] : Colors.grey[400]),
                ),
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  L10n?.appareilactuel ?? 'Appareil actuel',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (!isActive && !isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Déconnecté',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getPlatformIcon(device.platform),
                  size: 16,
                  color:
                      isDarkMode
                          ? (isActive ? Colors.white : Colors.grey[400])
                          : (isActive ? Colors.grey[800] : Colors.grey[400]),
                ),
                const SizedBox(width: 6),
                Text(
                  '${device.platform.toUpperCase()} • ${device.deviceType.toUpperCase()}',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? (isActive ? Colors.white : Colors.grey[400])
                            : (isActive ? Colors.grey[800] : Colors.grey[400]),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Dernière activité: ${_formatDate(device.lastActiveAt)}',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDarkMode
                        ? (isActive ? Colors.white : Colors.grey[400])
                        : (isActive ? Colors.grey[800] : Colors.grey[400]),
              ),
            ),
            if (device.appVersion != null) ...[
              const SizedBox(height: 4),
              Text(
                'Version: ${device.appVersion}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDarkMode
                          ? (isActive ? Colors.white : Colors.grey[400])
                          : (isActive ? Colors.grey[800] : Colors.grey[400]),
                ),
              ),
            ],
          ],
        ),
        // Afficher le bouton de déconnexion seulement si l'appareil est actif et n'est pas l'appareil courant
        trailing:
            isActive && !isCurrent
                ? Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _disconnectDeviceRemotely(device),
                    icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                    tooltip: 'Déconnecter à distance',
                  ),
                )
                : null,
        isThreeLine: true,
      ),
    );
  }

  IconData _getDeviceIcon(String deviceType, String platform) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return platform.toLowerCase() == 'ios'
            ? Icons.phone_iphone
            : Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      case 'web':
        return Icons.computer;
      default:
        return Icons.device_unknown;
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.language;
      default:
        return Icons.device_unknown;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            content: Text(
              content,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Déconnecter',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
