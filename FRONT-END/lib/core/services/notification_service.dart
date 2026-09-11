import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class NotificationItem {
  final int id;
  final String eventType;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  NotificationItem({
    required this.id,
    required this.eventType,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: int.tryParse('${map['id'] ?? 0}') ?? 0,
      eventType: map['event_type'] ?? 'GENERAL',
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? '',
      isRead: map['is_read'] == 1 || map['is_read'] == true || '${map['is_read']}' == '1',
      createdAt: map['created_at'] ?? '',
    );
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  final ApiService _api = ApiService();
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  Timer? _pollingTimer;

  NotificationService._internal() {
    // Start real-time background notification polling every 4 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      fetchNotifications(silent: true);
    });
  }

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(AppConstants.prefUserRole) ?? 'director';
      final res = await _api.get('get_notifications', params: {'role': role});

      if (res is Map<String, dynamic> && res['error'] == null) {
        _unreadCount = res['unread_count'] ?? 0;
        final list = res['notifications'] as List? ?? [];
        _notifications = list.map((e) => NotificationItem.fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('NotificationService fetch error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead([int? notificationId]) async {
    try {
      await _api.post('mark_notification_read', {
        if (notificationId != null) 'notification_id': notificationId,
      });
    } catch (_) {}

    if (notificationId != null) {
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        final old = _notifications[idx];
        _notifications[idx] = NotificationItem(
          id: old.id,
          eventType: old.eventType,
          title: old.title,
          message: old.message,
          isRead: true,
          createdAt: old.createdAt,
        );
      }
    } else {
      _notifications = _notifications.map((n) => NotificationItem(
        id: n.id,
        eventType: n.eventType,
        title: n.title,
        message: n.message,
        isRead: true,
        createdAt: n.createdAt,
      )).toList();
    }

    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }
}
