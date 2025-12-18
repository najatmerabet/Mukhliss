/// ============================================================
/// SupportTicket Model - Data Layer
/// ============================================================
library;

import '../../domain/entities/support_ticket_entity.dart';

class SupportTicketModel {
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

  const SupportTicketModel({
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

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      email: json['email'] as String,
      subject: json['sujet'] as String,
      message: json['message'] as String,
      status: json['status'] as String? ?? 'open',
      response: json['response'] as String?,
      adminNotes: json['admin_notes'] as String?,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      priority: json['priority'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'sujet': subject,
      'message': message,
      'status': status,
      'response': response,
      'admin_notes': adminNotes,
      'updated_at': updatedAt?.toIso8601String(),
      'priority': priority,
      'category': category,
    };
  }

  SupportTicketEntity toEntity() {
    return SupportTicketEntity(
      id: id,
      createdAt: createdAt,
      userId: userId,
      email: email,
      subject: subject,
      message: message,
      status: status,
      response: response,
      adminNotes: adminNotes,
      updatedAt: updatedAt,
      priority: priority,
      category: category,
    );
  }
}
