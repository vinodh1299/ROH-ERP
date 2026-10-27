// lib/features/auth/auth_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roh_erp/core/constants/app_constants.dart';
import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/schedule_service.dart';
import '../../core/services/session_reminders.dart';
import '../../core/services/token_store.dart';
import '../../core/services/web_storage/web_storage.dart';

class AuthService extends ChangeNotifier {
  AuthService() {
    ApiService.onSessionExpired = _handleSessionExpired;
  }

  UserModel? _currentUser;
  bool _isLoading = false;

  final ApiService _api = ApiService();

  /// Set by main.dart: takes the user to the login screen and tells them
  /// their session ended. Called after the local sign-out has happened.
  VoidCallback? onSessionExpired;

  /// True when the stored session was already expired at start-up, so the
  /// app opened on the login screen instead of the portal.
  bool expiredAtStartup = false;

  String? _token;
  Timer? _refreshTimer;
  AppLifecycleListener? _lifecycle;
  bool _inForeground = true;
  bool _refreshing = false;

  static const _refreshCheckInterval = Duration(minutes: 30);

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
    String? token = await TokenStore.read();

    // Fallback/sync directly from browser window.localStorage on Web
    if (!isLoggedIn) {
      final webLoggedIn = getWebStorage('is_logged_in');
      if (webLoggedIn == 'true') {
        isLoggedIn = true;
        userId = int.tryParse(getWebStorage('user_id') ?? '0') ?? 0;
        userName = getWebStorage('user_name') ?? '';
        userEmail = getWebStorage('user_email') ?? '';
        userRole = getWebStorage('user_role') ?? '';
        token ??= getWebStorage('jwt_token') ?? getWebStorage('auth_token');
      }
    }

