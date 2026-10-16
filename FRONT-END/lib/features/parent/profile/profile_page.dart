import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import 'package:roh_erp/features/auth/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _emailNotifs = true;
  bool _smsNotifs = true;
  bool _sessionAlerts = true;
  bool _iepUpdates = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final parentName = user?.name.isNotEmpty == true ? user!.name : 'User';
    final parentEmail =
        user?.email.isNotEmpty == true ? user!.email : 'Not provided';

    final isPhone = Breakpoints.isCompact(context);
    final cardPadding = EdgeInsets.all(isPhone ? 16 : 24);
    return SingleChildScrollView(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Title ──
          const Text(
            'Parent Profile & Account Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage guardian contacts, emergency notifications, and view enrolled child information.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // ── Parent Guardian Card ──
          Container(
            padding: cardPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: isPhone ? 28 : 36,
                  backgroundColor:
                      AppColors.primaryLight.withValues(alpha: 0.15),
                  child: Icon(Icons.person,
                      size: isPhone ? 30 : 40, color: AppColors.primary),
                ),
                SizedBox(width: isPhone ? 14 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + "Primary Guardian" chip; the chip wraps under
                      // the name when there isn't room beside it.
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            parentName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Primary Guardian',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: $parentEmail',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Contact your center administrator to update profile details.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Enrolled Child Overview Card ──
          Container(
            padding: cardPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.child_care, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enrolled Child Information',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.divider),
                if (ScheduleService.centerStudents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.child_care_outlined,
                              size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text(
                            'No Enrolled Child Linked Yet',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Once your child is enrolled by the Center Director, their clinical profile, assigned BCBA, and health protocols will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  _buildInfoRow('Child Name',
                      ScheduleService.centerStudents.first['name'] as String),
                  _buildInfoRow('Age',
                      '${ScheduleService.centerStudents.first['age']} years'),
                  _buildInfoRow(
                      'Active Program',
                      (ScheduleService.centerStudents.first['programs']
                              as String?) ??
                          'Comprehensive Behavioral Program'),
                  _buildInfoRow(
                      'Assigned Clinical BCBA',
                      ScheduleService.centerTherapists.isNotEmpty
                          ? ScheduleService.centerTherapists.first['name']!
                          : 'Pending Assignment'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Communication & Notification Preferences ──
          Container(
            padding: cardPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active_outlined,
                        color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Center Alerts & Notification Preferences',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Session Completion Alerts',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text(
                      'Receive notifications when therapist concludes daily session.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  value: _sessionAlerts,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _sessionAlerts = val),
                ),
                const Divider(height: 16, color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('IEP Approval & Clinical Milestone Updates',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text(
                      'Instant notification when Clinical Director authorizes quarterly IEP.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  value: _iepUpdates,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _iepUpdates = val),
                ),
                const Divider(height: 16, color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Email Digest & Progress Reports',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text(
                      'Weekly summary of skills mastered sent to parent email.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  value: _emailNotifs,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _emailNotifs = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            // Narrower label column on phones.
            width: Breakpoints.isCompact(context) ? 130 : 200,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
