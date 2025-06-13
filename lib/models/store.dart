


import 'package:latlong2/latlong.dart';

class Store{

final String id;
  final String nom_enseigne;
  final String siret ;
  final String adresse;
  final String ville ;
  final String code_postal ;
  final String telephone ;
  final String description ;
   final Map<String, dynamic> geom;
  final int Categorieid;

  const Store({
    required this.id,
    required this.nom_enseigne,
    required this.siret,
    required this.adresse,
    required this.ville,
    required this.code_postal,
    required this.telephone,
    required this.description,
    required this.geom,
    required this.Categorieid,
  });

   double get latitude {
    if (geom['coordinates'] != null && geom['coordinates'] is List) {
      List coordinates = geom['coordinates'];
      if (coordinates.length >= 2) {
        return coordinates[1].toDouble(); // Latitude est en position 1
      }
    }
    return 0.0;
  }

  // Getter pour obtenir la longitude depuis geom
  double get longitude {
    if (geom['coordinates'] != null && geom['coordinates'] is List) {
      List coordinates = geom['coordinates'];
      if (coordinates.length >= 2) {
        return coordinates[0].toDouble(); // Longitude est en position 0
      }
    }
    return 0.0;
  }

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      nom_enseigne: json['nom_enseigne'],
      siret: json['siret'],
      adresse: json['adresse'],
      ville: json['ville'],
      code_postal: json['code_postal'],
      telephone: json['telephone'],
      description: json['description'],
      Categorieid: json['Categorieid'],
      geom: json['geom'],
    );
  }


}