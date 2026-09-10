// lib/features/auth/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roh_erp/core/constants/app_constants.dart';
import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  final ApiService _api = ApiService();

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // ── Load session from SharedPreferences on boot up ──
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;
    if (isLoggedIn) {
      _currentUser = UserModel(
        id: prefs.getInt(AppConstants.prefUserId) ?? 0,
        name: prefs.getString(AppConstants.prefUserName) ?? '',
        email: prefs.getString(AppConstants.prefUserEmail) ?? '',
        role: prefs.getString(AppConstants.prefUserRole) ?? '',
      );
      notifyListeners();
    }
  }

  // ── Authentication Login with Mock Fallback for Testing ──
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // 1. Check built-in test/dummy credentials first for testing
    final trimmedEmail = email.toLowerCase().trim();
    UserModel? mockUser;

    if (trimmedEmail == AppConstants.adminEmail && password == AppConstants.adminPassword) {
      mockUser = const UserModel(id: 0, name: AppConstants.adminName, email: AppConstants.adminEmail, role: AppConstants.adminRole);
    } else if (trimmedEmail == AppConstants.directorEmail && password == AppConstants.directorPassword) {
      mockUser = const UserModel(id: 1, name: AppConstants.directorName, email: AppConstants.directorEmail, role: AppConstants.directorRole);
    } else if (trimmedEmail == AppConstants.therapistEmail && password == AppConstants.therapistPassword) {
      mockUser = const UserModel(id: 2, name: AppConstants.therapistName, email: AppConstants.therapistEmail, role: AppConstants.therapistRole);
    } else if (trimmedEmail == AppConstants.parentEmail && password == AppConstants.parentPassword) {
      mockUser = const UserModel(id: 3, name: AppConstants.parentName, email: AppConstants.parentEmail, role: AppConstants.parentRole);
    } else if (trimmedEmail.contains('admin')) {
      mockUser = UserModel(id: 0, name: 'System Admin (Test)', email: email, role: 'admin');
    } else if (trimmedEmail.contains('director')) {
      mockUser = UserModel(id: 1, name: 'Director (Test User)', email: email, role: 'director');
    } else if (trimmedEmail.contains('therapist') || trimmedEmail.contains('doctor')) {
      mockUser = UserModel(id: 2, name: 'Dr. Sarah Lee (Test)', email: email, role: 'therapist');
    } else if (trimmedEmail.contains('parent')) {
      mockUser = UserModel(id: 3, name: 'Mr. John Wilson (Test)', email: email, role: 'parent');
    }

    if (mockUser != null) {
      await _setSession(mockUser);
      _isLoading = false;
      notifyListeners();
      return mockUser.role;
    }

    // 2. Fallback to API endpoint if connected to backend server
    try {
      final result = await _api.post('login', {
        'email': email,
        'password': password,
      });

      if (result is Map<String, dynamic> && result['error'] == null) {
        final user = UserModel.fromMap(result);
        await _setSession(user);
        _isLoading = false;
        notifyListeners();
        return user.role;
      }
    } catch (e) {
      debugPrint('Login request failed: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null; // invalid credentials or connection failure
  }

  Future<void> _setSession(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsLoggedIn, true);
    await prefs.setInt(AppConstants.prefUserId, user.id);
    await prefs.setString(AppConstants.prefUserName, user.name);
    await prefs.setString(AppConstants.prefUserEmail, user.email);
    await prefs.setString(AppConstants.prefUserRole, user.role);
  }

  // ── Clear local session on logout ──
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
