// lib/features/parent/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_service.dart';

class ParentProfilePage extends StatefulWidget {
  const ParentProfilePage({super.key});

  @override
  State<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends State<ParentProfilePage> {
  bool _emailAlerts = true;
  bool _smsAlerts = true;
  bool _weeklyDigest = true;

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
                  radius: 36,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'P',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Parent / Guardian', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      const Text('Parent of: Noah Johnson (Age: 8)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Primary Parent Account', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile details updated.')));
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Details'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Details Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact & Guardian Information
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Guardian Contact Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildRow(Icons.email_outlined, 'Email', user?.email ?? 'parent@roh.org'),
                      const Divider(height: 20),
                      _buildRow(Icons.phone_outlined, 'Mobile Phone', '+1 (555) 987-6543'),
                      const Divider(height: 20),
                      _buildRow(Icons.location_on_outlined, 'Home Address', '742 Evergreen Terrace, Springfield'),
                      const Divider(height: 20),
                      _buildRow(Icons.medical_services_outlined, 'Primary BCBA', 'Sarah Adams (BCBA)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Notification Preferences
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notification Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Email Report Notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Get email notifications when new IEP reports are uploaded', style: TextStyle(fontSize: 11)),
                        value: _emailAlerts,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _emailAlerts = v),
                      ),
                      SwitchListTile(
                        title: const Text('SMS Reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Receive SMS reminders for therapy session schedules', style: TextStyle(fontSize: 11)),
                        value: _smsAlerts,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _smsAlerts = v),
                      ),
                      SwitchListTile(
                        title: const Text('Weekly Progress Digest', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Weekly summary email of child progress graphs', style: TextStyle(fontSize: 11)),
                        value: _weeklyDigest,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _weeklyDigest = v),
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

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}
