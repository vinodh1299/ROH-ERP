// lib/core/widgets/notification_detail_dialog.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/notification_service.dart';

class NotificationDetailDialog extends StatelessWidget {
  final NotificationItem item;

  const NotificationDetailDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, NotificationItem item) async {
    // Automatically mark as read when user views details
    if (!item.isRead) {
      NotificationService().markAsRead(item.id);
    }

    return showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => NotificationDetailDialog(item: item),
    );
  }

  IconData _getCategoryIcon(String type) {
    if (type.contains('APPOINTMENT')) return Icons.calendar_month_rounded;
    if (type.contains('SESSION')) return Icons.medical_services_rounded;
    if (type.contains('REPORT') || type.contains('IEP')) return Icons.assessment_rounded;
    if (type.contains('PASSWORD') || type.contains('LOCKED') || type.contains('SECURITY')) {
      return Icons.shield_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Color _getCategoryColor(String type) {
    if (type.contains('APPOINTMENT')) return const Color(0xFF7B2FBE);
    if (type.contains('SESSION')) return const Color(0xFF2563EB);
    if (type.contains('REPORT') || type.contains('IEP')) return const Color(0xFF059669);
    if (type.contains('PASSWORD') || type.contains('LOCKED') || type.contains('SECURITY')) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFF4F46E5);
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
    final catColor = _getCategoryColor(item.eventType);
    final catIcon = _getCategoryIcon(item.eventType);
    final catLabel = _formatCategoryLabel(item.eventType);
    final meta = item.metadata;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxHeight: 640),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 28,
                offset: Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header banner
              Container(
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border(bottom: BorderSide(color: catColor.withOpacity(0.15), width: 1)),
                ),
                child: Row(
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            'Marked Read',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      splashRadius: 18,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Body content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
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
                      const SizedBox(height: 18),

                      // Message Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          item.message,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF334155),
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Metadata cards if available
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
                                _buildMetaRow(
                                  icon: Icons.person_rounded,
                                  label: 'Attendee',
                                  value: '${meta['attendee_name']}',
                                ),
                              if (meta.containsKey('date'))
                                _buildMetaRow(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Date',
                                  value: '${meta['date']}',
                                ),
                              if (meta.containsKey('start_time'))
                                _buildMetaRow(
                                  icon: Icons.schedule_rounded,
                                  label: 'Scheduled Time',
                                  value: '${meta['start_time']}',
                                ),
                              if (meta.containsKey('title'))
                                _buildMetaRow(
                                  icon: Icons.bookmark_border_rounded,
                                  label: 'Topic',
                                  value: '${meta['title']}',
                                ),
                              if (meta.containsKey('appointment_id'))
                                _buildMetaRow(
                                  icon: Icons.confirmation_number_outlined,
                                  label: 'Reference ID',
                                  value: '#APPT-${meta['appointment_id']}',
                                  isLast: true,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Dismiss', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('OK, Got it', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
}
