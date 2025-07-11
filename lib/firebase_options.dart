// File generated by FlutterFire CLI.
// ignore_for_file: type=lint

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
    apiKey: 'AIzaSyCiaKcTh-5Qq_Kk_TinfW8MiYg3yzOh-9k',
    appId: '1:662778038323:web:b8b4f1d3d01d0d351a3b46',
    messagingSenderId: '662778038323',
    projectId: 'vettakipson',
    authDomain: 'vettakipson.firebaseapp.com',
    storageBucket: 'vettakipson.firebasestorage.app',
    measurementId: 'G-0ZCQ6N8WCG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCeH28H8XhxWr3QpsQ8RFpU4U8IAhRI39M',
    appId: '1:662778038323:android:9b0274daa3883ab91a3b46',
    messagingSenderId: '662778038323',
    projectId: 'vettakipson',
    storageBucket: 'vettakipson.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB80FI0vVMqGOTRwN5POYas84c_UXBUjQo',
    appId: '1:662778038323:ios:a76e5756a70296e21a3b46',
    messagingSenderId: '662778038323',
    projectId: 'vettakipson',
    storageBucket: 'vettakipson.firebasestorage.app',
    iosBundleId: 'com.example.vettakipprojeNew',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB80FI0vVMqGOTRwN5POYas84c_UXBUjQo',
    appId: '1:662778038323:ios:a76e5756a70296e21a3b46',
    messagingSenderId: '662778038323',
    projectId: 'vettakipson',
    storageBucket: 'vettakipson.firebasestorage.app',
    iosBundleId: 'com.example.vettakipprojeNew',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCiaKcTh-5Qq_Kk_TinfW8MiYg3yzOh-9k',
    appId: '1:662778038323:web:1aa0e8642500b69a1a3b46',
    messagingSenderId: '662778038323',
    projectId: 'vettakipson',
    authDomain: 'vettakipson.firebaseapp.com',
    storageBucket: 'vettakipson.firebasestorage.app',
    measurementId: 'G-JJTWZY41MH',
  );

}