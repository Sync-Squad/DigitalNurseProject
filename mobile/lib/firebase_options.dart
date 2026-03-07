// File used for Firebase config across platforms.
// For web, ensure you have added a Web app in Firebase Console; run
// `dart run flutterfire configure` to regenerate with your web appId if needed.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the current platform.
/// Web requires explicit options; mobile can use native config or these.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAUrxZvhofg0o7OK-pbjwXySW3bA--vPyA',
    appId: '1:175192714305:web:3202687f7c71c91a73eac0',
    messagingSenderId: '175192714305',
    projectId: 'mydigitalnurse-5ffcd',
    authDomain: 'mydigitalnurse-5ffcd.firebaseapp.com',
    storageBucket: 'mydigitalnurse-5ffcd.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUrxZvhofg0o7OK-pbjwXySW3bA--vPyA',
    appId: '1:175192714305:android:3202687f7c71c91a73eac0',
    messagingSenderId: '175192714305',
    projectId: 'mydigitalnurse-5ffcd',
    storageBucket: 'mydigitalnurse-5ffcd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAUrxZvhofg0o7OK-pbjwXySW3bA--vPyA',
    appId: '1:175192714305:ios:REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '175192714305',
    projectId: 'mydigitalnurse-5ffcd',
    storageBucket: 'mydigitalnurse-5ffcd.firebasestorage.app',
    iosBundleId: 'com.example.digitalNurse',
  );
}
