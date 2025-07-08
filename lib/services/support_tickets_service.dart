



import 'package:mukhliss/models/supportticket.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Support_Tickets_Servvice {
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
        'sujet': sujet, // Maintenant présent
        'message': message,
        'status': 'open',
        'priority':priority,
        'category': category,
      });
    } catch (e, stack) {
      print('Error creating ticket: $e\n$stack');
      rethrow;
    }
  }

  Future<List<Supportticket>> getUserTickets() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('support_tickets')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Supportticket.fromJson(json))
        .toList();
  }


 

}