import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
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
    final parentName = user?.name.isNotEmpty == true ? user!.name : 'Mr. John Wilson';
    final parentEmail = user?.email.isNotEmpty == true ? user!.email : 'parent@roh.com';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
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
            padding: const EdgeInsets.all(24),
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
                  radius: 36,
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                  child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            parentName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.15),
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
                        'Email: $parentEmail  •  Mobile: +1 (555) 019-2831',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Address: 742 Evergreen Terrace, Springfield, OR 97477',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
            padding: const EdgeInsets.all(24),
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
                    Text(
                      'Enrolled Child Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.divider),
                _buildInfoRow('Child Name', 'Alex Thomas Sam'),
                _buildInfoRow('Date of Birth', '12 April 2019 (Age: 7)'),
                _buildInfoRow('Primary Diagnosis', 'Autism Spectrum Disorder (Level 2)'),
                _buildInfoRow('Assigned Clinical BCBA', 'Dr. Sarah Lee (Lead BCBA)'),
                _buildInfoRow('Active Program', 'Comprehensive Verbal Behavior & DTT'),
                _buildInfoRow('Emergency EpiPen', 'Clinic Cabinet #2 (Peanut Allergy Protocol)'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Communication & Notification Preferences ──
          Container(
            padding: const EdgeInsets.all(24),
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
                    Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Center Alerts & Notification Preferences',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Session Completion Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Receive notifications when therapist concludes daily session.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _sessionAlerts,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _sessionAlerts = val),
                ),
                const Divider(height: 16, color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('IEP Approval & Clinical Milestone Updates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Instant notification when Clinical Director authorizes quarterly IEP.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _iepUpdates,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _iepUpdates = val),
                ),
                const Divider(height: 16, color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Email Digest & Progress Reports', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Weekly summary of skills mastered sent to parent email.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
            width: 200,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
