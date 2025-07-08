


import 'package:mukhliss/models/rewards.dart';

class ClientOffre {
  final String client_id;
  final Rewards reward;
  final DateTime created_at;

  ClientOffre({
    required this.client_id,
    required this.reward,
    required this.created_at,
  });

 factory ClientOffre.fromJson(Map<String, dynamic> json) {
    return ClientOffre(
      client_id: json['client_id'] as String,
      reward: Rewards.fromJson(json['rewards'] as Map<String, dynamic>),
      created_at: DateTime.parse(json['created_at'] as String),
    );
  }



}