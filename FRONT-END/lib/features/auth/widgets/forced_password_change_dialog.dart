// lib/features/auth/widgets/forced_password_change_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../auth_service.dart';

class ForcedPasswordChangeDialog extends StatefulWidget {
  const ForcedPasswordChangeDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.mustChangePassword) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const ForcedPasswordChangeDialog(),
      );
    }
  }

  @override
  State<ForcedPasswordChangeDialog> createState() => _ForcedPasswordChangeDialogState();
}

class _ForcedPasswordChangeDialogState extends State<ForcedPasswordChangeDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _hasMinLength => _newController.text.length >= 8;
  bool get _hasUppercase => _newController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _newController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _newController.text.contains(RegExp(r'[0-9]'));
  bool get _isCompliant => _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber;
  bool get _matchesConfirm => _newController.text == _confirmController.text && _confirmController.text.isNotEmpty;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_isCompliant) {
      setState(() => _errorMessage = 'Please meet all password complexity requirements.');
      return;
    }

    if (!_matchesConfirm) {
      setState(() => _errorMessage = 'New passwords do not match.');
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    final result = await auth.changePassword(_currentController.text, _newController.text);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Welcome to Ray of Hope ERP.'),
          backgroundColor: AppColors.statusActive,
        ),
      );
    } else {
      setState(() {
        _errorMessage = result['error'] ?? 'Failed to update password. Please check your current password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Non-dismissible
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge + Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password Update Required',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Temporary credentials must be replaced before proceeding',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Current (Temporary) Password
                const Text('Current / Temporary Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _currentController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    hintText: 'Enter temporary password',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // New Password
                const Text('New Secure Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Enter at least 8 characters',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Complexity Checklist
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildCheckItem('At least 8 characters long', _hasMinLength),
                      const SizedBox(height: 4),
                      _buildCheckItem('Contains at least one uppercase letter (A-Z)', _hasUppercase),
                      const SizedBox(height: 4),
                      _buildCheckItem('Contains at least one lowercase letter (a-z)', _hasLowercase),
                      const SizedBox(height: 4),
                      _buildCheckItem('Contains at least one numeric digit (0-9)', _hasNumber),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                const Text('Re-enter New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Re-enter new password',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting || !_isCompliant || !_matchesConfirm ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Update Password & Access Center', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String label, bool satisfied) {
    return Row(
      children: [
        Icon(
          satisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: satisfied ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: satisfied ? const Color(0xFF166534) : const Color(0xFF64748B),
            fontWeight: satisfied ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
