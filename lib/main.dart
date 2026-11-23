import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'views/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = true;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    firebaseReady = false;
  }

  runApp(TrueFeedApp(firebaseReady: firebaseReady));
}

class TrueFeedApp extends StatelessWidget {
  final bool firebaseReady;

  const TrueFeedApp({super.key, this.firebaseReady = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrueFeed',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E8B57),
        scaffoldBackgroundColor: const Color(0xFFFEFEFE),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F2E9),
          foregroundColor: Color(0xFF1A1A1A),
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF6F2E9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
            ),
          ),

        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE9E3D6)),
            ),
          ),

        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFFEFEFE),
          surfaceTintColor: Colors.transparent,
          indicatorColor: Color(0xFFF6F2E9),
          ),
        ),
      home: AuthGate(firebaseReady: firebaseReady),
    );
    }
}
