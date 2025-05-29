import 'package:flutter/material.dart';
import 'package:mukhliss/models/user_device.dart';
import 'package:mukhliss/services/auth_service.dart';
import 'package:mukhliss/services/device_management_service.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final AuthService _authService = AuthService();
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
  // 1) charge currentDeviceId depuis Supabase
  await _deviceService.initCurrentDeviceFromSession();
  // 2) charge la liste des appareils
  await _loadDevices();
}
  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final devices = await _authService.getUserDevices();
      final stats = await _authService.getDeviceStats();

      setState(() {
        _devices = devices;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Ajoutez cette méthode dans votre DevicesScreen
  // Dans DevicesScreen, modifiez la méthode _disconnectDeviceRemotely :

Future<void> _disconnectDeviceRemotely(UserDevice device) async {
  debugPrint('🔹 [DevicesScreen] Tentative déconnexion: ${device.deviceName}');
  debugPrint('🔹 [DevicesScreen] Device ID: ${device.deviceId}');
  debugPrint('🔹 [DevicesScreen] Current Device ID: ${_deviceService.currentDeviceId}');

  final confirmed = await _showConfirmDialog(
    'Déconnecter à distance',
    'Êtes-vous sûr de vouloir déconnecter "${device.deviceName}" à distance ?\n\nL\'appareil sera déconnecté automatiquement.',
  );

  if (confirmed) {
    try {
      debugPrint('🔹 [DevicesScreen] Démarrage déconnexion à distance...');
      
      final success = await _authService.disconnectDeviceRemotely(device.deviceId);
      
      if (success) {
        debugPrint('✅ [DevicesScreen] Déconnexion à distance réussie');
        _showSuccessSnackBar('Appareil déconnecté à distance - Il sera déconnecté dans quelques secondes');
        _loadDevices();
      } else {
        debugPrint('❌ [DevicesScreen] Échec déconnexion à distance');
        _showErrorSnackBar('Erreur lors de la déconnexion');
      }
    } catch (e) {
      debugPrint('❌ [DevicesScreen] Exception: $e');
      _showErrorSnackBar('Erreur: ${e.toString()}');
    }
  }
}
  // Vérifier si c'est l'appareil actuel
  bool _isCurrentDevice(UserDevice device) {
    final now = DateTime.now();
    final difference = now.difference(device.lastActiveAt);
    return difference.inMinutes <
        5; // Considéré comme actuel si actif dans les 5 dernières minutes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Appareils'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _registerCurrentDevice,
            tooltip: 'Enregistrer cet appareil',
          ),
        ],
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistiques', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    'Total',
                    _stats['total']?.toString() ?? '0',
                    Colors.blue,
                    Icons.devices,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'Actifs',
                    _stats['active']?.toString() ?? '0',
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'Inactifs',
                    _stats['inactive']?.toString() ?? '0',
                    Colors.orange,
                    Icons.pause_circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDevicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Appareils (${_devices.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: _registerCurrentDevice,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_devices.isEmpty)
          _buildEmptyState()
        else
          ..._devices.map((device) => _buildDeviceCard(device)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.devices, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun appareil enregistré',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Enregistrez cet appareil pour commencer',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _registerCurrentDevice,
              icon: const Icon(Icons.smartphone),
              label: const Text('Enregistrer cet appareil'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(UserDevice device) {
    final isCurrent = device.deviceId == _deviceService.currentDeviceId;
print( " currentDeviceId: " + _deviceService.currentDeviceId.toString());


    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.isActive ? Colors.green : Colors.grey,
          child: Icon(
            _getDeviceIcon(device.deviceType, device.platform),
            color: Colors.white,
          ),
        ),
        title: Text(
          device.deviceName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getPlatformIcon(device.platform),
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text('${device.platform} • ${device.deviceType}'),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Dernière activité: ${_formatDate(device.lastActiveAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (device.appVersion != null) ...[
              const SizedBox(height: 2),
              Text(
                'Version: ${device.appVersion}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleDeviceAction(value, device),
          itemBuilder:
              (context) => [
                if (device.isActive)
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Row(
                      children: [
                        Icon(Icons.pause, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Désactiver'),
                      ],
                    ),
                  ),
                // NOUVELLE OPTION - Déconnexion à distance
                // 2) Déconnecter à distance **si ce n’est pas** le device courant**
                if (!isCurrent)
                  const PopupMenuItem(
                    value: 'disconnect_remote',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Déconnecter à distance'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Détails'),
                    ],
                  ),
                ),
              ],
        ),

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

  Future<void> _registerCurrentDevice() async {
    try {
      // Afficher un dialog pour personnaliser le nom
      final deviceName = await _showDeviceNameDialog();
      if (deviceName == null) return;

      // Afficher un indicateur de chargement
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Enregistrement en cours...'),
                ],
              ),
            ),
      );

      final device = await _authService.registerCurrentDevice(
        customName: deviceName.isNotEmpty ? deviceName : null,
      );

      // Fermer le dialog de chargement
      if (mounted) Navigator.of(context).pop();

      if (device != null) {
        _showSuccessSnackBar('Appareil enregistré avec succès');
        _loadDevices();
      } else {
        _showErrorSnackBar('Erreur lors de l\'enregistrement');
      }
    } catch (e) {
      // Fermer le dialog de chargement si ouvert
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackBar('Erreur: ${e.toString()}');
    }
  }

  Future<String?> _showDeviceNameDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nom de l\'appareil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Donnez un nom à cet appareil (optionnel)'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Mon iPhone, PC Bureau...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  Future<void> _handleDeviceAction(String action, UserDevice device) async {
    switch (action) {
      case 'deactivate':
        await _deactivateDevice(device);
        break;
      case 'disconnect_remote': // NOUVEAU CAS
        await _disconnectDeviceRemotely(device);
        break;
      case 'delete':
        await _deleteDevice(device);
        break;
      case 'details':
        _showDeviceDetails(device);
        break;
    }
  }

  Future<void> _deactivateDevice(UserDevice device) async {
    final confirmed = await _showConfirmDialog(
      'Désactiver l\'appareil',
      'Êtes-vous sûr de vouloir désactiver "${device.deviceName}" ?',
    );

    if (confirmed) {
      try {
        final success = await _authService.deactivateDevice(device.deviceId);
        if (success) {
          _showSuccessSnackBar('Appareil désactivé');
          _loadDevices();
        } else {
          _showErrorSnackBar('Erreur lors de la désactivation');
        }
      } catch (e) {
        _showErrorSnackBar('Erreur: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteDevice(UserDevice device) async {
    final confirmed = await _showConfirmDialog(
      'Supprimer l\'appareil',
      'Êtes-vous sûr de vouloir supprimer "${device.deviceName}" ?\n\nCette action est irréversible.',
    );

    if (confirmed) {
      try {
        final success = await _authService.removeDevice(device.deviceId);
        if (success) {
          _showSuccessSnackBar('Appareil supprimé');
          _loadDevices();
        } else {
          _showErrorSnackBar('Erreur lors de la suppression');
        }
      } catch (e) {
        _showErrorSnackBar('Erreur: ${e.toString()}');
      }
    }
  }

  void _showDeviceDetails(UserDevice device) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(device.deviceName),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Type', device.deviceType),
                  _buildDetailRow('Plateforme', device.platform),
                  if (device.appVersion != null)
                    _buildDetailRow('Version app', device.appVersion!),
                  _buildDetailRow(
                    'Statut',
                    device.isActive ? 'Actif' : 'Inactif',
                  ),
                  _buildDetailRow('Créé le', _formatFullDate(device.createdAt)),
                  _buildDetailRow(
                    'Dernière activité',
                    _formatFullDate(device.lastActiveAt),
                  ),

                  if (device.deviceInfo != null &&
                      device.deviceInfo!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Informations techniques:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...device.deviceInfo!.entries
                        .map(
                          (entry) => _buildDetailRow(
                            entry.key,
                            entry.value.toString(),
                          ),
                        )
                        .toList(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmer'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
