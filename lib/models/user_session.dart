import 'dart:convert';

class UserSession {
  const UserSession({
    required this.token,
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String token;
  final int id;
  final String name;
  final String email;
  final String role;

  bool get isAdmin => role == 'admin';
  bool get isFieldWorker => role == 'field_worker';

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      },
    };
  }

  String encode() => jsonEncode(toJson());

  factory UserSession.fromAuthResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final user = data['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return UserSession(
      token: data['token'] as String? ?? json['token'] as String? ?? '',
      id: _toInt(user['id']) ?? 0,
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
      role: user['role'] as String? ?? 'field_worker',
    );
  }

  factory UserSession.fromEncoded(String value) {
    return UserSession.fromAuthResponse(jsonDecode(value) as Map<String, dynamic>);
  }

  UserSession copyWithUser(Map<String, dynamic> user) {
    return UserSession(
      token: token,
      id: _toInt(user['id']) ?? id,
      name: user['name'] as String? ?? name,
      email: user['email'] as String? ?? email,
      role: user['role'] as String? ?? role,
    );
  }
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
