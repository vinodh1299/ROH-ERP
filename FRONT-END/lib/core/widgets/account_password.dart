// lib/core/widgets/account_password.dart
// Password helpers for "add account" forms (therapists, parents).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roh_erp/core/constants/app_colors.dart';

/// Helper text for an optional password field on an add-account form.
const String kOptionalPasswordHelper =
    'Leave blank to generate a one-time password';

/// Same rule the server enforces: at least 8 characters with an uppercase
/// letter, a lowercase letter and a number. Returns an error message, or null
/// when [password] is acceptable. An empty value is allowed (the server then
/// generates a one-time password).
String? optionalPasswordPolicyError(String? password) {
  final p = password ?? '';
  if (p.isEmpty) return null;
  if (p.length < 8 ||
      !RegExp(r'[A-Z]').hasMatch(p) ||
      !RegExp(r'[a-z]').hasMatch(p) ||
      !RegExp(r'[0-9]').hasMatch(p)) {
    return 'Use at least 8 characters with uppercase, lowercase and a number.';
  }
  return null;
}

/// Shows the server-generated one-time password once, with a copy button.
/// Does nothing when [response] has no `temporary_password`.
Future<void> showTemporaryPasswordIfAny(
  BuildContext context,
  dynamic response, {
  required String accountLabel,
}) async {
  final temp = response is Map ? response['temporary_password'] : null;
  if (temp is! String || temp.isEmpty) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _TemporaryPasswordDialog(password: temp, accountLabel: accountLabel),
  );
}

class _TemporaryPasswordDialog extends StatefulWidget {
  final String password;
  final String accountLabel;

  const _TemporaryPasswordDialog({
    required this.password,
    required this.accountLabel,
  });

  @override
  State<_TemporaryPasswordDialog> createState() =>
      _TemporaryPasswordDialogState();
}

class _TemporaryPasswordDialogState extends State<_TemporaryPasswordDialog> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.password));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text(
        'One-time password',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign-in password for ${widget.accountLabel}:',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.password,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _copy,
                    icon: Icon(_copied ? Icons.check : Icons.copy_rounded,
                        size: 16),
                    label: Text(_copied ? 'Copied' : 'Copy'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Share this securely. They must set a new password at first "
              "sign-in. It won't be shown again.",
              style: TextStyle(
                  fontSize: 12, height: 1.4, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
