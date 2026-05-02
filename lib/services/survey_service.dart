import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../models/survey_model.dart';
import 'api_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SurveyQuestionDraft {
  const SurveyQuestionDraft({
    required this.text,
    required this.type,
    this.options = const <String>[],
  });

  final String text;
  final String type;
  final List<String> options;

  Map<String, dynamic> toApi() => {
    'text': text,
    'type': type,
    'options': options,
  };
}

class SurveyService {
  SurveyService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  static const uuid = Uuid();

  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  // Survey operations
  Future<Survey> createSurvey({
    required String title,
    String? description,
    String? creatorName,
    String? token,
    List<SurveyQuestionDraft> questions = const <SurveyQuestionDraft>[],
  }) async {
    final surveyId = uuid.v4();
    final now = DateTime.now();
    
    final surveyQuestions = questions.asMap().entries.map((entry) {
      final draft = entry.value;
      return Question(
        id: uuid.v4(),
        surveyId: surveyId,
        text: draft.text,
        type: draft.type,
        order: entry.key,
        options: draft.options,
      );
    }).toList();

    var survey = Survey(
      id: surveyId,
      title: title,
      description: description ?? '',
      creatorName: creatorName,
      createdAt: now,
      updatedAt: now,
      questionCount: surveyQuestions.length,
      syncStatus: SyncStatus.pending,
      questions: surveyQuestions,
    );

    // Always save locally first
    await _databaseHelper.upsertSurvey(survey);

    // Try to sync if online and token provided
    if (token != null && await _isOnline()) {
      try {
        final payload = await _apiClient.post(
          '/api/surveys',
          token: token,
          body: {
            'client_id': surveyId,
            'title': title,
            'description': description,
            'questions': questions.map((q) => q.toApi()).toList(),
          },
        );
        
        final remoteSurvey = Survey.fromApi(payload['data'] as Map<String, dynamic>);
        // Update local with remote info (like remoteId)
        survey = survey.copyWith(
          remoteId: remoteSurvey.remoteId,
          syncStatus: SyncStatus.synced,
        );
        await _databaseHelper.upsertSurvey(survey);
      } catch (e) {
        // Fallback to local only, already saved as pending
        print('Failed to sync survey: $e');
      }
    }

    return survey;
  }

  Future<List<Survey>> getAllSurveys() async {
    return _databaseHelper.getAllSurveys();
  }

  Future<Survey?> getSurvey(String id) async {
    return _databaseHelper.getSurvey(id);
  }

  Future<void> updateSurvey(Survey survey) async {
    final updated = survey.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );
    await _databaseHelper.upsertSurvey(updated);
  }

  Future<void> deleteSurvey(String id) async {
    await _databaseHelper.deleteSurvey(id);
  }

  // Response operations
  Future<SurveyResponse> saveResponse({
    required String surveyId,
    required Map<String, dynamic> responseData,
    double? latitude,
    double? longitude,
  }) async {
    final survey = await _databaseHelper.getSurvey(surveyId);
    final clientResponseId = uuid.v4();
    final response = SurveyResponse(
      id: clientResponseId,
      clientResponseId: clientResponseId,
      surveyId: surveyId,
      surveyRemoteId: survey?.remoteId ?? 0,
      answers: responseData,
      createdAt: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
    );

    await _databaseHelper.insertResponse(response);
    return response;
  }

  Future<List<SurveyResponse>> getResponsesBySurvey(String surveyId) async {
    return _databaseHelper.getResponsesBySurvey(surveyId);
  }

  Future<List<SurveyResponse>> getAllResponses() async {
    return _databaseHelper.getAllResponses();
  }

  Future<void> updateResponse(SurveyResponse response) async {
    await _databaseHelper.updateResponse(response);
  }

  Future<void> deleteResponse(String id) async {
    await _databaseHelper.deleteResponse(id);
  }

  // Sync operations
  Future<List<Survey>> getUnsyncedSurveys() async {
    return _databaseHelper.getUnsyncedSurveys();
  }

  Future<List<SurveyResponse>> getUnsyncedResponses() async {
    return _databaseHelper.getUnsyncedResponses();
  }

  Future<void> markSurveySynced(String id) async {
    await _databaseHelper.markSurveySynced(id);
  }

  Future<void> markResponseSynced(String id) async {
    await _databaseHelper.markResponseSynced(clientResponseId: id);
  }

  // Sync all data (call this when connection is restored)
  Future<void> syncAllData(String token) async {
    if (!await _isOnline()) return;

    // 1. Sync Pending Surveys
    final unsyncedSurveys = await getUnsyncedSurveys();
    for (var survey in unsyncedSurveys) {
      try {
        final payload = await _apiClient.post(
          '/api/surveys',
          token: token,
          body: {
            'client_id': survey.id,
            'title': survey.title,
            'description': survey.description,
            'questions': survey.questions.map((q) => q.toApi()).toList(),
          },
        );
        final remoteData = payload['data'] as Map<String, dynamic>;
        await _databaseHelper.markSurveySynced(survey.id, remoteId: remoteData['id'] as int?);
      } catch (e) {
        print('Error syncing survey ${survey.id}: $e');
      }
    }

    // 2. Sync Pending Responses
    final unsyncedResponses = await getUnsyncedResponses();
    if (unsyncedResponses.isNotEmpty) {
      try {
        final payload = await _apiClient.post(
          '/api/responses/batch', // Assuming a batch endpoint exists
          token: token,
          body: {
            'responses': unsyncedResponses.map((r) => r.toApi()).toList(),
          },
        );
        
        final results = payload['data'] as List<dynamic>? ?? [];
        for (var result in results) {
          final clientId = result['client_response_id'] as String?;
          if (clientId != null) {
            await markResponseSynced(clientId);
          }
        }
      } catch (e) {
        print('Error syncing responses: $e');
      }
    }
  }

  // Cleanup
  Future<void> clearAllData() async {
    await _databaseHelper.clearAllData();
  }

  Future<void> dispose() async {
    await _databaseHelper.closeDatabase();
  }
}
