// lib/features/auth/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/user_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // ── Load session from SharedPreferences ──
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;
    if (isLoggedIn) {
      _currentUser = UserModel(
        name: prefs.getString(AppConstants.prefUserName) ?? '',
        email: prefs.getString(AppConstants.prefUserEmail) ?? '',
        role: prefs.getString(AppConstants.prefUserRole) ?? '',
      );
      notifyListeners();
    }
  }

  // ── Dummy login – replace with real API/DB call later ──
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    UserModel? user;

    if (email == AppConstants.directorEmail &&
        password == AppConstants.directorPassword) {
      user = const UserModel(
        name: AppConstants.directorName,
        email: AppConstants.directorEmail,
        role: AppConstants.directorRole,
      );
    } else if (email == AppConstants.therapistEmail &&
        password == AppConstants.therapistPassword) {
      user = const UserModel(
        name: AppConstants.therapistName,
        email: AppConstants.therapistEmail,
        role: AppConstants.therapistRole,
      );
    } else if (email == AppConstants.parentEmail &&
        password == AppConstants.parentPassword) {
      user = const UserModel(
        name: AppConstants.parentName,
        email: AppConstants.parentEmail,
        role: AppConstants.parentRole,
      );
    }

    if (user != null) {
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefIsLoggedIn, true);
      await prefs.setString(AppConstants.prefUserName, user.name);
      await prefs.setString(AppConstants.prefUserEmail, user.email);
      await prefs.setString(AppConstants.prefUserRole, user.role);
      _isLoading = false;
      notifyListeners();
      return user.role; // return role for navigation
    }

    _isLoading = false;
    notifyListeners();
    return null; // invalid credentials
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
