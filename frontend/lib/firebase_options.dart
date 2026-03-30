import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDokgAFh1y_yo2pQgSbOmUxgaN7M5R1bpo',
    authDomain: 'gen-lang-client-0466665567.firebaseapp.com',
    projectId: 'gen-lang-client-0466665567',
    storageBucket: 'gen-lang-client-0466665567.firebasestorage.app',
    messagingSenderId: '193644652009',
    appId: '1:193644652009:web:aafba7d276d4de869c9778',
    measurementId: 'G-EEH38V59C5',
  );
}
