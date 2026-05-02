import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:feild_survey_app/database_helper.dart';
import 'package:feild_survey_app/models/survey_model.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() {
    // Initialize FFI for sqflite so it works on desktop environments like the test runner
    sqfliteFfiInit();
  });

  setUp(() async {
    // Use an in-memory database specifically for testing
    dbHelper = DatabaseHelper(
      databaseName: inMemoryDatabasePath,
      databaseFactoryOverride: databaseFactoryFfi,
    );
  });

  tearDown(() async {
    await dbHelper.closeDatabase();
  });

  test('upsertSurvey inserts and retrieves a survey successfully', () async {
    final now = DateTime.now();
    final survey = Survey(
      id: 'survey_test_1',
      remoteId: 1,
      title: 'Local Test Survey',
      description: 'Testing SQLite locally',
      createdAt: now,
      updatedAt: now,
      questions: [
        Question(
          id: 'q1',
          surveyId: 'survey_test_1',
          text: 'How is the testing going?',
          type: 'text',
          order: 0,
        ),
      ],
    );

    // Insert survey
    await dbHelper.upsertSurvey(survey);

    // Retrieve surveys
    final retrievedSurveys = await dbHelper.getAllSurveys();

    expect(retrievedSurveys.length, 1);
    expect(retrievedSurveys.first.id, 'survey_test_1');
    expect(retrievedSurveys.first.title, 'Local Test Survey');
    expect(retrievedSurveys.first.questions.length, 1);
    expect(retrievedSurveys.first.questions.first.text, 'How is the testing going?');
  });

  test('insertResponse stores a response correctly and can be retrieved', () async {
    final now = DateTime.now();
    final response = SurveyResponse(
      id: 'response_test_1',
      clientResponseId: 'client_resp_test_1',
      surveyId: 'survey_test_1',
      surveyRemoteId: 1,
      answers: {'q1': 'Great!'},
      createdAt: now,
    );

    // Insert response
    await dbHelper.insertResponse(response);

    // Retrieve responses
    final retrievedResponses = await dbHelper.getAllResponses();

    expect(retrievedResponses.length, 1);
    expect(retrievedResponses.first.id, 'response_test_1');
    expect(retrievedResponses.first.surveyRemoteId, 1);
    expect(retrievedResponses.first.answers['q1'], 'Great!');
    expect(retrievedResponses.first.syncStatus, SyncStatus.pending);
  });

  test('markResponseSynced updates sync status', () async {
    final now = DateTime.now();
    final response = SurveyResponse(
      id: 'response_test_2',
      clientResponseId: 'client_resp_test_2',
      surveyId: 'survey_test_1',
      surveyRemoteId: 1,
      answers: {'q1': 'Testing sync update'},
      createdAt: now,
    );

    await dbHelper.insertResponse(response);
    
    // Mark as synced
    await dbHelper.markResponseSynced(clientResponseId: 'client_resp_test_2', remoteId: 99);
    
    final responses = await dbHelper.getAllResponses();
    final syncedResponse = responses.firstWhere((r) => r.id == 'response_test_2');
    
    expect(syncedResponse.syncStatus, SyncStatus.synced);
    expect(syncedResponse.remoteId, 99);
  });
}
