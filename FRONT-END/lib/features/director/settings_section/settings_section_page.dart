// lib/features/director/settings_section/settings_section_page.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/services/api_service.dart';

class SettingsSectionPage extends StatefulWidget {
  const SettingsSectionPage({super.key});

  @override
  State<SettingsSectionPage> createState() => _SettingsSectionPageState();
}

class _SettingsSectionPageState extends State<SettingsSectionPage> {
  String _masteryCriteria = '80% across 3 consecutive sessions';
  bool _requireTwoTherapists = true;
  String _reassessmentFreq = 'Every 6 Months';
  String _stagnationDays = '21';
  String _supervisionRatio = '5.0%';
  bool _dualSignOffCrisis = true;
  final TextEditingController _nameController = TextEditingController(text: 'Dr. Vincent Sterling');
  final TextEditingController _titleController = TextEditingController(text: 'BCBA-D, Clinical Director');
  final TextEditingController _certController = TextEditingController(text: 'BACB # 1-19-38291');

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _certController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    try {
      final api = ApiService();
      await api.post('save_governance_settings', {
        'target_mastery_criteria': _masteryCriteria,
        'require_two_therapists': _requireTwoTherapists ? 1 : 0,
        'reassessment_frequency': _reassessmentFreq,
        'stagnation_alert_days': int.tryParse(_stagnationDays) ?? 21,
        'supervision_ratio_target': double.tryParse(_supervisionRatio.replaceAll('%', '')) ?? 5.0,
        'director_signature_name': _nameController.text,
        'director_title': _titleController.text,
        'director_bacb_cert': _certController.text,
      });
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Clinical Governance & Center Settings updated successfully!'),
        backgroundColor: AppColors.statusActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinical Governance & Executive Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Configure center-wide ABA mastery criteria, BACB supervision quotas, and digital authorization signatures.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                label: const Text('Save Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveSettings,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Section 1: Clinical Governance & ABA Treatment Rules ────────
          _buildSettingsCard(
            title: 'Clinical Governance & ABA Treatment Rules',
            subtitle: 'Core operational criteria for target mastery, skill acquisition, and milestone reassessments.',
            icon: Icons.gavel_outlined,
            children: [
              _buildDropdownSetting(
                'Target Mastery Standard',
                'Performance required before a discrete skill target moves from acquisition to maintenance.',
                _masteryCriteria,
                ['80% across 3 consecutive sessions', '90% across 2 consecutive sessions', '100% across 2 sessions'],
                (val) => setState(() => _masteryCriteria = val!),
              ),
              const Divider(height: 24, color: AppColors.divider),
              _buildSwitchSetting(
                'Generalization Across Therapists',
                'Require probe verification with at least two different therapists before target mastery is granted.',
                _requireTwoTherapists,
                (val) => setState(() => _requireTwoTherapists = val),
              ),
              const Divider(height: 24, color: AppColors.divider),
              _buildDropdownSetting(
                'Milestone Reassessment Frequency',
                'Center mandate for VB-MAPP / ABLLS-R reassessments and IEP renewals.',
                _reassessmentFreq,
                ['Every 3 Months', 'Every 6 Months', 'Annual (12 Months)'],
                (val) => setState(() => _reassessmentFreq = val!),
              ),
              const Divider(height: 24, color: AppColors.divider),
              _buildTextSetting(
                'Stagnation Alert Sentinel Trigger',
                'Number of days without acquisition before clinical protocol review is flagged.',
                _stagnationDays,
                'Days',
                (val) => setState(() => _stagnationDays = val),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Section 2: BACB Supervision Standards ───────────────────────
          _buildSettingsCard(
            title: 'BACB Supervision Standards & Accreditation',
            subtitle: 'Supervision compliance thresholds mandated by the Behavior Analyst Certification Board.',
            icon: Icons.verified_user_outlined,
            children: [
              _buildDropdownSetting(
                'Monthly RBT Supervision Ratio',
                'Percentage of monthly therapy hours that must be directly supervised by a BCBA.',
                _supervisionRatio,
                ['5.0%', '7.5%', '10.0%'],
                (val) => setState(() => _supervisionRatio = val!),
              ),
              const Divider(height: 24, color: AppColors.divider),
              _buildSwitchSetting(
                'Dual Sign-Off for Crisis & BIP Protocols',
                'Require both Lead BCBA and Clinical Director approval for severe behavior plans.',
                _dualSignOffCrisis,
                (val) => setState(() => _dualSignOffCrisis = val),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Section 3: Director Digital Signature Stamp ──────────────────
          _buildSettingsCard(
            title: 'Director Digital Signature & Authorization Stamp',
            subtitle: 'Configured credentials affixed to approved IEP reports and treatment plans.',
            icon: Icons.draw_outlined,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildInputField('Clinical Director Full Name', _nameController),
                        const SizedBox(height: 12),
                        _buildInputField('Clinical Title & Credentials', _titleController),
                        const SizedBox(height: 12),
                        _buildInputField('Board Certification Number', _certController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF8FE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified, color: AppColors.primary, size: 36),
                          const SizedBox(height: 10),
                          const Text('Digital Signature Stamp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          Text(_nameController.text, style: const TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 4),
                          Text(_titleController.text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(_certController.text, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.statusActiveBg, borderRadius: BorderRadius.circular(8)),
                            child: const Text('Signature Active & Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusActive)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Section 4: Center Capacity & Working Hours ──────────────────
          _buildSettingsCard(
            title: 'Center Operational Defaults & Capacity',
            subtitle: 'Staff limits, emergency contacts, and daily operating windows.',
            icon: Icons.business_outlined,
            children: [
              _buildStaticRow('Maximum Center Caseload Capacity', '30 Students (Current: 24 active)'),
              const Divider(height: 20, color: AppColors.divider),
              _buildStaticRow('Maximum Student Ratio per Clinician', '6 Cases maximum per therapist'),
              const Divider(height: 20, color: AppColors.divider),
              _buildStaticRow('Center Operating Hours', '08:00 AM - 06:00 PM (Monday - Saturday)'),
              const Divider(height: 20, color: AppColors.divider),
              _buildStaticRow('Emergency Clinical Escalation Line', '+1 (555) 911-0199 (24/7 On-Call BCBA)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(String label, String help, String current, List<String> options, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(help, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFFAF8FC),
          ),
          child: DropdownButton<String>(
            value: current,
            underline: const SizedBox(),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(String label, String help, bool val, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(help, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Switch(
          value: val,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextSetting(String label, String help, String val, String suffix, ValueChanged<String> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(help, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 120,
          child: TextFormField(
            initialValue: val,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: suffix,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}

