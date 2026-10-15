// lib/core/services/system_notifications.dart
// OS-level notifications (macOS Notification Center, iOS, Android) via
// flutter_local_notifications. On web the browser Notification API is used
// directly (only when the user has granted permission), so the plugin's own
// service worker never replaces Flutter's.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_storage/web_storage.dart';

class SystemNotifications {
  SystemNotifications._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const MethodChannel _windowChannel = MethodChannel('roh_erp/window');
  static const String _androidChannelId = 'roh_erp_alerts';

  static bool _initialized = false;
  static bool _permissionRequested = false;
  static const String _requestedKey = 'system_notifications_permission_requested';

  /// True once the OS permission prompt has been requested on this install (macOS shows it only once).
  static bool wasRequestedBefore = false;

  /// Called when the user clicks a system notification.
  static VoidCallback? onTap;

  static bool get _nativeSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.windows);

  /// Registers the plugin without prompting for permission.
  static Future<void> init() async {
    if (_initialized || !_nativeSupported) return;
    _initialized = true;
    try {
      wasRequestedBefore = (await SharedPreferences.getInstance()).getBool(_requestedKey) ?? false;
    } catch (_) {}
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: darwin,
          macOS: darwin,
          windows: WindowsInitializationSettings(
            appName: 'ROH ERP',
            appUserModelId: 'org.rohautism.erp',
            guid: '6f1c3c62-5d0b-4f3e-9a51-2b7d8e4c9a10',
          ),
        ),
        onDidReceiveNotificationResponse: (_) => _handleTap(),
      );
      // App was launched by clicking a notification left in Notification Center.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) _handleTap();
    } catch (e) {
      debugPrint('SystemNotifications init failed: $e');
    }
  }

  /// Whether the OS currently allows this app to post notifications (null if unknown).
  static Future<bool?> isEnabled() async {
    if (!_nativeSupported) return null;
    await init();
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
          return (await _plugin
                  .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
                  ?.checkPermissions())
              ?.isEnabled;
        case TargetPlatform.iOS:
          return (await _plugin
                  .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
                  ?.checkPermissions())
              ?.isEnabled;
        case TargetPlatform.android:
          return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled();
        default:
          return true;
      }
    } catch (e) {
      debugPrint('SystemNotifications isEnabled failed: $e');
      return null;
    }
  }

  /// Asks the OS for permission once per app run (or again with [force], e.g. from
  /// the first-launch permissions screen).
  static Future<void> requestPermission({bool force = false}) async {
    if (_permissionRequested && !force) return;
    _permissionRequested = true;
    if (kIsWeb) {
      requestWebNotificationPermission();
      return;
    }
    if (!_nativeSupported) return;
    await init();
    try {
      wasRequestedBefore = true;
      (await SharedPreferences.getInstance()).setBool(_requestedKey, true);
    } catch (_) {}
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
          final granted = await _plugin
              .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true);
          debugPrint('🔔 [SystemNotifications] macOS permission granted: $granted');
        case TargetPlatform.iOS:
          await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true);
        case TargetPlatform.android:
          await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission();
        default:
          break;
      }
    } catch (e) {
      debugPrint('SystemNotifications permission request failed: $e');
    }
  }

  static Future<void> show({required int id, required String title, required String body}) async {
    if (kIsWeb) {
      showWebSystemNotification(title, body, () => _handleTap());
      return;
    }
    if (!_nativeSupported) return;
    await init();
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    );
    debugPrint('🔔 [SystemNotifications] posting OS notification #$id: $title');
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            'ROH ERP alerts',
            channelDescription: 'Sessions, appointments and other ROH ERP updates',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: darwin,
          macOS: darwin,
          windows: WindowsNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('SystemNotifications show failed: $e');
    }
  }

  static void _handleTap() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      _windowChannel.invokeMethod('bringToFront').catchError((_) => null);
    }
    onTap?.call();
  }
}
