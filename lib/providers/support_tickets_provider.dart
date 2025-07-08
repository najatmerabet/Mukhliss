

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/services/support_tickets_service.dart';

final supportTicketsProvider = Provider<Support_Tickets_Servvice>((ref) {
  return Support_Tickets_Servvice();
});

// provider pour ajouter un ticket de support
final createSupportTicketProvider = FutureProvider.family<void, Map<String, String>>((ref, data) async {
  final supportService = ref.read(supportTicketsProvider);
  await supportService.createSupportTicket(
    sujet: data['subject'] ?? '',
    message: data['message'] ?? '',
    priority: data['priority'] ?? '',
    category: data['category'] ?? '',
  );
});