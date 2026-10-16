// lib/core/widgets/first_launch_permissions_gate.dart
// Shown once, on the first launch of the installed app (macOS, Windows, iOS,
// Android): explains and requests notifications, camera and microphone.
// Users can continue without granting — app stores reject apps that block on
// permissions — and can change their choice later from the OS settings.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../constants/app_images.dart';
import '../services/app_permissions.dart';

class FirstLaunchPermissionsGate extends StatefulWidget {
  final Widget child;
  const FirstLaunchPermissionsGate({super.key, required this.child});

  @override
  State<FirstLaunchPermissionsGate> createState() => _FirstLaunchPermissionsGateState();
}

class _FirstLaunchPermissionsGateState extends State<FirstLaunchPermissionsGate> with WidgetsBindingObserver {
  static const String _doneKey = 'first_launch_permissions_done';

  bool? _show; // null while loading
  bool _busy = false;
  final Map<AppPermission, AppPermissionState> _states = {};

  static const _items = [
    (AppPermission.notifications, Icons.notifications_active_outlined, 'Notifications',
        'Alerts when sessions are assigned, IEPs are signed off and appointments change.'),
    (AppPermission.camera, Icons.photo_camera_outlined, 'Camera',
        'Capture student photos and clinical session media.'),
    (AppPermission.microphone, Icons.mic_none_outlined, 'Microphone',
        'Record voice notes and session audio.'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-read statuses when the user comes back from the OS settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _show == true) _refresh();
  }

  Future<void> _load() async {
    if (!AppPermissions.supported) {
      setState(() => _show = false);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_doneKey) ?? false;
    if (done) {
      setState(() => _show = false);
      return;
    }
    await _refresh();
    if (mounted) setState(() => _show = true);
  }

  Future<void> _refresh() async {
    for (final item in _items) {
      _states[item.$1] = await AppPermissions.status(item.$1);
    }
    if (mounted) setState(() {});
  }

  Future<void> _request(AppPermission p) async {
    setState(() => _busy = true);
    _states[p] = await AppPermissions.request(p);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _allowAll() async {
    setState(() => _busy = true);
    for (final item in _items) {
      if (_states[item.$1] == AppPermissionState.notDetermined) {
        _states[item.$1] = await AppPermissions.request(item.$1);
        if (mounted) setState(() {});
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doneKey, true);
    if (mounted) setState(() => _show = false);
  }

  bool get _allGranted => _items.every((i) =>
      _states[i.$1] == AppPermissionState.granted || _states[i.$1] == AppPermissionState.managedBySystem);

  bool get _anyAskable => _items.any((i) => _states[i.$1] == AppPermissionState.notDetermined);

  @override
  Widget build(BuildContext context) {
    if (_show == false) return widget.child;
    if (_show == null) return const ColoredBox(color: AppColors.background);

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft, child: AppImages.rohLogo(height: 40)),
                  const SizedBox(height: 24),
                  const Text('Before you start',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text(
                    'ROH ERP works best with these permissions. You can change them any time in your device settings.',
                    style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  for (final item in _items) ...[
                    _PermissionRow(
                      icon: item.$2,
                      title: item.$3,
                      reason: item.$4,
                      state: _states[item.$1] ?? AppPermissionState.notDetermined,
                      busy: _busy,
                      onAllow: () => _request(item.$1),
                      onOpenSettings: () => AppPermissions.openSettings(item.$1),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  if (_anyAskable)
                    FilledButton(
                      onPressed: _busy ? null : _allowAll,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Allow all'),
                    ),
                  if (_anyAskable) const SizedBox(height: 8),
                  _allGranted
                      ? FilledButton(
                          onPressed: _finish,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Continue'),
                        )
                      : TextButton(
                          onPressed: _busy ? null : _finish,
                          child: const Text('Continue without some permissions'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String reason;
  final AppPermissionState state;
  final bool busy;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;

  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.reason,
    required this.state,
    required this.busy,
    required this.onAllow,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final Widget trailing = switch (state) {
      AppPermissionState.granted => const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 20),
          SizedBox(width: 6),
          Text('Allowed', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
        ]),
      AppPermissionState.notDetermined => OutlinedButton(onPressed: busy ? null : onAllow, child: const Text('Allow')),
      AppPermissionState.managedBySystem =>
        TextButton(onPressed: onOpenSettings, child: const Text('System settings')),
      _ => TextButton(onPressed: onOpenSettings, child: const Text('Open Settings')),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  state == AppPermissionState.permanentlyDenied || state == AppPermissionState.denied
                      ? 'Turned off. Enable it in Settings to use this feature.'
                      : reason,
                  style: const TextStyle(fontSize: 12.5, height: 1.35, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
