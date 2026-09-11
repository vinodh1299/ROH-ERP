// lib/core/widgets/notification_center_drawer.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/notification_service.dart';

class NotificationCenterDrawer extends StatefulWidget {
  const NotificationCenterDrawer({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationCenterDrawer(),
    );
  }

  @override
  State<NotificationCenterDrawer> createState() => _NotificationCenterDrawerState();
}

class _NotificationCenterDrawerState extends State<NotificationCenterDrawer> {
  final NotificationService _service = NotificationService();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _service.fetchNotifications();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'PASSWORD_RESET_REQUESTED':
      case 'PASSWORD_CHANGED':
      case 'ACCOUNT_LOCKED':
        return Icons.security_rounded;
      case 'SESSION_ASSIGNED':
      case 'SESSION_STARTED':
      case 'SESSION_ENDED':
        return Icons.calendar_today_rounded;
      case 'APPOINTMENT_SCHEDULED':
      case 'APPOINTMENT_CONFIRMED':
        return Icons.event_available_rounded;
      case 'REPORT_READY':
        return Icons.assignment_turned_in_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'PASSWORD_RESET_REQUESTED':
        return const Color(0xFFF59E0B);
      case 'ACCOUNT_LOCKED':
        return const Color(0xFFEF4444);
      case 'REPORT_READY':
        return const Color(0xFF10B981);
      case 'SESSION_ASSIGNED':
        return AppColors.primary;
      case 'APPOINTMENT_SCHEDULED':
      case 'APPOINTMENT_CONFIRMED':
        return const Color(0xFF7B2FBE);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final panelWidth = isMobile ? width : 460.0;

    final filteredList = _service.notifications.where((n) {
      if (_selectedFilter == 'Unread') return !n.isRead;
      if (_selectedFilter == 'Security') {
        return n.eventType.contains('PASSWORD') || n.eventType.contains('LOCKED') || n.eventType.contains('AUTH');
      }
      if (_selectedFilter == 'Clinical') {
        return n.eventType.contains('SESSION') || n.eventType.contains('REPORT') || n.eventType.contains('IEP') || n.eventType.contains('APPOINTMENT');
      }
      return true;
    }).toList();

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: panelWidth,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 24,
                offset: Offset(-4, 0),
              )
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 20, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Notification Center',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (_service.unreadCount > 0)
                          TextButton(
                            onPressed: () => _service.markAsRead(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Mark all as read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Unread', badge: _service.unreadCount > 0 ? '${_service.unreadCount}' : null),
                          const SizedBox(width: 8),
                          _buildFilterChip('Clinical'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Security'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Notification List
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.done_all_rounded, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'You are all caught up!',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No ${_selectedFilter == "All" ? "" : _selectedFilter.toLowerCase()} notifications at this time',
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, endIndent: 20, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          final icon = _getEventIcon(item.eventType);
                          final color = _getEventColor(item.eventType);

                          return InkWell(
                            onTap: () {
                              if (!item.isRead) {
                                _service.markAsRead(item.id);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              color: item.isRead ? Colors.transparent : AppColors.primaryLight.withOpacity(0.04),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(icon, color: color, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (!item.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.message,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textSecondary,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.createdAt,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {String? badge}) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.25) : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
