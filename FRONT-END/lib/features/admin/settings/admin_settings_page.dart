// lib/features/admin/settings/admin_settings_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _centerNameCtrl = TextEditingController(text: AppConstants.centerName);
  final _emailDomainCtrl = TextEditingController(text: 'roh.org');
  final _maxCapacityCtrl = TextEditingController(text: '150');

  bool _enableAutoBackup = true;
  bool _requireTwoFactor = true;
  bool _allowParentSelfRegistration = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF37474F), Color(0xFF546E7A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'System Settings & Center Configuration',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text('Global ERP Administration & System Governance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Admin settings saved successfully!'), backgroundColor: Colors.green),
                    );
                  },
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Center Profile Settings
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
                      const Text('Center Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _centerNameCtrl,
                        decoration: const InputDecoration(labelText: 'Center Name', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _emailDomainCtrl,
                        decoration: const InputDecoration(labelText: 'Allowed Email Domain', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _maxCapacityCtrl,
                        decoration: const InputDecoration(labelText: 'Maximum Student Capacity', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Security & Data Policies
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
                      const Text('Security & Governance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Automated Daily Cloud Backup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Nightly backup of trial logs & IEP reports', style: TextStyle(fontSize: 11)),
                        value: _enableAutoBackup,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _enableAutoBackup = v),
                      ),
                      SwitchListTile(
                        title: const Text('Enforce 2FA for Staff', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Require 2-factor authentication for BCBAs & Admin', style: TextStyle(fontSize: 11)),
                        value: _requireTwoFactor,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _requireTwoFactor = v),
                      ),
                      SwitchListTile(
                        title: const Text('Parent Self-Registration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Allow parents to create accounts online', style: TextStyle(fontSize: 11)),
                        value: _allowParentSelfRegistration,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _allowParentSelfRegistration = v),
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
}
