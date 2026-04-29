import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'survey_app.db';
  static const _databaseVersion = 1;

  // Table names
  static const String surveyTable = 'surveys';
  static const String responseTable = 'responses';

  // Survey columns
  static const String surveyId = 'id';
  static const String surveyTitle = 'title';
  static const String surveyDescription = 'description';
  static const String surveyCreatedAt = 'created_at';
  static const String surveyUpdatedAt = 'updated_at';
  static const String surveySynced = 'synced';

  // Response columns
  static const String responseId = 'id';
  static const String responseSurveyId = 'survey_id';
  static const String responseData = 'data';
  static const String responseCreatedAt = 'created_at';
  static const String responseSynced = 'synced';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create surveys table
    await db.execute('''
      CREATE TABLE $surveyTable (
        $surveyId TEXT PRIMARY KEY,
        $surveyTitle TEXT NOT NULL,
        $surveyDescription TEXT,
        $surveyCreatedAt TEXT,
        $surveyUpdatedAt TEXT,
        $surveySynced INTEGER DEFAULT 0
      )
    ''');

    // Create responses table
    await db.execute('''
      CREATE TABLE $responseTable (
        $responseId TEXT PRIMARY KEY,
        $responseSurveyId TEXT NOT NULL,
        $responseData TEXT NOT NULL,
        $responseCreatedAt TEXT,
        $responseSynced INTEGER DEFAULT 0,
        FOREIGN KEY ($responseSurveyId) REFERENCES $surveyTable ($surveyId)
      )
    ''');
  }

  // Survey operations
  Future<int> insertSurvey(Map<String, dynamic> survey) async {
    final db = await database;
    return await db.insert(surveyTable, survey);
  }

  Future<List<Map<String, dynamic>>> getAllSurveys() async {
    final db = await database;
    return await db.query(surveyTable);
  }

  Future<Map<String, dynamic>?> getSurvey(String id) async {
    final db = await database;
    final result = await db.query(
      surveyTable,
      where: '$surveyId = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateSurvey(Map<String, dynamic> survey) async {
    final db = await database;
    return await db.update(
      surveyTable,
      survey,
      where: '$surveyId = ?',
      whereArgs: [survey[surveyId]],
    );
  }

  Future<int> deleteSurvey(String id) async {
    final db = await database;
    return await db.delete(
      surveyTable,
      where: '$surveyId = ?',
      whereArgs: [id],
    );
  }

  // Response operations
  Future<int> insertResponse(Map<String, dynamic> response) async {
    final db = await database;
    return await db.insert(responseTable, response);
  }

  Future<List<Map<String, dynamic>>> getResponsesBySurvey(String surveyId) async {
    final db = await database;
    return await db.query(
      responseTable,
      where: '$responseSurveyId = ?',
      whereArgs: [surveyId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllResponses() async {
    final db = await database;
    return await db.query(responseTable);
  }

  Future<int> updateResponse(Map<String, dynamic> response) async {
    final db = await database;
    return await db.update(
      responseTable,
      response,
      where: '$responseId = ?',
      whereArgs: [response[responseId]],
    );
  }

  Future<int> deleteResponse(String id) async {
    final db = await database;
    return await db.delete(
      responseTable,
      where: '$responseId = ?',
      whereArgs: [id],
    );
  }

  // Sync operations
  Future<List<Map<String, dynamic>>> getUnsyncedSurveys() async {
    final db = await database;
    return await db.query(
      surveyTable,
      where: '$surveySynced = ?',
      whereArgs: [0],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedResponses() async {
    final db = await database;
    return await db.query(
      responseTable,
      where: '$responseSynced = ?',
      whereArgs: [0],
    );
  }

  Future<int> markSurveySynced(String id) async {
    final db = await database;
    return await db.update(
      surveyTable,
      {surveySynced: 1},
      where: '$surveyId = ?',
      whereArgs: [id],
    );
  }

  Future<int> markResponseSynced(String id) async {
    final db = await database;
    return await db.update(
      responseTable,
      {responseSynced: 1},
      where: '$responseId = ?',
      whereArgs: [id],
    );
  }

  // Utility
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(responseTable);
    await db.delete(surveyTable);
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
