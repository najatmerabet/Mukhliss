import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/routes/app_router.dart';

class Profile extends ConsumerStatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  ConsumerState<Profile> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<Profile> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      
      // Utilisation du provider pour accéder au service d'authentification
      final authService = ref.read(authProvider);
      final user = authService.currentUser;
      
      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pushNamed(context, AppRouter.login);
        }
        return;
      }

      final userType = await authService.getUserType();
      final tableName = userType == 'client' ? 'clients' : 'magasins';

      final response = await authService.client
          .from(tableName)
          .select()
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userData = response;
          _userData!['user_type'] = userType;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
        debugPrint('Erreur _loadUserData: $e');
      }
    }
  }

  Future<void> _logout() async {
    // Utilisation du provider pour accéder au service d'authentification
    await ref.read(authProvider).logout();
    if (mounted) {
      Navigator.pushNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClient = _userData?['user_type'] == 'client';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigation vers les paramètres
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Photo de profil
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _userData?['avatar_url'] != null
                        ? NetworkImage(_userData!['avatar_url'])
                        : const AssetImage('images/without background.png')
                            as ImageProvider,
                    child: _userData?['avatar_url'] == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Nom de l'utilisateur
                  Text(
                    _userData?['nom'] ?? 'Non défini',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    _userData?['email'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Informations spécifiques au type d'utilisateur
                  if (isClient) _buildClientInfo(),
                  if (!isClient) _buildMagasinInfo(),
                  
                  const SizedBox(height: 24),

                  // Boutons d'action
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier le profil'),
                    onPressed: () {
                      // Navigation vers l'édition du profil
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Déconnexion'),
                    onPressed: _logout,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  value.isNotEmpty ? value : 'Non renseigné',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations personnelles',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            _buildInfoRow(Icons.phone, 'Téléphone', _userData?['telephone'] ?? ''),
            _buildInfoRow(Icons.home, 'Adresse', _userData?['adresse'] ?? ''),
            _buildInfoRow(
              Icons.calendar_today, 
              'Membre depuis', 
              _formatDate(_userData?['created_at'] ?? '')
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMagasinInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations du magasin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            _buildInfoRow(Icons.store, 'Enseigne', _userData?['nom_enseigne'] ?? ''),
            _buildInfoRow(Icons.assignment, 'SIRET', _userData?['siret'] ?? ''),
            _buildInfoRow(
              Icons.location_city, 
              'Adresse', 
              _formatAddress(
                _userData?['adresse'] ?? '',
                _userData?['code_postal'] ?? '',
                _userData?['ville'] ?? ''
              )
            ),
            _buildInfoRow(
              Icons.calendar_today, 
              'Inscription', 
              _formatDate(_userData?['created_at'] ?? '')
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
  
  String _formatAddress(String address, String postalCode, String city) {
    final parts = [
      if (address.isNotEmpty) address,
      if (postalCode.isNotEmpty || city.isNotEmpty) '$postalCode $city',
    ];
    return parts.join('\n');
  }
}