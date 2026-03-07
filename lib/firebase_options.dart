import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'This build currently supports Android Firebase options only.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDihhus-K33IJlAG1SEPQCH7MJM9SaT5Ok',
    appId: '1:1070769209468:android:7d7d4239ff0296c39cc9f9',
    messagingSenderId: '1070769209468',
    projectId: 'foodtracking-2f928',
    databaseURL: 'https://foodtracking-2f928-default-rtdb.firebaseio.com',
    storageBucket: 'foodtracking-2f928.firebasestorage.app',
  );
}
