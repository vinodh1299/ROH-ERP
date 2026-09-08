// lib/features/therapist/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_service.dart';

class TherapistProfilePage extends StatefulWidget {
  const TherapistProfilePage({super.key});

  @override
  State<TherapistProfilePage> createState() => _TherapistProfilePageState();
}

class _TherapistProfilePageState extends State<TherapistProfilePage> {
  bool _emailNotifications = true;
  bool _smsAlerts = false;
  bool _dailySummary = true;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'T',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Lead Therapist',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Board Certified Behavior Analyst (BCBA) | Senior Therapist',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Active Staff', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                          const SizedBox(width: 12),
                          const Text('ID: TH-80429', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit Profile details saved.')),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Details Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact & Credentials Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Therapist Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.email_outlined, 'Email', user?.email ?? 'therapist@roh.org'),
                      const Divider(height: 20),
                      _buildInfoRow(Icons.phone_outlined, 'Phone', '+1 (555) 234-5678'),
                      const Divider(height: 20),
                      _buildInfoRow(Icons.badge_outlined, 'License Number', 'BCBA-2024-99120'),
                      const Divider(height: 20),
                      _buildInfoRow(Icons.location_on_outlined, 'Branch Location', 'ROH Autism Center - Main Campus'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Notification Preferences & Assigned Students
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notification Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Email Notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Receive daily session updates & IEP alerts', style: TextStyle(fontSize: 11)),
                        value: _emailNotifications,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _emailNotifications = v),
                      ),
                      SwitchListTile(
                        title: const Text('SMS Urgent Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Get instant SMS for ABC behavioral incidents', style: TextStyle(fontSize: 11)),
                        value: _smsAlerts,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _smsAlerts = v),
                      ),
                      SwitchListTile(
                        title: const Text('Daily Summary Digest', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Automated end-of-day trial summary report', style: TextStyle(fontSize: 11)),
                        value: _dailySummary,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _dailySummary = v),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}
