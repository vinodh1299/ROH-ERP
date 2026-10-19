import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/widgets/account_password.dart';
import 'package:roh_erp/core/widgets/edit_record_dialogs.dart';

class AdminTherapistAddDialog extends StatefulWidget {
  const AdminTherapistAddDialog({super.key});

  @override
  State<AdminTherapistAddDialog> createState() =>
      _AdminTherapistAddDialogState();
}

class _AdminTherapistAddDialogState extends State<AdminTherapistAddDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _designationCtrl = TextEditingController(text: 'Behavior Therapist');
  final _passwordCtrl = TextEditingController();
  String? _passwordError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _designationCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter therapist Name and Email'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final password = _passwordCtrl.text;
    final policyError = optionalPasswordPolicyError(password);
    setState(() => _passwordError = policyError);
    if (policyError != null) return;

    setState(() => _isSubmitting = true);
    final res = await ApiService().post('add_therapist', {
      'name': name,
      'email': email,
      'phone': _phoneCtrl.text.trim(),
      'designation': _designationCtrl.text.trim(),
      if (password.isNotEmpty) 'password': password,
    });
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (showApiResult(context, res, 'Therapist added.')) {
      await showTemporaryPasswordIfAny(context, res, accountLabel: name);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Dialog(
      // Near full-width on phones.
      insetPadding: isPhone
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: EdgeInsets.all(isPhone ? 18 : 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Therapist',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Container(
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(top: 6, bottom: 24),
              ),
              Column(
                children: [
                  _buildField('Full Name', _nameCtrl, 'e.g. Jane Doe'),
                  const SizedBox(height: 16),
                  _buildField(
                      'Email Address', _emailCtrl, 'e.g. jane@rohcenter.org'),
                  const SizedBox(height: 16),
                  _buildField(
                      'Phone Number', _phoneCtrl, 'e.g. +1 (555) 012-3456'),
                  const SizedBox(height: 16),
                  _buildField('Designation', _designationCtrl,
                      'e.g. Behavior Therapist'),
                  const SizedBox(height: 16),
                  _buildField('Password (optional)', _passwordCtrl,
                      'Set an initial password',
                      obscure: true,
                      helper: kOptionalPasswordHelper,
                      error: _passwordError),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, String hint,
      {bool obscure = false, String? helper, String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          autocorrect: !obscure,
          enableSuggestions: !obscure,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperStyle:
                const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
            errorText: error,
            errorMaxLines: 2,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
