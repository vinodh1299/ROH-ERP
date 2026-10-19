import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/widgets/edit_record_dialogs.dart';

import 'package:roh_erp/core/constants/app_images.dart';
import '../../auth/widgets/forced_password_change_dialog.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  static const _defaults = {
    'center_name': 'Ray of Hope Center for Autism',
    'portal_title': 'Ray of Hope Center for Autism',
    'support_email': 'admin@roh.com',
    'emergency_hotline': 'Contact center administration',
  };

  final _centerName = TextEditingController(text: _defaults['center_name']);
  final _portalTitle = TextEditingController(text: _defaults['portal_title']);
  final _supportEmail = TextEditingController(text: _defaults['support_email']);
  final _hotline = TextEditingController(text: _defaults['emergency_hotline']);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _centerName.dispose();
    _portalTitle.dispose();
    _supportEmail.dispose();
    _hotline.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final res = await ApiService().get('get_center_settings');
    if (!mounted || res is! Map || res.containsKey('error')) return;
    void fill(TextEditingController c, String key) {
      final v = res[key]?.toString().trim();
      if (v != null && v.isNotEmpty) c.text = v;
    }

    setState(() {
      fill(_centerName, 'center_name');
      fill(_portalTitle, 'portal_title');
      fill(_supportEmail, 'support_email');
      fill(_hotline, 'emergency_hotline');
    });
  }

  Future<void> _saveSettings() async {
    final email = _supportEmail.text.trim();
    if (_centerName.text.trim().isEmpty ||
        _portalTitle.text.trim().isEmpty ||
        (email.isNotEmpty &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Enter a center name, a portal title and a valid support email.')));
      return;
    }
    setState(() => _saving = true);
    final res = await ApiService().post('save_center_settings', {
      'center_name': _centerName.text.trim(),
      'portal_title': _portalTitle.text.trim(),
      'support_email': email,
      'emergency_hotline': _hotline.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    showApiResult(context, res, 'Center settings updated.');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Application Settings',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Container(
              padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 18 : 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
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
                  AppImages.therapistAvatar(radius: 44),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 550;
                      if (isNarrow) {
                        return Column(
                          children: [
                            _buildTextField('Center Name', _centerName),
                            const SizedBox(height: 16),
                            _buildTextField('Portal Title', _portalTitle),
                            const SizedBox(height: 24),
                            Center(
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      ForcedPasswordChangeDialog.show(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: const Text('Change Password',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                                'Support Contact Email', _supportEmail,
                                keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildTextField('Emergency Hotline', _hotline),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _buildTextField(
                                      'Center Name', _centerName)),
                              const SizedBox(width: 24),
                              Expanded(
                                  child: _buildTextField(
                                      'Portal Title', _portalTitle)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: SizedBox(
                              width: 260,
                              child: OutlinedButton(
                                onPressed: () =>
                                    ForcedPasswordChangeDialog.show(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                      color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Change Password',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                  child: _buildTextField(
                                      'Support Contact Email', _supportEmail,
                                      keyboardType:
                                          TextInputType.emailAddress)),
                              const SizedBox(width: 24),
                              Expanded(
                                  child: _buildTextField(
                                      'Emergency Hotline', _hotline)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Update',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: _hintFor(controller),
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  String? _hintFor(TextEditingController c) {
    if (identical(c, _centerName)) return _defaults['center_name'];
    if (identical(c, _portalTitle)) return _defaults['portal_title'];
    if (identical(c, _supportEmail)) return _defaults['support_email'];
    if (identical(c, _hotline)) return _defaults['emergency_hotline'];
    return null;
  }
}
