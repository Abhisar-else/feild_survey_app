# SQLite Offline Storage Setup Guide

## ✅ What Was Added

Your Flutter Survey App now supports **complete offline functionality** with SQLite database integration.

### New Dependencies
- **sqflite**: ^2.3.0 - SQLite plugin for Flutter
- **path**: ^1.8.3 - File path handling
- **uuid**: ^4.0.0 - Unique ID generation

### New Files Created

1. **`lib/database_helper.dart`**
   - Core SQLite database management
   - Creates surveys and responses tables
   - Provides CRUD operations

2. **`lib/models/survey_model.dart`**
   - Survey model with JSON serialization
   - SurveyResponse model for storing responses
   - copyWith methods for immutability

3. **`lib/services/survey_service.dart`**
   - High-level API for survey operations
   - Offline data management
   - Sync operations for cloud synchronization

## 🚀 How to Use

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Create a Survey (Offline)
```dart
import 'services/survey_service.dart';

final surveyService = SurveyService();

// Create survey offline
final survey = await surveyService.createSurvey(
  title: 'Customer Satisfaction',
  description: 'Rate your experience',
);
```

### 3. Save Survey Responses
```dart
await surveyService.saveResponse(
  surveyId: survey.id,
  responseData: {
    'question_1': 'Great experience!',
    'question_2': 'Would recommend',
  },
);
```

### 4. Retrieve Surveys
```dart
// Get all surveys
final surveys = await surveyService.getAllSurveys();

// Get responses for a specific survey
final responses = await surveyService.getResponsesBySurvey(surveyId);
```

### 5. Sync with Server (When Online)
```dart
// Get unsynced data
final unsyncedSurveys = await surveyService.getUnsyncedSurveys();
final unsyncedResponses = await surveyService.getUnsyncedResponses();

// Send to your backend API
// Then mark as synced
await surveyService.markSurveySynced(surveyId);
await surveyService.markResponseSynced(responseId);
```

## 📱 How It Works

### Database Schema

**Surveys Table**
```
- id (TEXT, Primary Key)
- title (TEXT)
- description (TEXT)
- created_at (TEXT)
- updated_at (TEXT)
- synced (INTEGER - 0/1)
```

**Responses Table**
```
- id (TEXT, Primary Key)
- survey_id (TEXT, Foreign Key)
- data (TEXT - JSON data)
- created_at (TEXT)
- synced (INTEGER - 0/1)
```

### Sync Flag System
- `synced = 0`: Data pending server synchronization
- `synced = 1`: Data successfully synced to server

## 🔄 Integration with Backend

Update your backend API calls to handle sync:

```dart
// In survey_service.dart, update the syncAllData method:
Future<void> syncAllData() async {
  final unsyncedSurveys = await getUnsyncedSurveys();
  final unsyncedResponses = await getUnsyncedResponses();

  for (var survey in unsyncedSurveys) {
    try {
      // Call your API
      await ApiService.pushSurvey(survey);
      await markSurveySynced(survey.id);
    } catch (e) {
      // Handle error - data remains unsynced
      print('Sync error: $e');
    }
  }
}
```

## 📝 Updated Files

- **`pubspec.yaml`**: Added sqflite, path, and uuid dependencies
- **`lib/survey_form.dart`**: Integrated offline storage on save

Now surveys are automatically saved locally when created! 🎉

## 🛠️ Next Steps

1. Connect to your backend API in `survey_service.dart`
2. Implement network connectivity detection
3. Add auto-sync when connection is restored
4. Test offline/online scenarios
