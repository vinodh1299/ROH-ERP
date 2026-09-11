// lib/core/services/offline_sync_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class OfflineSyncService extends ChangeNotifier {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  static const String _queueKey = 'roh_offline_trial_queue';
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _queue = [];
  bool _isSyncing = false;

  List<Map<String, dynamic>> get queue => _queue;
  int get pendingCount => _queue.length;
  bool get isSyncing => _isSyncing;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _queue = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> queueTrialData(Map<String, dynamic> data) async {
    data['queued_at'] = DateTime.now().toIso8601String();
    _queue.add(data);
    await _persist();
    notifyListeners();

    // Attempt sync immediately in background
    syncPendingData();
  }

  Future<void> syncPendingData() async {
    if (_isSyncing || _queue.isEmpty) return;
    _isSyncing = true;
    notifyListeners();

    final List<Map<String, dynamic>> remaining = [];

    for (final item in _queue) {
      try {
        final res = await _api.post('save_daily_data_sheet', item);
        if (res is Map<String, dynamic> && res['error'] != null) {
          remaining.add(item);
        }
      } catch (e) {
        remaining.add(item); // Keep in queue for next connectivity window
      }
    }

    _queue = remaining;
    await _persist();
    _isSyncing = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queueKey, jsonEncode(_queue));
  }
}
