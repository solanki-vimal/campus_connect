import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  AppUser? _appUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUser(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Right after signup, there's a brief race: Firebase Auth fires
      // authStateChanges before the Firestore user document write finishes.
      // Retry a few times with a short delay before treating it as missing.
      AppUser? fetched;
      const maxAttempts = 4;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        fetched = await _userService.fetchUser(uid);
        if (fetched != null) break;
        if (attempt < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }

      _appUser = fetched;
      if (_appUser == null) {
        _errorMessage = 'User profile not found. Please contact administration or try again.';
      }
    } catch (e) {
      _errorMessage = 'Failed to load user profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _appUser = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}