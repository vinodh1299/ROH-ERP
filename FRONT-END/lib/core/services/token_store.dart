// lib/core/services/token_store.dart
//
// Where the session JWT lives on this device.
//   • iOS / Android / macOS / Windows / Linux → FlutterSecureStorage
//     (Keychain / Keystore / libsecret / DPAPI).
//   • Web → SharedPreferences + window.localStorage, as before (there is no
//     stronger store in a browser).
// Older builds kept the token in SharedPreferences on every platform; read()
// moves such a token into secure storage the first time it runs.
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_storage/web_storage.dart';

class TokenStore {
  TokenStore._();

  static const _key = 'auth_token';
  static const _legacyKeys = ['jwt_token', 'auth_token'];

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    // The data-protection keychain needs a keychain-access-groups
    // entitlement (and so a signing team); the login keychain does not.
    mOptions: MacOsOptions(useDataProtectionKeyChain: false),
  );

  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      return prefs.getString('jwt_token') ??
          prefs.getString('auth_token') ??
          getWebStorage('jwt_token') ??
          getWebStorage('auth_token');
    }

    String? token;
    try {
      token = await _secure.read(key: _key);
    } catch (e) {
      if (kDebugMode) debugPrint('TokenStore read failed: $e');
    }

    // One-time migration from SharedPreferences.
    final legacy =
        prefs.getString('jwt_token') ?? prefs.getString('auth_token');
    if (legacy != null && legacy.isNotEmpty) {
      if (token == null || token.isEmpty) {
        try {
          await _secure.write(key: _key, value: legacy);
          token = legacy;
        } catch (e) {
          if (kDebugMode) debugPrint('TokenStore migration failed: $e');
          return legacy; // keep working; retry the move next launch
        }
      }
      for (final k in _legacyKeys) {
        await prefs.remove(k);
      }
    }
    return (token == null || token.isEmpty) ? null : token;
  }

  static Future<void> write(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('jwt_token', token);
      saveWebStorage('auth_token', token);
      saveWebStorage('jwt_token', token);
      return;
    }
    await _secure.write(key: _key, value: token);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in _legacyKeys) {
      await prefs.remove(k);
    }
    if (!kIsWeb) {
      try {
        await _secure.delete(key: _key);
      } catch (e) {
        if (kDebugMode) debugPrint('TokenStore delete failed: $e');
      }
    }
  }
}
