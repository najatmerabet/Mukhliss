import 'package:flutter/foundation.dart';
import 'package:mukhliss/features/support/data/models/support_ticket_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportTicketsService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createSupportTicket({
    required String sujet,
    required String message,
    required String priority,
    required String category,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _client.from('support_tickets').insert({
        'user_id': user.id,
        'email': user.email ?? 'no-email',
        'sujet': sujet,
        'message': message,
        'status': 'open',
        'priority': priority,
        'category': category,
      });
    } catch (e, stack) {
      debugPrint('Error creating ticket: $e\n$stack');
      rethrow;
    }
  }

  Future<List<SupportTicketModel>> getUserTickets() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('support_tickets')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => SupportTicketModel.fromJson(json))
        .toList();
  }
}
