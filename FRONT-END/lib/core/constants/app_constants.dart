// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // ── App Info ──
  static const String appName = 'Ray of Hope ERP';
  static const String appShortName = 'ROH';
  static const String centerName = 'Ray of Hope Center for Autism';



  // ── Network / API ──
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // ── Shared Prefs Keys ──
  static const String prefUserId = 'user_id';
  static const String prefUserEmail = 'user_email';
  static const String prefUserName = 'user_name';
  static const String prefUserRole = 'user_role';
  static const String prefIsLoggedIn = 'is_logged_in';

  // ── Routes ──
  static const String routeLogin = '/';
  static const String routeAdmin = '/admin';
  static const String routeDirector = '/director';
  static const String routeTherapist = '/therapist';
  static const String routeParent = '/parent';
}
