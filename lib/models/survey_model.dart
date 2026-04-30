import 'dart:convert';

enum SyncStatus {
  pending('pending'),
  synced('synced'),
  failed('failed');

  const SyncStatus(this.value);

  final String value;

  static SyncStatus fromValue(String? value) {
    return SyncStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SyncStatus.pending,
    );
  }
}

class Question {
  const Question({
    required this.id,
    this.remoteId,
    required this.surveyId,
    required this.text,
    required this.type,
    required this.order,
    this.options = const <String>[],
  });

  final String id;
  final int? remoteId;
  final String surveyId;
  final String text;
  final String type;
  final int order;
  final List<String> options;

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'remote_id': remoteId,
      'survey_id': surveyId,
      'text': text,
      'type': type,
      'question_order': order,
      'options': jsonEncode(options),
    };
  }

  Map<String, dynamic> toApi() {
    return {
      'text': text,
      'type': type,
      'options': options,
    };
  }

  factory Question.fromDatabase(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      remoteId: json['remote_id'] as int?,
      surveyId: json['survey_id'] as String,
      text: json['text'] as String? ?? '',
      type: json['type'] as String? ?? 'Text Input',
      order: json['question_order'] as int? ?? 0,
      options: _decodeStringList(json['options']),
    );
  }

  factory Question.fromApi(
    Map<String, dynamic> json, {
    required String surveyId,
    required int order,
  }) {
    final remoteId = _toInt(json['id']);
    return Question(
      id: remoteId?.toString() ?? '$surveyId-$order',
      remoteId: remoteId,
      surveyId: surveyId,
      text: json['question_text'] as String? ?? json['text'] as String? ?? '',
      type: json['question_type'] as String? ?? json['type'] as String? ?? 'Text Input',
      order: _toInt(json['question_order']) ?? order,
      options: _decodeStringList(json['options']),
    );
  }
}

class Survey {
  const Survey({
    required this.id,
    this.remoteId,
    required this.title,
    this.description = '',
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.creatorName,
    this.questionCount = 0,
    this.responseCount = 0,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncError,
    this.questions = const <Question>[],
  });

  final String id;
  final int? remoteId;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? creatorName;
  final int questionCount;
  final int responseCount;
  final SyncStatus syncStatus;
  final String? lastSyncError;
  final List<Question> questions;

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'remote_id': remoteId,
      'title': title,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'creator_name': creatorName,
      'question_count': questionCount == 0 ? questions.length : questionCount,
      'response_count': responseCount,
      'sync_status': syncStatus.value,
      'synced': syncStatus == SyncStatus.synced ? 1 : 0,
      'last_sync_error': lastSyncError,
    };
  }

  factory Survey.fromDatabase(
    Map<String, dynamic> json, {
    List<Question> questions = const <Question>[],
  }) {
    return Survey(
      id: json['id'] as String,
      remoteId: json['remote_id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      creatorName: json['creator_name'] as String?,
      questionCount: json['question_count'] as int? ?? questions.length,
      responseCount: json['response_count'] as int? ?? 0,
      syncStatus: SyncStatus.fromValue(json['sync_status'] as String?),
      lastSyncError: json['last_sync_error'] as String?,
      questions: questions,
    );
  }

  factory Survey.fromApi(Map<String, dynamic> json) {
    final remoteId = _toInt(json['id']);
    final surveyId = remoteId?.toString() ?? json['client_id']?.toString() ?? '';
    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map<String, dynamic>>()
            .toList()
            .asMap()
            .entries
            .map(
              (entry) => Question.fromApi(
                entry.value,
                surveyId: surveyId,
                order: entry.key,
              ),
            )
            .toList()
        : <Question>[];

    return Survey(
      id: surveyId,
      remoteId: remoteId,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at'] ?? json['created_at']),
      creatorName: json['creator_name'] as String?,
      questionCount: _toInt(json['question_count']) ?? questions.length,
      responseCount: _toInt(json['response_count']) ?? 0,
      syncStatus: SyncStatus.synced,
      questions: questions,
    );
  }

  Survey copyWith({
    String? id,
    int? remoteId,
    String? title,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creatorName,
    int? questionCount,
    int? responseCount,
    SyncStatus? syncStatus,
    String? lastSyncError,
    List<Question>? questions,
  }) {
    return Survey(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creatorName: creatorName ?? this.creatorName,
      questionCount: questionCount ?? this.questionCount,
      responseCount: responseCount ?? this.responseCount,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      questions: questions ?? this.questions,
    );
  }
}

class SurveyResponse {
  const SurveyResponse({
    required this.id,
    this.remoteId,
    required this.clientResponseId,
    required this.surveyId,
    required this.surveyRemoteId,
    required this.answers,
    required this.createdAt,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncError,
  });

  final String id;
  final int? remoteId;
  final String clientResponseId;
  final String surveyId;
  final int surveyRemoteId;
  final Map<String, dynamic> answers;
  final DateTime createdAt;
  final SyncStatus syncStatus;
  final String? lastSyncError;

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'remote_id': remoteId,
      'client_response_id': clientResponseId,
      'survey_id': surveyId,
      'survey_remote_id': surveyRemoteId,
      'answers': jsonEncode(answers),
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus.value,
      'synced': syncStatus == SyncStatus.synced ? 1 : 0,
      'last_sync_error': lastSyncError,
    };
  }

  Map<String, dynamic> toApi() {
    return {
      'client_response_id': clientResponseId,
      'survey_id': surveyRemoteId,
      'answers': answers,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SurveyResponse.fromDatabase(Map<String, dynamic> json) {
    return SurveyResponse(
      id: json['id'] as String,
      remoteId: json['remote_id'] as int?,
      clientResponseId: json['client_response_id'] as String,
      surveyId: json['survey_id'] as String,
      surveyRemoteId: json['survey_remote_id'] as int,
      answers: _decodeMap(json['answers']),
      createdAt: _date(json['created_at']),
      syncStatus: SyncStatus.fromValue(json['sync_status'] as String?),
      lastSyncError: json['last_sync_error'] as String?,
    );
  }

  SurveyResponse copyWith({
    int? remoteId,
    SyncStatus? syncStatus,
    String? lastSyncError,
  }) {
    return SurveyResponse(
      id: id,
      remoteId: remoteId ?? this.remoteId,
      clientResponseId: clientResponseId,
      surveyId: surveyId,
      surveyRemoteId: surveyRemoteId,
      answers: answers,
      createdAt: createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncError: lastSyncError,
    );
  }
}

Map<String, dynamic> _decodeMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is String && value.isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) return decoded;
  }
  return <String, dynamic>{};
}

List<String> _decodeStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
  }
  if (value is String && value.isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return decoded.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
    }
  }
  return <String>[];
}

DateTime _date(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
