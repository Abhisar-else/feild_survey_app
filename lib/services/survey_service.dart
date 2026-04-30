import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../models/survey_model.dart';

class SurveyQuestionDraft {
  const SurveyQuestionDraft({
    required this.text,
    required this.type,
    this.options = const <String>[],
  });

  final String text;
  final String type;
  final List<String> options;
}

class SurveyService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  static const uuid = Uuid();

  // Survey operations
  Future<Survey> createSurvey({
    required String title,
    String? description,
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

    final survey = Survey(
      id: surveyId,
      title: title,
      description: description ?? '',
      createdAt: now,
      updatedAt: now,
      questionCount: surveyQuestions.length,
      syncStatus: SyncStatus.pending,
      questions: surveyQuestions,
    );

    await _databaseHelper.upsertSurvey(survey);
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
  Future<void> syncAllData() async {
    // Get unsynced surveys and responses
    final unsyncedSurveys = await getUnsyncedSurveys();
    final unsyncedResponses = await getUnsyncedResponses();

    // Send to server (implement your API calls here)
    // After successful sync, mark as synced
    for (var survey in unsyncedSurveys) {
      // await _api.syncSurvey(survey);
      await markSurveySynced(survey.id);
    }

    for (var response in unsyncedResponses) {
      // await _api.syncResponse(response);
      await markResponseSynced(response.id);
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
