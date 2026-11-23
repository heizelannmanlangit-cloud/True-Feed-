import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

// ViewModel for the Login / Register screen
class AuthViewModel extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _errorMessage = 'Enter your email and password.';
      notifyListeners();
      return;
    }
    await _run(() => _service.login(email, password));
  }

  Future<void> register(String name, String email, String password) async {
    if (name.trim().isEmpty) {
      _errorMessage = 'Enter your name.';
      notifyListeners();
      return;
    }
    if (!email.contains('@')) {
      _errorMessage = 'Enter a valid email.';
      notifyListeners();
      return;
    }
    if (password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return;
    }
    await _run(() => _service.register(name, email, password));
  }

  Future<void> logout() async {
    await _service.logout();
  }

  // Runs a login/register action and handles loading and errors
  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on FirebaseAuthException catch (e) {
      _errorMessage = friendlyAuthError(e);
    } catch (e) {
      _errorMessage = 'Something went wrong. Try again.';
    }

    _isLoading = false;
    notifyListeners();
  }
}
