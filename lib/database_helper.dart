import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/survey_model.dart';

class DatabaseHelper {
  DatabaseHelper({
    this.databaseName = 'survey_app.db',
    this.databaseFactoryOverride,
    this.databasePathOverride,
  });

  static const int databaseVersion = 3;

  static const String surveyTable = 'surveys';
  static const String questionTable = 'questions';
  static const String responseTable = 'responses';

  final String databaseName;
  final DatabaseFactory? databaseFactoryOverride;
  final String? databasePathOverride;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final options = OpenDatabaseOptions(
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    if (databaseFactoryOverride != null) {
      return databaseFactoryOverride!.openDatabase(
        databasePathOverride ?? databaseName,
        options: options,
      );
    }

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, databaseName);
    return databaseFactory.openDatabase(path, options: options);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSchema(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _dropSchema(db);
      await _createSchema(db);
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $surveyTable (
        id TEXT PRIMARY KEY,
        remote_id INTEGER UNIQUE,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        creator_name TEXT,
        question_count INTEGER NOT NULL DEFAULT 0,
        response_count INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        synced INTEGER NOT NULL DEFAULT 1,
        last_sync_error TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $questionTable (
        id TEXT PRIMARY KEY,
        remote_id INTEGER,
        survey_id TEXT NOT NULL,
        text TEXT NOT NULL,
        type TEXT NOT NULL,
        options TEXT NOT NULL DEFAULT '[]',
        question_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (survey_id) REFERENCES $surveyTable (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $responseTable (
        id TEXT PRIMARY KEY,
        remote_id INTEGER,
        client_response_id TEXT NOT NULL UNIQUE,
        survey_id TEXT NOT NULL,
        survey_remote_id INTEGER NOT NULL,
        answers TEXT NOT NULL,
        created_at TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        synced INTEGER NOT NULL DEFAULT 0,
        last_sync_error TEXT,
        FOREIGN KEY (survey_id) REFERENCES $surveyTable (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_questions_survey ON $questionTable (survey_id)',
    );
    await db.execute(
      'CREATE INDEX idx_responses_survey ON $responseTable (survey_id)',
    );
    await db.execute(
      'CREATE INDEX idx_responses_sync ON $responseTable (sync_status)',
    );
  }

  Future<void> _dropSchema(Database db) async {
    await db.execute('DROP TABLE IF EXISTS $responseTable');
    await db.execute('DROP TABLE IF EXISTS $questionTable');
    await db.execute('DROP TABLE IF EXISTS $surveyTable');
  }

  Future<void> cacheSurveys(List<Survey> surveys) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final survey in surveys) {
        await _upsertSurvey(txn, survey);
      }
    });
  }

  Future<void> upsertSurvey(Survey survey) async {
    final db = await database;
    await db.transaction((txn) => _upsertSurvey(txn, survey));
  }

