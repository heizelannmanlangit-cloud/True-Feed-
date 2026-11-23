import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/roles.dart';
import '../viewmodels/auth_view_model.dart';
import 'login_screen.dart';
import 'main_navigation.dart';


class AuthGate extends StatefulWidget {
  final bool firebaseReady;

  const AuthGate({super.key, required this.firebaseReady});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthViewModel authViewModel = AuthViewModel();

  @override
  void dispose() {
    authViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseReady) {
      return const _SetupNeededScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginScreen(viewModel: authViewModel);
        }

        final name = (user.displayName != null && user.displayName!.isNotEmpty)
            ? user.displayName!
            : (user.email ?? 'User');

        return MainNavigation(
          key: ValueKey(user.uid),
          userId: user.uid,
          userEmail: user.email ?? '',
          userName: name,
          isReviewer: isReviewerEmail(user.email),
          onLogout: authViewModel.logout,
         );
        },
     );
    }
}

class _SetupNeededScreen extends StatelessWidget {
  const _SetupNeededScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Firebase is not set up yet.\n\n'
              'Run "flutterfire configure" in the project folder, '
              'then run the app again.',
              textAlign: TextAlign.center,
            ),
            ),
       ),
      );
   }
}
