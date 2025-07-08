


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/models/clientoffre.dart';
import 'package:mukhliss/services/clientoffre_service.dart';

final clientoffreprovider = Provider<ClientoffreService>((ref) {
  return ClientoffreService();
});


// Provider pour récupérer les offres d'un client spécifique
final clientOffresProvider = FutureProvider.family<List<ClientOffre>, String>((ref, clientId) {
  return ref.watch(clientoffreprovider).getClientOffres(clientId);
});