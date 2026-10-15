import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/notification_service.dart';
import '../services/web_storage/web_storage.dart';
import 'notification_detail_dialog.dart';

class NotificationCenterDrawer extends StatefulWidget {
  const NotificationCenterDrawer({super.key});

  static void show(BuildContext context) {
    // Browsers only show the permission prompt from a user gesture like this tap.
    if (kIsWeb) requestWebNotificationPermission();
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
  NotificationItem? _selectedNotification;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.fetchNotifications();
    });
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

  String _formatCategoryLabel(String type) {
    if (type.contains('APPOINTMENT')) return 'CLINICAL APPOINTMENT';
    if (type.contains('SESSION')) return 'THERAPY SESSION';
    if (type.contains('REPORT')) return 'IEP REPORT';
    if (type.contains('PASSWORD') || type.contains('LOCKED')) return 'SECURITY ALERT';
    return 'SYSTEM NOTIFICATION';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final panelWidth = isMobile ? width : 480.0;

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
          child: _selectedNotification != null
              ? _buildDetailView(_selectedNotification!)
              : _buildListView(),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Notification List View
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildListView() {
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

    return Column(
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
                        setState(() {
                          _selectedNotification = item;
                        });
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.createdAt.isNotEmpty ? item.createdAt : 'Just now',
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
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // In-Drawer Notification Detail View
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDetailView(NotificationItem item) {
    final catColor = _getEventColor(item.eventType);
    final catIcon = _getEventIcon(item.eventType);
    final catLabel = _formatCategoryLabel(item.eventType);
    final meta = item.metadata;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Navigation Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => _selectedNotification = null),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF334155)),
                      SizedBox(width: 4),
                      Text('Back', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Notification Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Detail Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Pill + Marked Read status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: catColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(catIcon, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            catLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text('Read', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Timestamp
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      item.createdAt.isNotEmpty ? item.createdAt : 'Just now',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Full Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.message,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF1E293B),
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Structured metadata
                if (meta.isNotEmpty) ...[
                  const Text(
                    'Event Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        if (meta.containsKey('attendee_name'))
                          _buildMetaRow(icon: Icons.person_rounded, label: 'Attendee', value: '${meta['attendee_name']}'),
                        if (meta.containsKey('date'))
                          _buildMetaRow(icon: Icons.calendar_today_rounded, label: 'Date', value: '${meta['date']}'),
                        if (meta.containsKey('start_time'))
                          _buildMetaRow(icon: Icons.schedule_rounded, label: 'Scheduled Time', value: '${meta['start_time']}'),
                        if (meta.containsKey('title'))
                          _buildMetaRow(icon: Icons.bookmark_border_rounded, label: 'Topic', value: '${meta['title']}'),
                        if (meta.containsKey('appointment_id'))
                          _buildMetaRow(icon: Icons.confirmation_number_outlined, label: 'Reference ID', value: '#APPT-${meta['appointment_id']}', isLast: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),

        // Bottom Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _selectedNotification = null),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to List'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ],
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
