import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAXqO3B3GJHSyuhzMhcwxqUbZmiOEuFP1Y',
    appId: '1:476285489549:web:9f612a7dd1098965d96dc4',
    messagingSenderId: '476285489549',
    projectId: 'acadexa-484807',
    authDomain: 'acadexa-484807.firebaseapp.com',
    storageBucket: 'acadexa-484807.firebasestorage.app',
    measurementId: 'G-00PJLL5EF6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCN85bqYFqpl4flosq1qyK5Ujt6KZ0ialQ',
    appId: '1:476285489549:android:1a5e9ed295ffcfdbd96dc4',
    messagingSenderId: '476285489549',
    projectId: 'acadexa-484807',
    storageBucket: 'acadexa-484807.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDwez9IzWphQNDKNn5521FelsiZHLBpMWQ',
    appId: '1:476285489549:ios:6cb89d190b3681bdd96dc4',
    messagingSenderId: '476285489549',
    projectId: 'acadexa-484807',
    storageBucket: 'acadexa-484807.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDwez9IzWphQNDKNn5521FelsiZHLBpMWQ',
    appId: '1:476285489549:ios:6cb89d190b3681bdd96dc4',
    messagingSenderId: '476285489549',
    projectId: 'acadexa-484807',
    storageBucket: 'acadexa-484807.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAXqO3B3GJHSyuhzMhcwxqUbZmiOEuFP1Y',
    appId: '1:476285489549:web:1da0b524a2a7c6b1d96dc4',
    messagingSenderId: '476285489549',
    projectId: 'acadexa-484807',
    authDomain: 'acadexa-484807.firebaseapp.com',
    storageBucket: 'acadexa-484807.firebasestorage.app',
    measurementId: 'G-K982YGH4XS',
  );

}