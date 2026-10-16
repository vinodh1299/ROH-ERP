// lib/features/auth/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roh_erp/core/constants/app_constants.dart';
import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/web_storage/web_storage.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  final ApiService _api = ApiService();

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // ── Load session from SharedPreferences & Web LocalStorage on boot up ──
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;
    int userId = prefs.getInt(AppConstants.prefUserId) ?? 0;
    String userName = prefs.getString(AppConstants.prefUserName) ?? '';
    String userEmail = prefs.getString(AppConstants.prefUserEmail) ?? '';
    String userRole = prefs.getString(AppConstants.prefUserRole) ?? '';
    String? token = prefs.getString('jwt_token') ?? prefs.getString('auth_token');

    // Fallback/sync directly from browser window.localStorage on Web
    if (!isLoggedIn) {
      final webLoggedIn = getWebStorage('is_logged_in');
      if (webLoggedIn == 'true') {
        isLoggedIn = true;
        userId = int.tryParse(getWebStorage('user_id') ?? '0') ?? 0;
        userName = getWebStorage('user_name') ?? '';
        userEmail = getWebStorage('user_email') ?? '';
        userRole = getWebStorage('user_role') ?? '';
        token = getWebStorage('jwt_token') ?? getWebStorage('auth_token');
      }
    }

    if (isLoggedIn && userRole.isNotEmpty) {
      _currentUser = UserModel(
        id: userId,
        name: userName,
        email: userEmail,
        role: userRole,
      );
      if (token != null && token.isNotEmpty) {
        ApiService().setAuthToken(token);
        // Ensure web storage is kept in sync
        saveWebStorage('jwt_token', token);
        saveWebStorage('auth_token', token);
        saveWebStorage('user_role', userRole);
        saveWebStorage('user_email', userEmail);
        saveWebStorage('user_name', userName);
        saveWebStorage('user_id', userId.toString());
        saveWebStorage('is_logged_in', 'true');
      }
      notifyListeners();
    }
  }

  // ── Authentication Login via Node.js API Gateway (MySQL) ──
  // ── Authentication Login via Node.js API Gateway (MySQL) ──
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    try {
      final result = await _api.post('login', {
        'email': cleanEmail,
        'password': cleanPass,
      });

      if (result is Map<String, dynamic> && result['error'] == null) {
        final user = UserModel.fromMap(result);
        final token = result['token'] as String?;
        await _setSession(user, token);
        _isLoading = false;
        notifyListeners();
        return user.role;
      } else if (result is Map<String, dynamic> && result['error'] != null) {
        debugPrint('Login rejected by backend: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Login connection failed: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null; // invalid credentials or connection failure
  }

  Future<void> _setSession(UserModel user, [String? token]) async {
    _currentUser = user;
    NotificationService().reset();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsLoggedIn, true);
    await prefs.setInt(AppConstants.prefUserId, user.id);
    await prefs.setString(AppConstants.prefUserName, user.name);
    await prefs.setString(AppConstants.prefUserEmail, user.email);
    await prefs.setString(AppConstants.prefUserRole, user.role);

    // Save directly to browser window.localStorage so DevTools shows the JWT token clearly
    saveWebStorage('is_logged_in', 'true');
    saveWebStorage('user_id', user.id.toString());
    saveWebStorage('user_name', user.name);
    saveWebStorage('user_email', user.email);
    saveWebStorage('user_role', user.role);

    if (token != null && token.isNotEmpty) {
      await prefs.setString('auth_token', token);
      await prefs.setString('jwt_token', token);
      saveWebStorage('auth_token', token);
      saveWebStorage('jwt_token', token);
      ApiService().setAuthToken(token);
    }
  }

  bool get mustChangePassword => _currentUser?.mustChangePassword ?? false;

  // ── Change Password (Self-service or First-login) ──
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final res = await _api.post('change_password', {
        'current_password': currentPassword,
        'new_password': newPassword,
      });

      if (res is Map<String, dynamic>) {
        if (res['success'] == true) {
          if (_currentUser != null) {
            _currentUser = UserModel(
              id: _currentUser!.id,
              name: _currentUser!.name,
              email: _currentUser!.email,
              role: _currentUser!.role,
              mustChangePassword: false,
            );
            notifyListeners();
          }
          return {'success': true, 'message': res['message'] ?? 'Password changed successfully'};
        } else if (res['error'] != null) {
          return {'success': false, 'error': res['error']};
        }
      }
      return {'success': true, 'message': 'Password changed successfully'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Clear local session on logout ──
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefIsLoggedIn);
    await prefs.remove(AppConstants.prefUserId);
    await prefs.remove(AppConstants.prefUserName);
    await prefs.remove(AppConstants.prefUserEmail);
    await prefs.remove(AppConstants.prefUserRole);
    await prefs.remove('auth_token');
    await prefs.remove('jwt_token');
    clearAllWebStorage();
    ApiService().setAuthToken(null);
    NotificationService().reset();
    notifyListeners();
  }
}
