// lib/features/parent/consent/dpdp_consent_dialog.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';

class DpdpConsentDialog extends StatefulWidget {
  final int studentId;
  final String studentName;

  const DpdpConsentDialog({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  static Future<bool?> show(BuildContext context, {required int studentId, required String studentName}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DpdpConsentDialog(studentId: studentId, studentName: studentName),
    );
  }

  static Future<void> showIfNeeded(BuildContext context, {int studentId = 1, String studentName = 'Alex Thomas Sam'}) async {
    final prefs = await SharedPreferences.getInstance();
    final consentGiven = prefs.getBool('dpdp_consent_student_$studentId') ?? false;
    if (!consentGiven && context.mounted) {
      final res = await show(context, studentId: studentId, studentName: studentName);
      if (res == true) {
        await prefs.setBool('dpdp_consent_student_$studentId', true);
      }
    }
  }

  @override
  State<DpdpConsentDialog> createState() => _DpdpConsentDialogState();
}

class _DpdpConsentDialogState extends State<DpdpConsentDialog> {
  bool _agreedToClinicalProcessing = false;
  bool _agreedToRecordRetention = false;
  bool _agreedToEmergencyDisclosures = false;
  bool _isSubmitting = false;

  bool get _canSubmit => _agreedToClinicalProcessing && _agreedToRecordRetention && _agreedToEmergencyDisclosures;

  Future<void> _submitConsent() async {
    setState(() => _isSubmitting = true);
    try {
      await ApiService().post('record_parental_consent', {
        'student_id': widget.studentId,
        'consent_version': 'DPDP-2023-V1',
      });
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parental consent recorded under India DPDP Act 2023.'),
          backgroundColor: AppColors.statusActive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          width: 520,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.gavel_rounded, color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Digital Data Consent',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          Text(
                            'India Digital Personal Data Protection (DPDP) Act 2023',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  'Ray of Hope Center for Autism securely processes health, behavioral, and developmental milestone records for your child, ${widget.studentName}.',
                  style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: _agreedToClinicalProcessing,
                        onChanged: (v) => setState(() => _agreedToClinicalProcessing = v ?? false),
                        title: const Text('Clinical & Therapy Data Processing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        subtitle: const Text('I authorize certified therapists and BCBA supervisors to document behavioral trials and IEP progress.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        value: _agreedToRecordRetention,
                        onChanged: (v) => setState(() => _agreedToRecordRetention = v ?? false),
                        title: const Text('Retention & Portability Rights', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        subtitle: const Text('Records are maintained for clinical continuity. You retain the right to request a full data dossier export.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        value: _agreedToEmergencyDisclosures,
                        onChanged: (v) => setState(() => _agreedToEmergencyDisclosures = v ?? false),
                        title: const Text('Emergency Clinical Protocols', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        subtitle: const Text('Allergies and emergency contacts may be accessed immediately during on-site clinical urgencies.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: !_canSubmit || _isSubmitting ? null : _submitConsent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Record Digital Consent & Continue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
