/// ============================================================
/// SupportTicket Entity - Domain Layer
/// ============================================================
library;

/// Entité représentant un ticket de support
class SupportTicketEntity {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String email;
  final String subject;
  final String message;
  final String status;
  final String? response;
  final String? adminNotes;
  final DateTime? updatedAt;
  final String? priority;
  final String? category;

  const SupportTicketEntity({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.email,
    required this.subject,
    required this.message,
    this.status = 'open',
    this.response,
    this.adminNotes,
    this.updatedAt,
    this.priority,
    this.category,
  });

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
  bool get hasResponse => response != null && response!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportTicketEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
