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

      // Refresh user to get latest profile info
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser ?? user;

      // 2. Create session from Firebase user
      final idToken = await refreshedUser.getIdToken() ?? '';
      final session = UserSession(
        token: idToken,
        id: refreshedUser.uid,
        name: (refreshedUser.displayName != null && refreshedUser.displayName!.isNotEmpty)
            ? refreshedUser.displayName!
            : 'User',
        email: refreshedUser.email ?? email,
        role: 'field_worker', // Default role for Firebase users
      );

      await _sessionStore.save(session);
      return session;
    } on fb_auth.FirebaseAuthException catch (e) {
      // Return a human-friendly error from Firebase
      throw Exception(e.message ?? 'Authentication failed');
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
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
      await user.reload();
      
      final updatedUser = _firebaseAuth.currentUser ?? user;
      final idToken = await updatedUser.getIdToken() ?? '';

      final session = UserSession(
        token: idToken,
        id: updatedUser.uid,
        name: updatedUser.displayName ?? name,
        email: updatedUser.email ?? email,
        role: 'field_worker',
      );

      await _sessionStore.save(session);
      return session;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    } catch (e) {
      debugPrint('Registration failed: $e');
      rethrow;
    }
  }

  @override
  Future<UserSession?> currentSession({bool validate = true}) async {
    // Also check Firebase current user
    final fbUser = _firebaseAuth.currentUser;
    
    // Check persistent store
    UserSession? storedSession = await _sessionStore.read();

    if (fbUser != null) {
      final idToken = await fbUser.getIdToken();
      
      // If Firebase doesn't have a name yet, try to refresh it
      if (fbUser.displayName == null || fbUser.displayName!.isEmpty) {
        await fbUser.reload();
      }
      
      final refreshedUser = _firebaseAuth.currentUser ?? fbUser;
      
      // Determine the best name to use
      String name = 'User';
      if (refreshedUser.displayName != null && refreshedUser.displayName!.isNotEmpty) {
        name = refreshedUser.displayName!;
      } else if (storedSession != null && storedSession.name.isNotEmpty && storedSession.name != 'User') {
        name = storedSession.name;
      } else if (refreshedUser.email != null && refreshedUser.email!.isNotEmpty) {
        name = refreshedUser.email!.split('@').first;
      }

      final session = UserSession(
        token: idToken ?? storedSession?.token ?? '',
        id: refreshedUser.uid,
        name: name,
        email: refreshedUser.email ?? storedSession?.email ?? '',
        role: storedSession?.role ?? 'field_worker',
      );

      // Keep the store in sync
      if (storedSession == null || storedSession.name != name) {
        await _sessionStore.save(session);
      }
      
      return session;
    }

    if (storedSession == null || storedSession.token.isEmpty) return null;
    if (!validate) return storedSession;

    try {
      final payload = await _apiClient.get('/api/auth/me', token: storedSession.token);
      final data = payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final validated = storedSession.copyWithUser(data['user'] as Map<String, dynamic>? ?? data);
      await _sessionStore.save(validated);
      return validated;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await logout();
        return null;
      }
      return storedSession;
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _sessionStore.clear();
  }
}
