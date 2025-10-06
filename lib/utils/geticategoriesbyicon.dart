import 'package:flutter/material.dart';

class CategoryMarkers {
  // Icônes pour le centre des marqueurs
  static final Map<String, IconData> _pinIcons = {
    'restaurant': Icons.restaurant,
    'food': Icons.fastfood,
    'shopping': Icons.shopping_basket,
    'commerce': Icons.store,
    'health': Icons.medical_services,
    'santé': Icons.health_and_safety,
    'gas': Icons.local_gas_station,
    'essence': Icons.ev_station,
    'bank': Icons.account_balance,
    'banque': Icons.money,
    'hotel': Icons.king_bed,
    'pharmacy': Icons.local_pharmacy,
    'pharmacie': Icons.medication,
    'sport': Icons.sports_soccer,
  };

  // Couleurs des pins
  static final Map<String, Color> _pinColors = {
    'restaurant': Colors.orange,
    'food': Colors.deepOrange,
    'shopping': Colors.purple,
    'commerce': Colors.indigo,
    'health': Colors.red,
    'santé': Colors.red[800]!,
    'gas': Colors.blueGrey,
    'essence': Colors.blue[800]!,
    'bank': Colors.green,
    'banque': Colors.lightGreen[800]!,
    'hotel': Colors.blue,
    'pharmacy': Colors.pink,
    'pharmacie': Colors.pink[800]!,
    'sport': Colors.teal,
  };

  // Méthode pour obtenir un widget de marqueur complet
  static Widget getPinWidget(String categoryName, {double size = 20}) {
    final icon = getPinIcon(categoryName);
    final color = getPinColor(categoryName);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Partie inférieure du pin (forme de goutte)
        Icon(
          Icons.location_pin,
          color:color,
          size: size,
        ),
        // Partie supérieure du pin (cercle coloré)
        Positioned(
          top: size * 0.2, // Ajustez cette valeur pour positionner le cercle
          child: CircleAvatar(
            radius: size * 0.2, // Ajustez la taille du cercle
            backgroundColor: color,
          ),
        ),
        // Icône centrale
        Positioned(
          top: size * 0.2, // Ajustez cette valeur pour centrer l'icône
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.4,
          ),
        ),
      ],
    );
  }

  // Méthodes privées
  static IconData getPinIcon(String categoryName) {
    final lowerName = categoryName.toLowerCase();
    for (final key in _pinIcons.keys) {
      if (lowerName.contains(key)) return _pinIcons[key]!;
    }
    return Icons.category_rounded;
  }

  static Color getPinColor(String categoryName) {
    final lowerName = categoryName.toLowerCase();
    for (final key in _pinColors.keys) {
      if (lowerName.contains(key)) return _pinColors[key]!;
    }
    return Colors.blue;
  }
}