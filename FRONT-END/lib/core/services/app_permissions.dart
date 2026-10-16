// lib/core/services/app_permissions.dart
// One place to check / request the OS permissions ROH ERP asks for on first
// launch: notifications, camera and microphone.
//
//   iOS / Android  → permission_handler
//   macOS          → notifications via flutter_local_notifications, camera/mic
//                    via the native 'roh_erp/permissions' channel (MainFlutterWindow.swift)
//   Windows        → notifications need no runtime prompt; camera/mic are
//                    controlled in Windows Settings > Privacy
//   Web            → not used (the browser asks when a feature needs it)
import 'dart:io' show Process;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'system_notifications.dart';

enum AppPermission { notifications, camera, microphone }

enum AppPermissionState { granted, notDetermined, denied, permanentlyDenied, managedBySystem }

class AppPermissions {
  AppPermissions._();

  static const MethodChannel _macChannel = MethodChannel('roh_erp/permissions');

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);

  static bool get _isMac => defaultTargetPlatform == TargetPlatform.macOS;
  static bool get _isWindows => defaultTargetPlatform == TargetPlatform.windows;

  static ph.Permission _ph(AppPermission p) => switch (p) {
        AppPermission.notifications => ph.Permission.notification,
        AppPermission.camera => ph.Permission.camera,
        AppPermission.microphone => ph.Permission.microphone,
      };

  static String _key(AppPermission p) => p.name;

  static Future<AppPermissionState> status(AppPermission p) async {
    if (!supported) return AppPermissionState.managedBySystem;
    try {
      if (_isWindows) {
        // Toast notifications need no prompt; camera/mic are Windows privacy settings.
        return p == AppPermission.notifications
            ? AppPermissionState.granted
            : AppPermissionState.managedBySystem;
      }
      if (_isMac) {
        if (p == AppPermission.notifications) {
          final enabled = await SystemNotifications.isEnabled();
          if (enabled == true) return AppPermissionState.granted;
          // macOS only shows its prompt once; afterwards it must be changed in Settings.
          return SystemNotifications.wasRequestedBefore
              ? AppPermissionState.permanentlyDenied
              : AppPermissionState.notDetermined;
        }
        final s = await _macChannel.invokeMethod<String>('status', _key(p));
        return switch (s) {
          'granted' => AppPermissionState.granted,
          'notDetermined' => AppPermissionState.notDetermined,
          _ => AppPermissionState.permanentlyDenied, // macOS never re-prompts once denied
        };
      }
      final s = await _ph(p).status;
      if (s.isGranted || s.isLimited || s.isProvisional) return AppPermissionState.granted;
      if (s.isPermanentlyDenied || s.isRestricted) return AppPermissionState.permanentlyDenied;
      if (s.isDenied) return AppPermissionState.notDetermined; // can still be asked
      return AppPermissionState.denied;
    } catch (e) {
      debugPrint('AppPermissions.status($p) failed: $e');
      return AppPermissionState.denied;
    }
  }

  /// Shows the OS prompt (when the OS still allows one) and returns the new state.
  static Future<AppPermissionState> request(AppPermission p) async {
    if (!supported) return AppPermissionState.managedBySystem;
    try {
      if (_isWindows) return status(p);
      if (_isMac) {
        if (p == AppPermission.notifications) {
          await SystemNotifications.requestPermission(force: true);
        } else {
          await _macChannel.invokeMethod<bool>('request', _key(p));
        }
        return status(p);
      }
      if (p == AppPermission.notifications) await SystemNotifications.init();
      await _ph(p).request();
      return status(p);
    } catch (e) {
      debugPrint('AppPermissions.request($p) failed: $e');
      return status(p);
    }
  }

  static Future<void> openSettings(AppPermission p) async {
    try {
      if (_isMac) {
        await _macChannel.invokeMethod('openSettings', _key(p));
      } else if (_isWindows) {
        final uri = switch (p) {
          AppPermission.camera => 'ms-settings:privacy-webcam',
          AppPermission.microphone => 'ms-settings:privacy-microphone',
          AppPermission.notifications => 'ms-settings:notifications',
        };
        await Process.run('cmd', ['/c', 'start', '', uri]);
      } else {
        await ph.openAppSettings();
      }
    } catch (e) {
      debugPrint('AppPermissions.openSettings($p) failed: $e');
    }
  }
}
