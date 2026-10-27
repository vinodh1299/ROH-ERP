import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'poller.dart';
import 'system_notifications.dart';
import 'web_storage/web_storage.dart';

class NotificationItem {
  final int id;
  final String eventType;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;
  final Map<String, dynamic> metadata;

  NotificationItem({
    required this.id,
    required this.eventType,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.metadata = const {},
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedMeta = {};
    if (map['metadata_json'] != null) {
      if (map['metadata_json'] is Map) {
        parsedMeta = Map<String, dynamic>.from(map['metadata_json'] as Map);
      } else if (map['metadata_json'] is String &&
          (map['metadata_json'] as String).isNotEmpty) {
        try {
          final decoded = jsonDecode(map['metadata_json'] as String);
          if (decoded is Map) {
            parsedMeta = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
    } else if (map['metadata'] is Map) {
      parsedMeta = Map<String, dynamic>.from(map['metadata'] as Map);
    }

    return NotificationItem(
      id: int.tryParse('${map['id'] ?? 0}') ?? 0,
      eventType: map['event_type'] ?? 'GENERAL',
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? '',
      isRead: map['is_read'] == 1 ||
          map['is_read'] == true ||
          '${map['is_read']}' == '1',
      createdAt: map['created_at'] ?? '',
      metadata: parsedMeta,
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
  late final Poller _poller = Poller(
      const Duration(seconds: 30), () => fetchNotifications(silent: true));

  final StreamController<NotificationItem> _bannerStreamController =
      StreamController<NotificationItem>.broadcast();
  Stream<NotificationItem> get onNewNotification =>
      _bannerStreamController.stream;

  NotificationItem? activeBannerNotification;
  Set<int> _knownNotificationIds = {};
  bool _isFirstFetch = true;
  int _sessionGeneration =
      0; // bumped by reset() so in-flight polls from a previous session are dropped

  NotificationService._internal();

  /// Begins the 30-second inbox refresh (idempotent). Called by AuthService
  /// once a user is signed in.
  void startPolling() => _poller.start();

  /// Stops refreshing (on sign-out).
  void stopPolling() => _poller.stop();

  /// Pauses polling while the app is in the background; refreshes on return.
  void setForeground(bool foreground) => _poller.setForeground(foreground);

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void showInAppBanner(NotificationItem item) {
    if (kDebugMode) {
      debugPrint(
          '🔔 [NotificationService] showInAppBanner triggered: "${item.title}"');
    }
    activeBannerNotification = item;
    playWebNotificationSound();
    notifyListeners();
  }

  /// Forget the previous user's inbox so their items aren't treated as new
  /// for the next user (call on login and logout).
  void reset() {
    _notifications = [];
    _unreadCount = 0;
    _knownNotificationIds = {};
    _isFirstFetch = true;
    _sessionGeneration++;
    activeBannerNotification = null;
    notifyListeners();
  }

  void dismissBanner() {
    if (activeBannerNotification != null) {
      activeBannerNotification = null;
      notifyListeners();
    }
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    final generation = _sessionGeneration;
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!_api.hasAuthToken) {
        // Not logged in: nothing to poll.
        if (_isLoading) {
          _isLoading = false;
          notifyListeners();
        }
        return;
      }

      // Resolve current user ID and role with immediate webStorage and prefs fallback
      final webUserId = getWebStorage('user_id');
      final webUserRole = getWebStorage('user_role');
      final userId = (webUserId != null && webUserId.isNotEmpty)
          ? webUserId
          : (prefs.getInt(AppConstants.prefUserId)?.toString() ?? '3');
      final role = (webUserRole != null && webUserRole.isNotEmpty)
          ? webUserRole
          : (prefs.getString(AppConstants.prefUserRole) ?? 'therapist');

      final res = await _api.get('get_notifications', params: {
        'user_id': userId,
        'role': role,
      });
      if (generation != _sessionGeneration) {
        _isLoading = false;
        return;
      }
      if (res is Map && res['error'] == null) {
        final resMap = Map<String, dynamic>.from(res);
        _unreadCount = resMap['unread_count'] ?? 0;
        final list = resMap['notifications'] as List? ?? [];
        final items = list
            .map((e) =>
                NotificationItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();

        if (kDebugMode) {
          debugPrint(
              '🔔 [NotificationService] User #$userId ($role) Poll count: ${items.length}, unread: $_unreadCount, isFirst: $_isFirstFetch');
        }

        // Highest notification id already alerted for this user, persisted so that
        // items which arrived while the app was closed still alert on next launch.
        final alertedKey = 'last_alerted_notification_id_$userId';
        final lastAlertedId = prefs.getInt(alertedKey) ?? 0;

        // Check if there are newly arrived unread notifications
        {
          final newItems = items
              .where((item) =>
                  !item.isRead &&
                  (_isFirstFetch
                      ? item.id > lastAlertedId
                      : !_knownNotificationIds.contains(item.id)))
              .toList();
          if (newItems.isNotEmpty) {
            if (kDebugMode) {
              debugPrint(
                  '🎉 [NotificationService] New unread notification detected: #${newItems.first.id} "${newItems.first.title}"');
            }
            showInAppBanner(newItems.first); // Show most recent new banner
            // OS-level banner (Notification Center) for each new item, capped to avoid a flood.
            for (final item in newItems.take(3)) {
              SystemNotifications.show(
                  id: item.id, title: item.title, body: item.message);
            }
          }
        }

        _knownNotificationIds = items.map((e) => e.id).toSet();
        _isFirstFetch = false;
        final maxId =
            items.fold<int>(lastAlertedId, (m, e) => e.id > m ? e.id : m);
        if (maxId > lastAlertedId) await prefs.setInt(alertedKey, maxId);
        _notifications = items;
      }
    } catch (e) {
      debugPrint('NotificationService fetch error: $e');
    }

    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> markAsRead([int? notificationId]) async {
    try {
      final webUserId = getWebStorage('user_id');
      final prefs = await SharedPreferences.getInstance();
      final userId = (webUserId != null && webUserId.isNotEmpty)
          ? webUserId
          : (prefs.getInt(AppConstants.prefUserId)?.toString() ?? '3');

      await _api.post('mark_notification_read', {
        'user_id': userId,
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
          metadata: old.metadata,
        );
      }
    } else {
      _notifications = _notifications
          .map((n) => NotificationItem(
                id: n.id,
                eventType: n.eventType,
                title: n.title,
                message: n.message,
                isRead: true,
                createdAt: n.createdAt,
                metadata: n.metadata,
              ))
          .toList();
    }

    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }
}
