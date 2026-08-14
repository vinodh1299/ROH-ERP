// lib/features/admin/dashboard/admin_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_service.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final now = DateTime.now();
    const dayNames = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final dateStr =
        '${now.day.toString().padLeft(2,'0')}-${now.month.toString().padLeft(2,'0')}-${now.year} ${dayNames[now.weekday - 1]}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.welcomeGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${user?.name ?? 'System Admin'} !',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'System Administration & Account Management Console',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // High Level Accounts Stat Cards
          Row(
            children: const [
              Expanded(
                child: _AdminStatCard(
                  label: 'Therapist Accounts',
                  count: '6 Registered',
                  icon: Icons.medical_services_outlined,
                  iconBg: Color(0xFFF3E8FF),
                  iconColor: AppColors.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _AdminStatCard(
                  label: 'Student Profiles',
                  count: '6 Active',
                  icon: Icons.school_outlined,
                  iconBg: Color(0xFFE0F7FA),
                  iconColor: AppColors.accentTeal,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _AdminStatCard(
                  label: 'Parent Accounts',
                  count: '5 Registered',
                  icon: Icons.family_restroom_outlined,
                  iconBg: Color(0xFFFFF3E0),
                  iconColor: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Section Overview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Administration Responsibilities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Use the sidebar tabs to manage system accounts and profiles:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _AdminTaskBullet(
                  icon: Icons.medical_services_outlined,
                  title: 'Therapist Accounts Management',
                  subtitle: 'Create therapist login credentials, configure access levels, and maintain active clinical staff records.',
                ),
                const SizedBox(height: 12),
                _AdminTaskBullet(
                  icon: Icons.school_outlined,
                  title: 'Student Profiles Creation & Intake',
                  subtitle: 'Build comprehensive 3-tab student records (personal details, medical history, medications, emergency contacts).',
                ),
                const SizedBox(height: 12),
                _AdminTaskBullet(
                  icon: Icons.family_restroom_outlined,
                  title: 'Parent Accounts Onboarding',
                  subtitle: 'Create parent login credentials, link families to assigned students, and grant portal monitoring access.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _AdminStatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTaskBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AdminTaskBullet({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
