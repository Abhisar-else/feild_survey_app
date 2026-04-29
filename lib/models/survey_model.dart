class Survey {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Survey({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  // Convert Survey to JSON for database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  // Create Survey from database map
  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      synced: (json['synced'] as int) == 1,
    );
  }

  // Copy with method for immutability
  Survey copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Survey(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}

class SurveyResponse {
  final String id;
  final String surveyId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool synced;

  SurveyResponse({
    required this.id,
    required this.surveyId,
    required this.data,
    required this.createdAt,
    this.synced = false,
  });

  // Convert to JSON for database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'survey_id': surveyId,
      'data': _encodeData(data),
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  // Create from database map
  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    return SurveyResponse(
      id: json['id'] as String,
      surveyId: json['survey_id'] as String,
      data: _decodeData(json['data'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      synced: (json['synced'] as int) == 1,
    );
  }

  // Helper to encode map to string
  static String _encodeData(Map<String, dynamic> data) {
    // Simple JSON encoding - use json package for production
    return data.toString();
  }

  // Helper to decode string to map
  static Map<String, dynamic> _decodeData(String data) {
    // Parse the string representation back to map
    // For production, use proper JSON parsing
    try {
      final parts = data.replaceAll('{', '').replaceAll('}', '').split(',');
      final map = <String, dynamic>{};
      for (var part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) {
          map[kv[0].trim()] = kv[1].trim();
        }
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  // Copy with method
  SurveyResponse copyWith({
    String? id,
    String? surveyId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? synced,
  }) {
    return SurveyResponse(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }
}
