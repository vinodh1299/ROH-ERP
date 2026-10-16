// lib/core/widgets/in_app_notification_banner.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../services/notification_service.dart';
import 'notification_detail_dialog.dart';

class InAppNotificationOverlay extends StatelessWidget {
  final Widget child;

  const InAppNotificationOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          const _InAppBannerHost(),
        ],
      ),
    );
  }
}

class _InAppBannerHost extends StatelessWidget {
  const _InAppBannerHost();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationService(),
      builder: (context, _) {
        final item = NotificationService().activeBannerNotification;

        return IgnorePointer(
          ignoring: item == null,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 18, right: 22),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                reverseDuration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, -0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: item != null
                    ? _BannerCard(key: ValueKey(item.id), item: item)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BannerCard extends StatefulWidget {
  final NotificationItem item;

  const _BannerCard({super.key, required this.item});

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  bool _isHovered = false;

  IconData _getIconForType(String type) {
    if (type.contains('APPOINTMENT')) return Icons.calendar_month_rounded;
    if (type.contains('SESSION')) return Icons.groups_rounded;
    if (type.contains('SECURITY') || type.contains('PASSWORD') || type.contains('LOCKED')) {
      return Icons.shield_rounded;
    }
    if (type.contains('REPORT') || type.contains('IEP')) return Icons.assessment_rounded;
    return Icons.notifications_active_rounded;
  }

  void _handleTap() {
    final item = widget.item;
    NotificationService().dismissBanner();
    final navContext = RohApp.navigatorKey.currentContext ?? context;
    NotificationDetailDialog.show(navContext, item);
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForType(widget.item.eventType);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        elevation: _isHovered ? 12 : 8,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 390,
          decoration: BoxDecoration(
            color: const Color(0xF71E1F24), // Dark macOS-style charcoal
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered ? Colors.white.withOpacity(0.24) : Colors.white.withOpacity(0.14),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(18),
              splashColor: Colors.white.withOpacity(0.08),
              highlightColor: Colors.white.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App / Event Icon Badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B2FBE), Color(0xFF9333EA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B2FBE).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),

                    // Title & Subtitle Message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Just now',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.item.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFCBD5E1),
                              height: 1.35,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Prominent Dismiss 'X' Button
                    Material(
                      color: Colors.white.withOpacity(0.12),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => NotificationService().dismissBanner(),
                        customBorder: const CircleBorder(),
                        hoverColor: const Color(0xFFEF4444).withOpacity(0.4),
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
