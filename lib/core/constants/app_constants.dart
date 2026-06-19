// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // ── App Info ──
  static const String appName = 'Ray of Hope ERP';
  static const String appShortName = 'ROH';
  static const String centerName = 'Ray of Hope Center for Autism';

  // ── Dummy Credentials ──
  // Director
  static const String directorEmail = 'director@roh.com';
  static const String directorPassword = 'director123';
  static const String directorName = 'ROH Admin';
  static const String directorRole = 'director';

  // Therapist
  static const String therapistEmail = 'therapist@roh.com';
  static const String therapistPassword = 'therapist123';
  static const String therapistName = 'Dr. Sarah Lee';
  static const String therapistRole = 'therapist';

  // Parent
  static const String parentEmail = 'parent@roh.com';
  static const String parentPassword = 'parent123';
  static const String parentName = 'Mr. John Wilson';
  static const String parentRole = 'parent';

  // ── Shared Prefs Keys ──
  static const String prefUserEmail = 'user_email';
  static const String prefUserName = 'user_name';
  static const String prefUserRole = 'user_role';
  static const String prefIsLoggedIn = 'is_logged_in';

  // ── Routes ──
  static const String routeLogin = '/';
  static const String routeDirector = '/director';
  static const String routeTherapist = '/therapist';
  static const String routeParent = '/parent';
}
