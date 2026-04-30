import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_session.dart';
import 'api_client.dart';

abstract class SessionStore {
  Future<void> save(UserSession session);
  Future<UserSession?> read();
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'field_survey_session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> save(UserSession session) {
    return _storage.write(key: _sessionKey, value: session.encode());
  }

  @override
  Future<UserSession?> read() async {
    final value = await _storage.read(key: _sessionKey);
    if (value == null || value.isEmpty) return null;
    return UserSession.fromEncoded(value);
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _sessionKey);
  }
}

class MemorySessionStore implements SessionStore {
  UserSession? _session;

  @override
  Future<void> save(UserSession session) async {
    _session = session;
  }

  @override
  Future<UserSession?> read() async => _session;

  @override
  Future<void> clear() async {
    _session = null;
  }
}

abstract class AuthServiceBase {
  Future<UserSession> login({required String email, required String password});
  Future<UserSession?> currentSession({bool validate = true});
  Future<void> logout();
}

class AuthService implements AuthServiceBase {
  AuthService({
    required ApiClient apiClient,
    SessionStore? sessionStore,
  })  : _apiClient = apiClient,
        _sessionStore = sessionStore ?? SecureSessionStore();

  final ApiClient _apiClient;
  final SessionStore _sessionStore;

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final payload = await _apiClient.post(
      '/api/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
    );
    final session = UserSession.fromAuthResponse(payload);
    await _sessionStore.save(session);
    return session;
  }

  @override
  Future<UserSession?> currentSession({bool validate = true}) async {
    final session = await _sessionStore.read();
    if (session == null || session.token.isEmpty) return null;
    if (!validate) return session;

    try {
      final payload = await _apiClient.get('/api/auth/me', token: session.token);
      final data = payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final validated = session.copyWithUser(data['user'] as Map<String, dynamic>? ?? data);
      await _sessionStore.save(validated);
      return validated;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await logout();
        return null;
      }
      return session;
    }
  }

  @override
  Future<void> logout() {
    return _sessionStore.clear();
  }
}
