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
    apiKey: 'PASTE_YOUR_API_KEY_HERE',
    appId: 'PASTE_YOUR_APP_ID_HERE',
    messagingSenderId: 'PASTE_YOUR_SENDER_ID_HERE',
    projectId: 'survey-app-767fc',
    authDomain: 'survey-app-767fc.firebaseapp.com',
    storageBucket: 'survey-app-767fc.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PASTE_YOUR_API_KEY_HERE',
    appId: 'PASTE_YOUR_APP_ID_HERE',
    messagingSenderId: 'PASTE_YOUR_SENDER_ID_HERE',
    projectId: 'survey-app-767fc',
    storageBucket: 'survey-app-767fc.appspot.com',
  );
}
