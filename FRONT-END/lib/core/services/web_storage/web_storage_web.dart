// lib/core/services/web_storage/web_storage_web.dart
// Web platform implementation utilizing window.localStorage directly
import 'dart:html' as html;

void saveWebStorage(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

String? getWebStorage(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void removeWebStorage(String key) {
  try {
    html.window.localStorage.remove(key);
  } catch (_) {}
}

void clearAllWebStorage() {
  try {
    html.window.localStorage.remove('jwt_token');
    html.window.localStorage.remove('auth_token');
    html.window.localStorage.remove('user_role');
    html.window.localStorage.remove('user_email');
    html.window.localStorage.remove('user_name');
    html.window.localStorage.remove('user_id');
    html.window.localStorage.remove('is_logged_in');
  } catch (_) {}
}
