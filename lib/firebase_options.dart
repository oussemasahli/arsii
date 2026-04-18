import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Generated Firebase configuration for the arsii project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError('This platform is not supported.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDkEZEPiZSfP4L7jGivp2DkWW4vLCjzMxY',
    appId: '1:248003527245:web:a5886606cb7c859db05204',
    messagingSenderId: '248003527245',
    projectId: 'lock-in-258ad',
    authDomain: 'lock-in-258ad.firebaseapp.com',
    storageBucket: 'lock-in-258ad.firebasestorage.app',
    measurementId: 'G-MBZ0VPX4FH',
  );
}
