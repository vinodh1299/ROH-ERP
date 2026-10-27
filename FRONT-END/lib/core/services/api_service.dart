// ════════════════════════════════════════════════════════════════════════════
// lib/core/services/api_service.dart
//
// CENTRAL HTTP CLIENT — talks to your single api.php file using ?action=...
//
// HOW IT WORKS:
//   Flutter  →  GET/POST  http://yourserver/api.php?action=xxx  →  MySQL
//
// SETUP:
//   1. Open .env and set API_BASE_URL to the FOLDER your api.php lives in,
//      WITHOUT the filename, e.g.:
//         API_BASE_URL=http://localhost/roh_api/
//      (api.php must be directly inside that folder)
//
//   2. Every call below automatically appends "api.php?action=..."
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// A decoded API response together with its HTTP status code
/// (null when the request never reached the server).
class ApiResponse {
  final int? statusCode;
  final dynamic body;
  const ApiResponse(this.statusCode, this.body);
}

class ApiService {
  // ── Singleton ────────────────────────────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Called once when a request that carried the current bearer token is
  /// answered with 401 (expired or revoked session). Registered by
  /// AuthService. Re-armed whenever a new token is set.
  static void Function()? onSessionExpired;

  /// Actions whose 401 means "wrong credentials" / "can't refresh", not
  /// "your session ended mid-use"; the caller handles those itself.
  static const _authActions = {'login', 'refresh_token'};

  String? _authToken;
  bool _expiryReported = false;
  int? _lastStatusCode;

  /// HTTP status of the most recently completed request (null if it failed
  /// before a response arrived).
  int? get lastStatusCode => _lastStatusCode;

  bool get hasAuthToken => _authToken != null && _authToken!.isNotEmpty;

  void setAuthToken(String? token) {
    _authToken = token;
    if (token != null && token.isNotEmpty) _expiryReported = false;
  }

  Map<String, String> _headersFor(String? token) {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ── Base URL from .env ──────────────────────────────────────────────────
  String get baseUrl {
    // Build-time override for deployments: --dart-define=API_BASE_URL=https://...
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) {
      return defined.endsWith('/') ? defined : '$defined/';
    }
    try {
      if (dotenv.isInitialized) {
        final url = dotenv.env['API_BASE_URL'];
        if (url != null && url.trim().isNotEmpty) {
          final trimmed = url.trim();
          return trimmed.endsWith('/') ? trimmed : '$trimmed/';
        }
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000/';
  }

  String get _apiFile => '${baseUrl}api';

  // ── GET request  →  /api?action=xxx&key=value ───────────────────────────
  Future<dynamic> get(String action, {Map<String, String>? params}) async =>
      (await getWithStatus(action, params: params)).body;

  Future<ApiResponse> getWithStatus(String action,
      {Map<String, String>? params}) async {
    final token = _authToken;
    try {
      final query = {'action': action, ...(params ?? {})};
      final uri = Uri.parse(_apiFile).replace(queryParameters: query);
      if (kDebugMode) debugPrint('ApiService GET → $uri');
      final response = await http
          .get(uri, headers: _headersFor(token))
          .timeout(const Duration(seconds: 15));
      return _complete(action, token, response);
    } catch (e) {
      _lastStatusCode = null;
      if (kDebugMode) debugPrint('ApiService.get($action) error: $e');
      return ApiResponse(null, {'error': e.toString()});
    }
  }

  // ── POST request  →  api.php?action=xxx  with JSON body ─────────────────
  Future<dynamic> post(String action, Map<String, dynamic> body) async =>
      (await postWithStatus(action, body)).body;

  Future<ApiResponse> postWithStatus(
      String action, Map<String, dynamic> body) async {
    final token = _authToken;
    try {
      final uri =
          Uri.parse(_apiFile).replace(queryParameters: {'action': action});
      if (kDebugMode) debugPrint('ApiService POST → $uri');
      final response = await http
          .post(uri, headers: _headersFor(token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _complete(action, token, response);
    } catch (e) {
      _lastStatusCode = null;
      if (kDebugMode) debugPrint('ApiService.post($action) error: $e');
      return ApiResponse(null, {'error': e.toString()});
    }
  }

  ApiResponse _complete(String action, String? token, http.Response response) {
    _lastStatusCode = response.statusCode;
    if (response.statusCode == 401 &&
        token != null &&
        token.isNotEmpty &&
        token == _authToken &&
        !_authActions.contains(action) &&
        !_expiryReported) {
      // Only the token still in use counts: a 401 for a token that has since
      // been refreshed or cleared is stale.
      _expiryReported = true;
      onSessionExpired?.call();
    }
    return ApiResponse(response.statusCode, _decode(response));
  }

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService decode error (HTTP ${response.statusCode}): '
            '$e — raw body: ${response.body}');
      }
      return {'error': 'Invalid response from server'};
    }
  }
}