    if (isLoggedIn && userRole.isNotEmpty) {
      // A session without a usable token can't call the API: start signed out.
      final exp = token == null ? null : _expiryOf(token);
      if (token == null ||
          token.isEmpty ||
          (exp != null && !exp.isAfter(DateTime.now()))) {
        expiredAtStartup = token != null && token.isNotEmpty;
        await logout();
        return;
      }
      _currentUser = UserModel(
        id: userId,
        name: userName,
        email: userEmail,
        role: userRole,
      );
      _token = token;
      ApiService().setAuthToken(token);
      // Ensure web storage is kept in sync
      if (kIsWeb) {
        saveWebStorage('jwt_token', token);
        saveWebStorage('auth_token', token);
      }
      saveWebStorage('user_role', userRole);
      saveWebStorage('user_email', userEmail);
      saveWebStorage('user_name', userName);
      saveWebStorage('user_id', userId.toString());
      saveWebStorage('is_logged_in', 'true');
      _onSignedIn();
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
        if (kDebugMode) {
          debugPrint('Login rejected by backend: ${result['error']}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Login connection failed: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null; // invalid credentials or connection failure
  }

  Future<void> _setSession(UserModel user, [String? token]) async {
    _currentUser = user;
    NotificationService().reset();
    SessionReminders.clear();
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

    await _storeToken(token);
    _onSignedIn();
  }

  Future<void> _storeToken(String? token) async {
    if (token == null || token.isEmpty) return;
    _token = token;
    ApiService().setAuthToken(token);
    await TokenStore.write(token);
  }

  // ── Session upkeep: polling, token refresh, app lifecycle ──

  /// Starts everything that runs while a user is signed in. Idempotent.
  void _onSignedIn() {
    _inForeground = _isForeground(WidgetsBinding.instance.lifecycleState);
    _lifecycle ??= AppLifecycleListener(onStateChange: _onLifecycleChange);
    ScheduleService().setForeground(_inForeground);
    NotificationService().setForeground(_inForeground);
    ScheduleService().startPolling();
    NotificationService().startPolling();
    _refreshTimer ??= Timer.periodic(_refreshCheckInterval, (_) {
      if (_inForeground) _refreshIfNeeded();
    });
    _refreshIfNeeded();
  }

  void _onSignedOut() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    ScheduleService().stopPolling();
    NotificationService().stopPolling();
  }

  /// Only a hidden/paused app counts as background. "inactive" also fires on
  /// desktop and web whenever the window merely loses focus, and on mobile
  /// it is always followed by hidden/paused when the app really leaves.
  static bool _isForeground(AppLifecycleState? state) =>
      state != AppLifecycleState.hidden && state != AppLifecycleState.paused;

  void _onLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) return;
    final foreground = _isForeground(state);
    if (foreground == _inForeground) return;
    _inForeground = foreground;
    if (!isLoggedIn) return;
    if (foreground) {
      final exp = _token == null ? null : _expiryOf(_token!);
      if (exp != null && !exp.isAfter(DateTime.now())) {
        _handleSessionExpired();
        return;
      }
      _refreshIfNeeded();
    }
    ScheduleService().setForeground(foreground);
    NotificationService().setForeground(foreground);
  }

  /// Swaps the token for a fresh one once less than half its lifetime is
  /// left, so an active user is never signed out mid-use.
  Future<void> _refreshIfNeeded() async {
    final token = _token;
    if (token == null || _refreshing || !isLoggedIn) return;
    final payload = _jwtPayload(token);
    final exp = _epoch(payload?['exp']);
    if (exp == null) return;
    final iat = _epoch(payload?['iat']) ??
        exp.subtract(const Duration(hours: 12)); // staff default lifetime
    final halfLife = exp.difference(iat) ~/ 2;
    if (exp.difference(DateTime.now()) > halfLife) return;

    _refreshing = true;
    try {
      final res = await _api.postWithStatus('refresh_token', {});
      if (_token != token) return; // signed out or replaced meanwhile
      final body = res.body;
      if (res.statusCode == 200 &&
          body is Map &&
          body['token'] is String &&
          (body['token'] as String).isNotEmpty) {
        await _storeToken(body['token'] as String);
      } else if (res.statusCode == 401) {
        _handleSessionExpired();
      }
      // Anything else (offline, 429, 5xx): keep the current token and retry
      // on the next check.
    } finally {
      _refreshing = false;
    }
  }

  /// The server refused our token (expired or revoked): sign out locally and
  /// let the UI send the user to the login screen.
  Future<void> _handleSessionExpired() async {
    if (!isLoggedIn) return;
    await logout();
    onSessionExpired?.call();
  }

  static Map<String, dynamic>? _jwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final json = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payload = jsonDecode(json);
      return payload is Map<String, dynamic> ? payload : null;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _epoch(dynamic seconds) => seconds is num
      ? DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round())
      : null;

  static DateTime? _expiryOf(String token) =>
      _epoch(_jwtPayload(token)?['exp']);

  /// Updates the signed-in user's display name after a profile edit.
  Future<void> updateDisplayName(String name) async {
    final user = _currentUser;
    if (user == null || name.isEmpty || name == user.name) return;
    _currentUser = UserModel(
      id: user.id,
      name: name,
      email: user.email,
      role: user.role,
      mustChangePassword: user.mustChangePassword,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserName, name);
    saveWebStorage('user_name', name);
    notifyListeners();
  }

  bool get mustChangePassword => _currentUser?.mustChangePassword ?? false;

  // ── Change Password (Self-service or First-login) ──
  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
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
            // The server revokes the old token on a password change and
            // returns a new one for this device.
            await _storeToken(res['token'] as String?);
            notifyListeners();
          }
          return {
            'success': true,
            'message': res['message'] ?? 'Password changed successfully'
          };
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
    _token = null;
    ApiService().setAuthToken(null);
    _onSignedOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefIsLoggedIn);
    await prefs.remove(AppConstants.prefUserId);
    await prefs.remove(AppConstants.prefUserName);
    await prefs.remove(AppConstants.prefUserEmail);
    await prefs.remove(AppConstants.prefUserRole);
    await TokenStore.clear();
    clearAllWebStorage();
    NotificationService().reset();
    SessionReminders.clear();
    notifyListeners();
  }
}
