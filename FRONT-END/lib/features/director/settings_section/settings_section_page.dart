// lib/features/director/settings_section/settings_section_page.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/services/governance_settings.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import 'package:roh_erp/core/widgets/edit_record_dialogs.dart';

class SettingsSectionPage extends StatefulWidget {
  const SettingsSectionPage({super.key});

  @override
  State<SettingsSectionPage> createState() => _SettingsSectionPageState();
}

class _SettingsSectionPageState extends State<SettingsSectionPage> {
  String _masteryCriteria = '80% across 3 consecutive sessions';
  bool _requireTwoTherapists = true;
  String _reassessmentFreq = 'Every 6 Months';
  final TextEditingController _stagnationController =
      TextEditingController(text: '21');
  String _supervisionRatio = '5.0%';
  bool _dualSignOffCrisis = true;
  final TextEditingController _nameController =
      TextEditingController(text: 'Clinical Director');
  final TextEditingController _titleController =
      TextEditingController(text: 'BCBA, Clinical Director');
  final TextEditingController _certController = TextEditingController(text: '');
  String _emergencyLine = 'Not configured';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Keep the signature stamp preview in sync while typing.
    for (final c in [_nameController, _titleController, _certController]) {
      c.addListener(_onStampChanged);
    }
    _loadSettings();
  }

  void _onStampChanged() {
    if (mounted) setState(() {});
  }

  /// Loads saved governance settings; the current values stay as defaults
  /// when nothing has been saved yet (the API returns null).
  Future<void> _loadSettings() async {
    final api = ApiService();
    final results = await Future.wait([
      api.get('get_governance_settings'),
      api.get('get_center_settings'),
    ]);
    if (!mounted) return;
    final g = results[0];
    final c = results[1];
    setState(() {
      if (c is Map && c['error'] == null) {
        final line = (c['emergency_hotline'] ?? '').toString().trim();
        if (line.isNotEmpty) _emergencyLine = line;
      }
      if (g is! Map || g['error'] != null) return;
      String str(String k, String fallback) {
        final v = (g[k] ?? '').toString().trim();
        return v.isEmpty ? fallback : v;
      }

      bool flag(String k, bool fallback) {
        final v = g[k];
        if (v == null) return fallback;
        return v == 1 || v == true || v.toString() == '1';
      }

      _masteryCriteria = str('target_mastery_criteria', _masteryCriteria);
      _requireTwoTherapists =
          flag('require_two_therapists', _requireTwoTherapists);
      _reassessmentFreq = str('reassessment_frequency', _reassessmentFreq);
      _stagnationController.text =
          str('stagnation_alert_days', _stagnationController.text);
      final ratio =
          double.tryParse((g['supervision_ratio_target'] ?? '').toString());
      if (ratio != null) _supervisionRatio = '${ratio.toStringAsFixed(1)}%';
      _dualSignOffCrisis = flag('dual_signoff_crisis', _dualSignOffCrisis);
      _nameController.text =
          str('director_signature_name', _nameController.text);
      _titleController.text = str('director_title', _titleController.text);
      _certController.text = str('director_bacb_cert', _certController.text);
    });
  }

  @override
  void dispose() {
    _stagnationController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _certController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final days = int.tryParse(_stagnationController.text.trim());
    if (days == null || days < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Review alert days must be a whole number of 1 or more.'),
        backgroundColor: AppColors.statusDeactivated,
      ));
      return;
    }
    setState(() => _saving = true);
    final res = await ApiService().post('save_governance_settings', {
      'target_mastery_criteria': _masteryCriteria,
      'require_two_therapists': _requireTwoTherapists ? 1 : 0,
      'reassessment_frequency': _reassessmentFreq,
      'stagnation_alert_days': days,
      'supervision_ratio_target':
          double.tryParse(_supervisionRatio.replaceAll('%', '')) ?? 5.0,
      'dual_signoff_crisis': _dualSignOffCrisis ? 1 : 0,
      'director_signature_name': _nameController.text.trim(),
      'director_title': _titleController.text.trim(),
      'director_bacb_cert': _certController.text.trim(),
    });
    // Progress pages re-read the mastery criteria / review threshold.
    GovernanceSettings.invalidate();
    if (!mounted) return;
    setState(() => _saving = false);
    showApiResult(context, res,
        'Clinical Governance & Center Settings updated successfully!');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──────────────────────────────────────────────────
          _ResponsiveHeader(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinical Governance & Executive Settings',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Configure center-wide ABA mastery criteria, BACB supervision quotas, and digital authorization signatures.',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            action: ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              label: const Text('Save Settings',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _saving ? null : _saveSettings,
            ),
          ),
          const SizedBox(height: 24),

          // ── Section 1: Clinical Governance & ABA Treatment Rules ────────
          _buildSettingsCard(
            title: 'Clinical Governance & ABA Treatment Rules',
            subtitle:
                'Core operational criteria for target mastery, skill acquisition, and milestone reassessments.',
            icon: Icons.gavel_outlined,
            children: [
              _buildDropdownSetting(
                'Target Mastery Standard',
                'Performance required before a discrete skill target moves from acquisition to maintenance.',
                _masteryCriteria,
                [
                  '80% across 3 consecutive sessions',
                  '90% across 2 consecutive sessions',
                  '100% across 2 sessions'
                ],
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
                'No-progress review threshold',
                'Number of days without progress on a target before it is listed under "Targets needing review".',
                _stagnationController,
                'Days',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Section 2: BACB Supervision Standards ───────────────────────
          _buildSettingsCard(
            title: 'BACB Supervision Standards & Accreditation',
            subtitle:
                'Supervision compliance thresholds mandated by the Behavior Analyst Certification Board.',
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
            subtitle:
                'Configured credentials affixed to approved IEP reports and treatment plans.',
            icon: Icons.draw_outlined,
            children: [
              LayoutBuilder(builder: (context, constraints) {
                final fields = Column(
                  children: [
                    _buildInputField(
                        'Clinical Director Full Name', _nameController),
                    const SizedBox(height: 12),
                    _buildInputField(
                        'Clinical Title & Credentials', _titleController),
                    const SizedBox(height: 12),
                    _buildInputField(
                        'Board Certification Number', _certController),
                  ],
                );
                final stamp = Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF8FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified,
                          color: AppColors.primary, size: 36),
                      const SizedBox(height: 10),
                      const Text('Digital Signature Stamp',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text(_nameController.text,
                          style: const TextStyle(
                              fontFamily: 'serif',
                              fontStyle: FontStyle.italic,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(_titleController.text,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      Text(_certController.text,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textHint)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.statusActiveBg,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Signature Active & Verified',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.statusActive)),
                      ),
                    ],
                  ),
                );
                // Narrow: stack the stamp preview under the input fields.
                if (constraints.maxWidth < _stackBelow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [fields, const SizedBox(height: 16), stamp],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: fields),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: stamp),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 20),

          // ── Section 4: Center Capacity & Working Hours ──────────────────
          _buildSettingsCard(
            title: 'Center Operational Defaults & Capacity',
            subtitle:
                'Staff limits, emergency contacts, and daily operating windows.',
            icon: Icons.business_outlined,
            children: [
              _buildStaticRow(
                  'Maximum Center Caseload Capacity', '30 Students'),
              const Divider(height: 20, color: AppColors.divider),
              _buildStaticRow('Maximum Student Ratio per Clinician',
                  '6 Cases maximum per therapist'),
              const Divider(height: 20, color: AppColors.divider),
              _buildStaticRow('Center Operating Hours',
                  '08:00 AM - 06:00 PM (Monday - Saturday)'),
              const Divider(height: 20, color: AppColors.divider),
              _buildStaticRow(
                  'Emergency Clinical Escalation Line', _emergencyLine),
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
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 16 : 22),
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
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  /// Below this content width a setting's control is stacked under its
  /// label/description instead of sitting to the right.
  static const double _stackBelow = 560;

  Widget _settingLabel(String label, String help) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(help,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  /// Label + description on the left and [control] on the right; stacks the
  /// control below the text when the row is narrower than [_stackBelow].
  Widget _settingRow(
      String label, String help, Widget Function(bool stacked) control,
      {double gap = 20}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _settingLabel(label, help),
              const SizedBox(height: 10),
              control(true),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _settingLabel(label, help)),
            SizedBox(width: gap),
            control(false),
          ],
        );
      },
    );
  }

  Widget _buildDropdownSetting(String label, String help, String current,
      List<String> options, ValueChanged<String?> onChanged) {
    return _settingRow(
      label,
      help,
      (stacked) => Container(
        width: stacked ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFFAF8FC),
        ),
        child: DropdownButton<String>(
          value: current,
          isExpanded: stacked,
          underline: const SizedBox(),
          // A saved value outside the presets is still selectable.
          items: (options.contains(current) ? options : [current, ...options])
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
      String label, String help, bool val, ValueChanged<bool> onChanged) {
    return _settingRow(
      label,
      help,
      (_) => Switch(
        value: val,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
      gap: 0,
    );
  }

  Widget _buildTextSetting(String label, String help,
      TextEditingController controller, String suffix) {
    return _settingRow(
      label,
      help,
      (_) => SizedBox(
        width: 120,
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: suffix,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticRow(String label, String value) {
    const labelStyle = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    const valueStyle = TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: 4),
              Text(value, style: valueStyle),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: labelStyle)),
            const SizedBox(width: 16),
            Flexible(
                child:
                    Text(value, textAlign: TextAlign.right, style: valueStyle)),
          ],
        );
      },
    );
  }
}

/// Page header: title block on the left and action button(s) on the right;
/// stacks the actions under the title when there is not enough width.
class _ResponsiveHeader extends StatelessWidget {
  final Widget title;
  final Widget action;
  const _ResponsiveHeader({required this.title, required this.action});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), action],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            action,
          ],
        );
      },
    );
  }
}
