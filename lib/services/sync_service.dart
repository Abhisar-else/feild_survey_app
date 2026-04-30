import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/user_session.dart';
import 'api_client.dart';
import 'survey_repository.dart';

class SyncResult {
  const SyncResult({
    required this.syncedCount,
    this.message,
    this.offline = false,
  });

  final int syncedCount;
  final String? message;
  final bool offline;
}

class SyncService {
  SyncService({
    required SurveyRepository repository,
    Connectivity? connectivity,
  })  : _repository = repository,
        _connectivity = connectivity ?? Connectivity();

  final SurveyRepository _repository;
  final Connectivity _connectivity;

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<SyncResult> syncPendingResponses(UserSession session) async {
    if (!await isOnline) {
      return const SyncResult(
        syncedCount: 0,
        offline: true,
        message: 'No network connection. Responses remain queued.',
      );
    }

    try {
      final count = await _repository.syncPendingResponses(session);
      return SyncResult(syncedCount: count);
    } on ApiException catch (error) {
      await _repository.markAllPendingFailed(error.message);
      return SyncResult(syncedCount: 0, message: error.message);
    }
  }
}
