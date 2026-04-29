import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../models/survey_model.dart';

class SurveyService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  static const uuid = Uuid();

  // Survey operations
  Future<Survey> createSurvey({
    required String title,
    String? description,
  }) async {
    final survey = Survey(
      id: uuid.v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _databaseHelper.insertSurvey(survey.toJson());
    return survey;
  }

  Future<List<Survey>> getAllSurveys() async {
    final maps = await _databaseHelper.getAllSurveys();
    return List.generate(
      maps.length,
      (i) => Survey.fromJson(maps[i]),
    );
  }

  Future<Survey?> getSurvey(String id) async {
    final map = await _databaseHelper.getSurvey(id);
    return map != null ? Survey.fromJson(map) : null;
  }

  Future<void> updateSurvey(Survey survey) async {
    final updated = survey.copyWith(updatedAt: DateTime.now());
    await _databaseHelper.updateSurvey(updated.toJson());
  }

  Future<void> deleteSurvey(String id) async {
    await _databaseHelper.deleteSurvey(id);
  }

  // Response operations
  Future<SurveyResponse> saveResponse({
    required String surveyId,
    required Map<String, dynamic> responseData,
  }) async {
    final response = SurveyResponse(
      id: uuid.v4(),
      surveyId: surveyId,
      data: responseData,
      createdAt: DateTime.now(),
    );

    await _databaseHelper.insertResponse(response.toJson());
    return response;
  }

  Future<List<SurveyResponse>> getResponsesBySurvey(String surveyId) async {
    final maps = await _databaseHelper.getResponsesBySurvey(surveyId);
    return List.generate(
      maps.length,
      (i) => SurveyResponse.fromJson(maps[i]),
    );
  }

  Future<List<SurveyResponse>> getAllResponses() async {
    final maps = await _databaseHelper.getAllResponses();
    return List.generate(
      maps.length,
      (i) => SurveyResponse.fromJson(maps[i]),
    );
  }

  Future<void> updateResponse(SurveyResponse response) async {
    await _databaseHelper.updateResponse(response.toJson());
  }

  Future<void> deleteResponse(String id) async {
    await _databaseHelper.deleteResponse(id);
  }

  // Sync operations
  Future<List<Survey>> getUnsyncedSurveys() async {
    final maps = await _databaseHelper.getUnsyncedSurveys();
    return List.generate(
      maps.length,
      (i) => Survey.fromJson(maps[i]),
    );
  }

  Future<List<SurveyResponse>> getUnsyncedResponses() async {
    final maps = await _databaseHelper.getUnsyncedResponses();
    return List.generate(
      maps.length,
      (i) => SurveyResponse.fromJson(maps[i]),
    );
  }

  Future<void> markSurveySynced(String id) async {
    await _databaseHelper.markSurveySynced(id);
  }

  Future<void> markResponseSynced(String id) async {
    await _databaseHelper.markResponseSynced(id);
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
