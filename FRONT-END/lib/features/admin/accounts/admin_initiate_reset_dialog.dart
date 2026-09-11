// lib/features/admin/accounts/admin_initiate_reset_dialog.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';

class AdminInitiateResetDialog extends StatefulWidget {
  final int userId;
  final String userName;
  final String userEmail;
  final String userRole;

  const AdminInitiateResetDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
  });

  static Future<bool?> show({
    required BuildContext context,
    required int userId,
    required String userName,
    required String userEmail,
    required String userRole,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AdminInitiateResetDialog(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userRole: userRole,
      ),
    );
  }

  @override
  State<AdminInitiateResetDialog> createState() => _AdminInitiateResetDialogState();
}

class _AdminInitiateResetDialogState extends State<AdminInitiateResetDialog> {
  final _reasonController = TextEditingController(text: 'User lost device / locked out');
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService().post('initiate_password_reset', {
        'user_id': widget.userId,
        'reason': _reasonController.text.trim(),
      });

      if (res is Map<String, dynamic> && res['error'] != null) {
        setState(() {
          _errorMessage = res['error'];
          _isSubmitting = false;
        });
        return;
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset for ${widget.userName} forwarded to Clinical Director for approval.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Initiate Password Reset',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Requires Clinical Director Approval (FRS 3.0)',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Target user card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account: ${widget.userName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Email: ${widget.userEmail} • Role: ${widget.userRole.toUpperCase()}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12.5)),
              ),
            ],

            const Text('Reason / Operational Justification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter reason for reset request...',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 14),

            // Security assurance notice
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Zero plaintext passwords stored. Once approved by Director, a 1-time temp credential is issued with 48h expiry.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit to Director', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
