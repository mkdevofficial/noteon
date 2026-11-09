import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Run `flutterfire configure` to generate project-specific options,
/// or replace placeholder values with your Firebase project credentials.
class DefaultFirebaseOptions {
  static const bool isConfigured = true;
  static const String projectId = 'note-on-mkdevofficial';

  static FirebaseOptions? get currentPlatform {
    if (!isConfigured) return null;
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return null;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAaPQhUKt9lz0gj8WWIzS9hvPqg3FLO534',
    appId: '1:554489529266:web:c2b2468b12f713f45b1aab',
    messagingSenderId: '554489529266',
    projectId: 'note-on-mkdevofficial',
    authDomain: 'note-on-mkdevofficial.firebaseapp.com',
    storageBucket: 'note-on-mkdevofficial.firebasestorage.app',
    measurementId: 'G-NKNY282HXJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAzWDWeOPJNkxBBCVuzX0OCFg6FbleAmgw',
    appId: '1:554489529266:android:db88a8e2b29bbd2d5b1aab',
    messagingSenderId: '554489529266',
    projectId: 'note-on-mkdevofficial',
    storageBucket: 'note-on-mkdevofficial.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy-DemoApiKeyNoteOnIos000000000000',
    appId: '1:100000000000:ios:abcdef1234567890',
    messagingSenderId: '100000000000',
    projectId: 'note-on-mkdevofficial',
    iosBundleId: 'com.example.noteon',
  );
}
