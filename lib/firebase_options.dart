import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// Project: survey-app-767fc
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      default: throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAZ4Y-z6C_TOh1KmS3HBbBBxVmNpV1jrtA',
    appId: '1:595229626690:web:7c14e365000fac0986f8db', // Using Android ID as placeholder for web if not set
    messagingSenderId: '595229626690',
    projectId: 'survey-app-767fc',
    authDomain: 'survey-app-767fc.firebaseapp.com',
    storageBucket: 'survey-app-767fc.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZ4Y-z6C_TOh1KmS3HBbBBxVmNpV1jrtA',
    appId: '1:595229626690:android:7c14e365000fac0986f8db',
    messagingSenderId: '595229626690',
    projectId: 'survey-app-767fc',
    storageBucket: 'survey-app-767fc.firebasestorage.app',
  );
}
