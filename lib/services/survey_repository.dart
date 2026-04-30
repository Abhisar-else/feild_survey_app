import 'package:uuid/uuid.dart';

import '../database_helper.dart';
import '../models/survey_model.dart';
import '../models/user_session.dart';
import 'api_client.dart';

class QuestionDraft {
  const QuestionDraft({
    required this.text,
    required this.type,
    this.options = const <String>[],
  });

  final String text;
  final String type;
  final List<String> options;

  Map<String, dynamic> toApi() {
    return {
      'text': text,
      'type': type,
      'options': options,
    };
  }
}

class SurveyRepository {
  SurveyRepository({
    required ApiClient apiClient,
    DatabaseHelper? databaseHelper,
    Uuid? uuid,
  })  : _apiClient = apiClient,
        _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _uuid = uuid ?? const Uuid();

  final ApiClient _apiClient;
  final DatabaseHelper _databaseHelper;
  final Uuid _uuid;

  DatabaseHelper get databaseHelper => _databaseHelper;

  Future<List<Survey>> getCachedSurveys() {
    return _databaseHelper.getAllSurveys();
  }

  Future<Survey?> getCachedSurvey(String id) {
    return _databaseHelper.getSurvey(id);
  }

  Future<List<Survey>> refreshSurveys(UserSession session) async {
    final payload = await _apiClient.get('/api/surveys', token: session.token);
    final rows = payload['data'] as List<dynamic>? ?? <dynamic>[];
    final surveys = <Survey>[];

    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final remoteId = row['id'];
      if (remoteId == null) continue;
      try {
        final detail = await _apiClient.get('/api/surveys/$remoteId', token: session.token);
        surveys.add(Survey.fromApi(detail['data'] as Map<String, dynamic>));
      } on ApiException {
        surveys.add(Survey.fromApi(row));
      }
    }

    await _databaseHelper.cacheSurveys(surveys);
    return _databaseHelper.getAllSurveys();
  }

  Future<Survey> createSurvey({
    required UserSession session,
    required String title,
    required String description,
    required List<QuestionDraft> questions,
  }) async {
    if (!session.isAdmin) {
      throw const ApiException('Only admins can create surveys.');
    }

    final payload = await _apiClient.post(
      '/api/surveys',
      token: session.token,
      body: {
        'title': title,
        'description': description,
        'questions': questions.map((question) => question.toApi()).toList(),
      },
    );
    final survey = Survey.fromApi(payload['data'] as Map<String, dynamic>);
    await _databaseHelper.upsertSurvey(survey);
    return survey;
  }

  Future<SurveyResponse> saveResponseOffline({
    required Survey survey,
    required Map<String, dynamic> answers,
  }) async {
    final remoteId = survey.remoteId;
    if (remoteId == null) {
      throw const ApiException('This survey has not been synced from the server yet.');
    }

    final clientResponseId = _uuid.v4();
    final response = SurveyResponse(
      id: clientResponseId,
      clientResponseId: clientResponseId,
      surveyId: survey.id,
      surveyRemoteId: remoteId,
      answers: answers,
      createdAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    await _databaseHelper.insertResponse(response);
    return response;
  }

  Future<int> pendingResponseCount() {
    return _databaseHelper.pendingResponseCount();
  }

  Future<List<SurveyResponse>> getResponsesBySurvey(String surveyId) {
    return _databaseHelper.getResponsesBySurvey(surveyId);
  }

  Future<int> syncPendingResponses(UserSession session) async {
    final pending = await _databaseHelper.getPendingResponses();
    if (pending.isEmpty) return 0;

    final payload = await _apiClient.post(
      '/api/responses',
      token: session.token,
      body: {
        'responses': pending.map((response) => response.toApi()).toList(),
      },
    );

    final results = payload['data'] as List<dynamic>? ?? <dynamic>[];
    var syncedCount = 0;
    for (final result in results.whereType<Map<String, dynamic>>()) {
      final clientId = result['client_response_id'] as String?;
      if (clientId == null || clientId.isEmpty) continue;
      await _databaseHelper.markResponseSynced(
        clientResponseId: clientId,
        remoteId: _toInt(result['id']),
      );
      syncedCount++;
    }
    return syncedCount;
  }

  Future<void> markAllPendingFailed(String message) async {
    final pending = await _databaseHelper.getPendingResponses();
    for (final response in pending) {
      await _databaseHelper.markResponseFailed(
        clientResponseId: response.clientResponseId,
        error: message,
      );
    }
  }
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
