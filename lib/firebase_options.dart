import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;


class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCo3mhBr8NLdvoA2SjgeVC08Km1aYeng_A',
    appId: '1:852122286546:web:8c056341a963163edf700b',
    messagingSenderId: '852122286546',
    projectId: 'truefeedauth',
    authDomain: 'truefeedauth.firebaseapp.com',
    storageBucket: 'truefeedauth.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDxh2LAddUp6SjHgy7amLxxkXKADAC0pyE',
    appId: '1:852122286546:android:aa7a05687e74f74adf700b',
    messagingSenderId: '852122286546',
    projectId: 'truefeedauth',
    storageBucket: 'truefeedauth.firebasestorage.app',
  );
}
