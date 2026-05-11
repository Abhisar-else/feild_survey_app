import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  SurveyService({ApiClient? apiClient}) 
    : _apiClient = apiClient ?? ApiClient(),
      _firestore = FirebaseFirestore.instance;

  final ApiClient _apiClient;
  final FirebaseFirestore _firestore;
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

    // Try to sync to Firestore if online
    if (await _isOnline()) {
      try {
        final surveyData = survey.toDatabase();
        surveyData['questions'] = survey.questions.map((q) => q.toDatabase()).toList();
        
        await _firestore.collection('surveys').doc(surveyId).set(surveyData);
        survey = survey.copyWith(syncStatus: SyncStatus.synced);
        await _databaseHelper.upsertSurvey(survey);
      } catch (e) {
        print('Failed to sync survey: $e');
      }
    }

    return survey;
  }

  Future<List<Survey>> getAllSurveys() async {
    if (await _isOnline()) {
      try {
        final snapshot = await _firestore.collection('surveys').get();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final List<Question> questions = [];
          if (data['questions'] != null) {
            final rawQuestions = data['questions'] as List;
            for (var q in rawQuestions) {
              questions.add(Question.fromDatabase(q as Map<String, dynamic>));
            }
          }
          final survey = Survey.fromDatabase(data, questions: questions);
          // When pulling from cloud, mark as synced
          final syncedSurvey = survey.copyWith(syncStatus: SyncStatus.synced);
          await _databaseHelper.upsertSurvey(syncedSurvey);
        }
      } catch (e) {
        print('Cloud Survey Pull Error: $e');
      }
    }
    return _databaseHelper.getAllSurveys();
  }

  Future<Survey?> getSurvey(String id) async {
    final localSurvey = await _databaseHelper.getSurvey(id);
    if (localSurvey != null && localSurvey.questions.isNotEmpty) return localSurvey;

    if (await _isOnline()) {
      try {
        final doc = await _firestore.collection('surveys').doc(id).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final List<Question> questions = [];
          if (data['questions'] != null) {
            final rawQuestions = data['questions'] as List;
            for (var q in rawQuestions) {
              questions.add(Question.fromDatabase(q as Map<String, dynamic>));
            }
          }
          final survey = Survey.fromDatabase(data, questions: questions);
          final syncedSurvey = survey.copyWith(syncStatus: SyncStatus.synced);
          await _databaseHelper.upsertSurvey(syncedSurvey);
          return syncedSurvey;
        }
      } catch (e) {
        print('Cloud Survey Detail Error: $e');
      }
    }
    return localSurvey;
  }

  Future<void> updateSurvey(Survey survey) async {
    final updated = survey.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );
    await _databaseHelper.upsertSurvey(updated);
    
    if (await _isOnline()) {
      try {
        final surveyData = updated.toDatabase();
        surveyData['questions'] = updated.questions.map((q) => q.toDatabase()).toList();
        await _firestore.collection('surveys').doc(survey.id).set(surveyData);
        await _databaseHelper.markSurveySynced(survey.id);
      } catch (e) {
        print('Update sync failed: $e');
      }
    }
  }

  Future<void> deleteSurvey(String id) async {
    await _databaseHelper.deleteSurvey(id);
    if (await _isOnline()) {
      _firestore.collection('surveys').doc(id).delete().catchError((e) => print(e));
    }
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
    
    if (await _isOnline()) {
      try {
        final responseData = response.toDatabase();
        responseData['sync_status'] = SyncStatus.synced.value; // Mark as synced for cloud
        await _firestore.collection('responses').doc(clientResponseId).set(responseData);
        await _databaseHelper.markResponseSynced(clientResponseId: clientResponseId);
      } catch (e) {
        print('Response cloud push failed: $e');
      }
    }
    
    return response;
  }

  Future<List<SurveyResponse>> getResponsesBySurvey(String surveyId) async {
    if (await _isOnline()) {
      try {
        final snapshot = await _firestore
            .collection('responses')
            .where('survey_id', isEqualTo: surveyId)
            .get();
        for (var doc in snapshot.docs) {
          final response = SurveyResponse.fromDatabase(doc.data());
          final syncedResponse = response.copyWith(syncStatus: SyncStatus.synced);
          await _databaseHelper.insertResponse(syncedResponse);
        }
      } catch (e) {
        print('Cloud Responses Pull Error: $e');
      }
    }
    return _databaseHelper.getResponsesBySurvey(surveyId);
  }

  Future<List<SurveyResponse>> getAllResponses() async {
    if (await _isOnline()) {
      try {
        final snapshot = await _firestore.collection('responses').get();
        for (var doc in snapshot.docs) {
          final response = SurveyResponse.fromDatabase(doc.data());
          final syncedResponse = response.copyWith(syncStatus: SyncStatus.synced);
          await _databaseHelper.insertResponse(syncedResponse);
        }
      } catch (e) {
        print('Global Cloud Pull Error: $e');
      }
    }
    return _databaseHelper.getAllResponses();
  }

  Future<void> updateResponse(SurveyResponse response) async {
    await _databaseHelper.updateResponse(response);
  }

  Future<void> deleteResponse(String id) async {
    await _databaseHelper.deleteResponse(id);
  }

  // Draft operations
  Future<void> saveDraft(String surveyId, Map<String, dynamic> answers) async {
    await _databaseHelper.saveDraft(surveyId, answers);
  }

  Future<Map<String, dynamic>?> getDraft(String surveyId) async {
    return _databaseHelper.getDraft(surveyId);
  }

  Future<void> deleteDraft(String surveyId) async {
    await _databaseHelper.deleteDraft(surveyId);
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

    final unsyncedSurveys = await getUnsyncedSurveys();
    for (var survey in unsyncedSurveys) {
      try {
        final surveyData = survey.toDatabase();
        surveyData['questions'] = survey.questions.map((q) => q.toDatabase()).toList();
        await _firestore.collection('surveys').doc(survey.id).set(surveyData);
        await _databaseHelper.markSurveySynced(survey.id);
      } catch (e) {
        print('Sync survey failed: $e');
      }
    }

    final unsyncedResponses = await getUnsyncedResponses();
    for (var response in unsyncedResponses) {
      try {
        final responseData = response.toDatabase();
        responseData['sync_status'] = SyncStatus.synced.value;
        await _firestore.collection('responses').doc(response.clientResponseId).set(responseData);
        await _databaseHelper.markResponseSynced(clientResponseId: response.clientResponseId);
      } catch (e) {
        print('Sync response failed: $e');
      }
    }
  }

  Future<void> clearAllData() async {
    await _databaseHelper.clearAllData();
  }

  Future<void> dispose() async {
    await _databaseHelper.closeDatabase();
  }
}
