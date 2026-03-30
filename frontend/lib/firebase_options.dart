import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_API_KEY', fallback: ''),
    authDomain: dotenv.get('FIREBASE_AUTH_DOMAIN', fallback: ''),
    projectId: dotenv.get('FIREBASE_PROJECT_ID', fallback: ''),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET', fallback: ''),
    messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: ''),
    appId: dotenv.get('FIREBASE_APP_ID', fallback: ''),
    measurementId: dotenv.get('FIREBASE_MEASUREMENT_ID', fallback: ''),
  );
}
