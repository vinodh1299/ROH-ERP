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

class ApiService {
  // ── Singleton ────────────────────────────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_authToken';
    }
    return h;
  }

  // ── Base URL from .env ──────────────────────────────────────────────────
  String get baseUrl {
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
  Future<dynamic> get(String action, {Map<String, String>? params}) async {
    try {
      final query = {'action': action, ...(params ?? {})};
      final uri = Uri.parse(_apiFile).replace(queryParameters: query);
      debugPrint('ApiService GET → $uri');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      return _decode(response);
    } catch (e) {
      debugPrint('ApiService.get error: $e');
      return {'error': e.toString()};
    }
  }

  // ── POST request  →  api.php?action=xxx  with JSON body ─────────────────
  Future<dynamic> post(String action, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse(_apiFile).replace(queryParameters: {'action': action});
      debugPrint('ApiService POST → $uri');
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _decode(response);
    } catch (e) {
      debugPrint('ApiService.post error: $e');
      return {'error': e.toString()};
    }
  }

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('ApiService decode error: $e — raw body: ${response.body}');
      return {'error': 'Invalid response from server'};
    }
  }
}