  Future<void> _upsertSurvey(Transaction txn, Survey survey) async {
    await txn.insert(
      surveyTable,
      survey.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await txn.delete(
      questionTable,
      where: 'survey_id = ?',
      whereArgs: [survey.id],
    );

    for (final question in survey.questions) {
      await txn.insert(
        questionTable,
        question.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Survey>> getAllSurveys() async {
    final db = await database;
    final maps = await db.query(surveyTable, orderBy: 'created_at DESC');
    final surveys = <Survey>[];
    for (final map in maps) {
      final questions = await getQuestionsForSurvey(map['id'] as String);
      surveys.add(Survey.fromDatabase(map, questions: questions));
    }
    return surveys;
  }

  Future<Survey?> getSurvey(String id) async {
    final db = await database;
    final result = await db.query(
      surveyTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    final questions = await getQuestionsForSurvey(id);
    return Survey.fromDatabase(result.first, questions: questions);
  }

  Future<List<Survey>> getUnsyncedSurveys() async {
    final db = await database;
    final maps = await db.query(
      surveyTable,
      where: 'sync_status IN (?, ?) OR synced = ?',
      whereArgs: [SyncStatus.pending.value, SyncStatus.failed.value, 0],
      orderBy: 'updated_at ASC',
    );
    final surveys = <Survey>[];
    for (final map in maps) {
      final questions = await getQuestionsForSurvey(map['id'] as String);
      surveys.add(Survey.fromDatabase(map, questions: questions));
    }
    return surveys;
  }

  Future<void> markSurveySynced(String id, {int? remoteId}) async {
    final db = await database;
    final values = <String, Object?>{
      'sync_status': SyncStatus.synced.value,
      'synced': 1,
      'last_sync_error': null,
    };
    if (remoteId != null) {
      values['remote_id'] = remoteId;
    }

    await db.update(surveyTable, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSurvey(String id) async {
    final db = await database;
    await db.delete(surveyTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Question>> getQuestionsForSurvey(String surveyId) async {
    final db = await database;
    final maps = await db.query(
      questionTable,
      where: 'survey_id = ?',
      whereArgs: [surveyId],
      orderBy: 'question_order ASC',
    );
    return maps.map(Question.fromDatabase).toList();
  }

  Future<int> surveyCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $surveyTable',
    );
    return result.first['total'] as int? ?? 0;
  }

  Future<void> insertResponse(SurveyResponse response) async {
    final db = await database;
    await db.insert(
      responseTable,
      response.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<SurveyResponse>> getResponsesBySurvey(String surveyId) async {
    final db = await database;
    final maps = await db.query(
      responseTable,
      where: 'survey_id = ?',
      whereArgs: [surveyId],
      orderBy: 'created_at DESC',
    );
    return maps.map(SurveyResponse.fromDatabase).toList();
  }

  Future<List<SurveyResponse>> getAllResponses() async {
    final db = await database;
    final maps = await db.query(responseTable, orderBy: 'created_at DESC');
    return maps.map(SurveyResponse.fromDatabase).toList();
  }

  Future<List<SurveyResponse>> getPendingResponses() async {
    final db = await database;
    final maps = await db.query(
      responseTable,
      where: 'sync_status IN (?, ?)',
      whereArgs: [SyncStatus.pending.value, SyncStatus.failed.value],
      orderBy: 'created_at ASC',
    );
    return maps.map(SurveyResponse.fromDatabase).toList();
  }

  Future<List<SurveyResponse>> getUnsyncedResponses() {
    return getPendingResponses();
  }

  Future<int> pendingResponseCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $responseTable WHERE sync_status IN (?, ?)',
      [SyncStatus.pending.value, SyncStatus.failed.value],
    );
    return result.first['total'] as int? ?? 0;
  }

  Future<void> markResponseSynced({
    required String clientResponseId,
    int? remoteId,
  }) async {
    final db = await database;
    await db.update(
      responseTable,
      {
        'remote_id': remoteId,
        'sync_status': SyncStatus.synced.value,
        'synced': 1,
        'last_sync_error': null,
      },
      where: 'client_response_id = ?',
      whereArgs: [clientResponseId],
    );
  }

  Future<void> markResponseFailed({
    required String clientResponseId,
    required String error,
  }) async {
    final db = await database;
    await db.update(
      responseTable,
      {
        'sync_status': SyncStatus.failed.value,
        'synced': 0,
        'last_sync_error': error,
      },
      where: 'client_response_id = ?',
      whereArgs: [clientResponseId],
    );
  }

  Future<void> updateResponse(SurveyResponse response) async {
    final db = await database;
    await db.update(
      responseTable,
      response.toDatabase(),
      where: 'id = ?',
      whereArgs: [response.id],
    );
  }

  Future<void> deleteResponse(String id) async {
    final db = await database;
    await db.delete(responseTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(responseTable);
    await db.delete(questionTable);
    await db.delete(surveyTable);
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db == null) return;
    await db.close();
    _database = null;
  }
}
