/// ============================================================
/// Support Provider - Presentation Layer
/// ============================================================
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mukhliss/core/logger/app_logger.dart';
import '../../domain/entities/support_ticket_entity.dart';
import '../../data/models/support_ticket_model.dart';

// ============================================================
// PROVIDERS
// ============================================================

/// Provider pour les tickets de support d'un utilisateur
final supportTicketsProvider =
    FutureProvider.family<List<SupportTicketEntity>, String>((
      ref,
      userId,
    ) async {
      try {
        final response = await Supabase.instance.client
            .from('support_tickets')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => SupportTicketModel.fromJson(json).toEntity())
            .toList();
      } catch (e) {
        AppLogger.error('Erreur fetch tickets', error: e);
        return [];
      }
    });

/// Provider pour créer un ticket
final createTicketProvider = FutureProvider.family<bool, Map<String, dynamic>>((
  ref,
  ticketData,
) async {
  try {
    await Supabase.instance.client.from('support_tickets').insert(ticketData);
    return true;
  } catch (e) {
    AppLogger.error('Erreur création ticket', error: e);
    return false;
  }
});
