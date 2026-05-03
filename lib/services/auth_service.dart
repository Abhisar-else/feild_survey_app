import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

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

abstract class AuthServiceBase {
  Future<UserSession> login({required String email, required String password});
  Future<UserSession> register({required String name, required String email, required String password});
  Future<UserSession?> currentSession({bool validate = true});
  Future<void> logout();
}

class AuthService implements AuthServiceBase {
  AuthService({
    required ApiClient apiClient,
    SessionStore? sessionStore,
    fb_auth.FirebaseAuth? firebaseAuth,
  })  : _apiClient = apiClient,
        _sessionStore = sessionStore ?? SecureSessionStore(),
        _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance;

  static final AuthService instance = AuthService(apiClient: ApiClient());

  final ApiClient _apiClient;
  final SessionStore _sessionStore;
  final fb_auth.FirebaseAuth _firebaseAuth;

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Try Firebase Authentication
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Firebase login failed: User is null');

      // 2. Create session from Firebase user
      final idToken = await user.getIdToken() ?? '';
      final session = UserSession(
        token: idToken,
        id: user.uid,
        name: user.displayName ?? 'User',
        email: user.email ?? email,
        role: 'field_worker', // Default role for Firebase users
      );

      await _sessionStore.save(session);
      return session;
    } on fb_auth.FirebaseAuthException catch (e) {
      // Fallback to legacy API if Firebase is not configured or user not found there
      if (e.code == 'api-not-available' || e.code == 'invalid-api-key') {
         return _legacyLogin(email: email, password: password);
      }
      rethrow;
    } catch (e) {
      // If Firebase fails (e.g. not configured), try legacy login
      debugPrint('Firebase Auth failed, trying legacy API: $e');
      return _legacyLogin(email: email, password: password);
    }
  }

  Future<UserSession> _legacyLogin({required String email, required String password}) async {
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
  Future<UserSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Registration failed');

      await user.updateDisplayName(name);
      final idToken = await user.getIdToken() ?? '';

      final session = UserSession(
        token: idToken,
        id: user.uid,
        name: name,
        email: email,
        role: 'field_worker',
      );

      await _sessionStore.save(session);
      return session;
    } catch (e) {
      // Try legacy register
      final payload = await _apiClient.post(
        '/api/auth/register',
        body: {
          'name': name,
          'email': email.trim(),
          'password': password,
        },
      );
      final session = UserSession.fromAuthResponse(payload);
      await _sessionStore.save(session);
      return session;
    }
  }

  @override
  Future<UserSession?> currentSession({bool validate = true}) async {
    // Check persistent store first
    final session = await _sessionStore.read();
    
    // Also check Firebase current user
    final fbUser = _firebaseAuth.currentUser;

    if (fbUser != null) {
      final idToken = await fbUser.getIdToken();
      return UserSession(
        token: idToken ?? '',
        id: fbUser.uid,
        name: fbUser.displayName ?? 'User',
        email: fbUser.email ?? '',
        role: 'field_worker',
      );
    }

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
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _sessionStore.clear();
  }
}
