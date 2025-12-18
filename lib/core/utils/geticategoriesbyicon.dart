import 'package:flutter/material.dart';
import 'package:mukhliss/core/theme/app_theme.dart';

class CategoryMarkers {
  // Icônes pour le centre des marqueurs
static final Map<String, IconData> _pinIcons = {
    // Restaurants & Nourriture
    'restaurant': Icons.restaurant,
    'food': Icons.fastfood,
    'cafe': Icons.local_cafe,
    'bakery': Icons.bakery_dining,
    'icecream': Icons.icecream,
    'lunch_dining': Icons.lunch_dining,
    'dinner_dining': Icons.dinner_dining,
    
    // Achats & Commerce
    'shopping': Icons.shopping_basket,
    'commerce': Icons.store,
    'store': Icons.store_mall_directory,
    'mall': Icons.local_mall,
    'grocery': Icons.local_grocery_store,
    
    // Santé & Médical
    'health': Icons.medical_services,
    'santé': Icons.health_and_safety,
    'pharmacy': Icons.local_pharmacy,
    'pharmacie': Icons.medication,
    'hospital': Icons.local_hospital,
    'medical': Icons.medical_information,
    
    // Transport & Énergie
    'gas': Icons.local_gas_station,
    'essence': Icons.ev_station,
    'charging_station': Icons.electric_car,
    'airport': Icons.airplanemode_active,
    'bus': Icons.directions_bus,
    'train': Icons.train,
    'taxi': Icons.local_taxi,
    'car_rental': Icons.car_rental,
    
    // Finances
    'bank': Icons.account_balance,
    'banque': Icons.money,
    'atm': Icons.atm,
    'finance': Icons.account_balance_wallet,
    
    // Hébergement
    'hotel': Icons.king_bed,
    'accommodation': Icons.hotel,
    'bed': Icons.bed,
    
    // Sports & Loisirs
    'sport': Icons.sports_soccer,
    'sports': Icons.sports,
    'fitness': Icons.fitness_center,
    'gym': Icons.sports_gymnastics,
    'park': Icons.park,
    'pool': Icons.pool,
    'golf': Icons.golf_course,
    'tennis': Icons.sports_tennis,
    'basketball': Icons.sports_basketball,
    
    // Éducation & Culture
    'school': Icons.school,
    'education': Icons.cast_for_education,
    'library': Icons.local_library,
    'museum': Icons.museum,
    'theater': Icons.theaters,
    'cinema': Icons.movie,
    
    // Divertissement
    'entertainment': Icons.celebration,
    'bar': Icons.sports_bar,
    'nightlife': Icons.nightlife,
    'music': Icons.music_note,
    'casino': Icons.casino,
    
    // Services Publics
    'post_office': Icons.local_post_office,
    'police': Icons.local_police,
    'fire_station': Icons.local_fire_department,
    'government': Icons.account_balance,
    
    // Autres - CORRIGÉ
    'parking': Icons.local_parking,
    'toilet': Icons.wc,
    'wifi': Icons.wifi,
    'beach': Icons.beach_access,
    'camping': Icons.forest, // Correction: utilisé forest pour camping
    'church': Icons.church,
    'temple': Icons.temple_buddhist,
    'mosque': Icons.mosque,
    'synagogue': Icons.synagogue,
    
    // Catégories générales
    'home': Icons.home,
    'work': Icons.work,
    'favorite': Icons.favorite,
    'star': Icons.star,
    'warning': Icons.warning,
    'info': Icons.info,
    'place': Icons.place, // Icône par défaut
    'game':Icons.videogame_asset
  };

  // Couleurs des pins
static final Map<String, Color> _pinColors = {
    // Restaurants & Nourriture
    'restaurant': Colors.orange,
    'food': Colors.deepOrange,
    'cafe': Colors.orange[700]!,
    'bakery': Colors.orange[800]!,
    'icecream': Colors.deepOrange[300]!,
    'lunch_dining': Colors.orange[600]!,
    'dinner_dining': Colors.deepOrange[600]!,
    
    // Achats & Commerce
    'shopping': Colors.purple,
    'commerce': Colors.indigo,
    'store': Colors.indigo[700]!,
    'mall': Colors.purple[700]!,
    'grocery': Colors.purple[600]!,
    
    // Santé & Médical
    'health': Colors.red,
    'santé': Colors.red[800]!,
    'pharmacy': Colors.pink,
    'pharmacie': Colors.pink[800]!,
    'hospital': Colors.red[700]!,
    'medical': Colors.red[900]!,
    
    // Transport & Énergie
    'gas': Colors.blueGrey,
    'essence': Colors.blue[800]!,
    'charging_station': Colors.blue[700]!,
    'airport': Colors.blue[600]!,
    'bus': Colors.blue[500]!,
    'train': Colors.blue[400]!,
    'taxi': Colors.yellow[700]!,
    'car_rental': Colors.blue[300]!,
    
    // Finances
    'bank': Colors.green,
    'banque': Colors.lightGreen[800]!,
    'atm': Colors.green[700]!,
    'finance': Colors.green[600]!,
    
    // Hébergement
    'hotel': Colors.blue,
    'accommodation': Colors.blue[200]!,
    'bed': Colors.blue[100]!,
    
    // Sports & Loisirs
    'sport': Colors.teal,
    'sports': Colors.teal[700]!,
    'fitness': Colors.teal[600]!,
    'gym': Colors.teal[500]!,
    'park': Colors.green,
    'pool': Colors.cyan,
    'golf': Colors.green[700]!,
    'tennis': Colors.green[600]!,
    'basketball': Colors.orange[900]!,
    
    // Éducation & Culture
    'school': Colors.brown,
    'education': Colors.brown[700]!,
    'library': Colors.brown[600]!,
    'museum': Colors.brown[800]!,
    'theater': Colors.deepPurple,
    'cinema': Colors.deepPurple[600]!,
    
    // Divertissement
    'entertainment': Colors.amber,
    'bar': Colors.amber[800]!,
    'nightlife': Colors.amber[900]!,
    'music': Colors.amber[700]!,
    'casino': Colors.amber[600]!,
    
    // Services Publics
    'post_office': Colors.red[400]!,
    'police': Colors.blue[900]!,
    'fire_station': Colors.red,
    'government': Colors.grey[800]!,
    
    // Autres
    'parking': Colors.grey,
    'toilet': Colors.grey[600]!,
    'wifi': Colors.blue,
    'beach': Colors.cyan[300]!,
    'camping': Colors.green[800]!,
    'church': Colors.brown[400]!,
    'temple': Colors.orange[300]!,
    'mosque': Colors.blueGrey[800]!,
    'synagogue': Colors.yellow[800]!,
    
    // Catégories générales
    'home': Colors.pink[300]!,
    'work': Colors.grey[700]!,
    'favorite': Colors.pink,
    'star': Colors.amber,
    'warning': Colors.orange[900]!,
    'info': Colors.blue,
    'place': Colors.grey[600]!,
    'game':Colors.purple
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
    return AppColors.lightPrimary;
  }
}