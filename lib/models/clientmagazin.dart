


class ClientMagazin {

final int id;
final String client_id;
final String magazin_id;
final String createdAt;
final int cumulpoint;
final int solde;


  const ClientMagazin({
    required this.id,
    required this.client_id,
    required this.magazin_id,
    required this.createdAt,
    required this.cumulpoint,
    required this.solde,
 
  });

  factory ClientMagazin.fromJson(Map<String, dynamic> json) {
    return ClientMagazin(
      id: json['id'] as int? ?? 0, // Valeur par défaut si null
      client_id: json['client_id'] as String? ?? '', // Valeur par défaut si null
      magazin_id: json['magazin_id'] as String? ?? '', // Valeur par défaut si null
      createdAt: json['created_at'] as String? ?? '', // Valeur par défaut si null
      cumulpoint: json['cumulpoint'] as int? ?? 0, // Valeur par défaut si null
      solde: json['solde'] as int? ?? 0, // Valeur par défaut si null
    );
  }

}