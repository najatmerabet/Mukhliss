



class Supportticket {

 final String id;
 final DateTime created_at;
 final String user_id;
 final String email;
 final String sujet;
 final String message;
 final String status ;
 final String? response;
 final String? admin_notes;
 final DateTime? updated_at;
 final String? priority;
 final String? category;

  Supportticket({
    required this.id,
    required this.created_at,
    required this.user_id,
    required this.email,
    required this.message,
     this.status='open',
    required this.sujet,
     this.response,
     this.admin_notes,
      this.updated_at,
      this.priority,
      this.category,
  });
 
  factory Supportticket.fromJson(Map<String, dynamic> json) {
    return Supportticket(
      id: json['id'] as String,
      created_at: DateTime.parse(json['created_at'] as String),
      user_id: json['user_id'] as String,
      email: json['email'] as String,
      message: json['message'] as String,
      status: json['status'] as String? ?? 'open',
      response: json['response'] as String?,
      admin_notes: json['admin_notes'] as String?,
      sujet: json['sujet'] as String,
      updated_at: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      priority: json['priority'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': user_id,
      'email': email,
      'subject': sujet, // Ajouté
      'message': message,
      'status': status,
      'response': response,
      'admin_notes': admin_notes,
      'sujet': sujet,
      'updated_at': updated_at?.toIso8601String(),
      'priority': priority,
      'category': category,
    };
  }

}