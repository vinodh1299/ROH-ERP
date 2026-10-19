import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'package:roh_erp/core/layout/responsive.dart';

/// Version of the consent text below. Bump it when the wording changes so
/// every parent is asked again.
const String kDpdpConsentVersion = 'DPDP-2023-V1';

/// One child of the signed-in parent and the latest consent the server holds.
class ChildConsent {
  final int studentId;
  final String studentName;
  final String? version;
  final DateTime? agreedAt;
  final DateTime? withdrawnAt;

  const ChildConsent({
    required this.studentId,
    required this.studentName,
    this.version,
    this.agreedAt,
    this.withdrawnAt,
  });

  bool get isWithdrawn => agreedAt != null && withdrawnAt != null;

  bool get isGiven => agreedAt != null && withdrawnAt == null;

  /// Given for the current consent text and not withdrawn.
  bool get isActive => isGiven && version == kDpdpConsentVersion;
}

class DpdpConsentDialog extends StatefulWidget {
  final int studentId;
  final String studentName;

  /// Label of the secondary button, which closes the dialog with `false`.
  final String dismissLabel;

  /// e.g. "Child 1 of 2" when several children need consent.
  final String? progressLabel;

  const DpdpConsentDialog({
    super.key,
    required this.studentId,
    required this.studentName,
    this.dismissLabel = 'Cancel',
    this.progressLabel,
  });

  /// Resolves true only when the server recorded the consent.
  static Future<bool?> show(
    BuildContext context, {
    required int studentId,
    required String studentName,
    String dismissLabel = 'Cancel',
    String? progressLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DpdpConsentDialog(
        studentId: studentId,
        studentName: studentName,
        dismissLabel: dismissLabel,
        progressLabel: progressLabel,
      ),
    );
  }

  /// The parent's children (get_students is parent-scoped) joined with their
  /// latest consent. Returns null when either request fails.
  static Future<List<ChildConsent>?> loadChildConsents() async {
    final api = ApiService();
    final results = await Future.wait([
      api.get('get_students'),
      api.get('get_parental_consents'),
    ]);
    final students = results[0];
    final consents = results[1];
    if (students is! List || consents is! List) return null;

    final byStudent = <int, Map>{};
    for (final c in consents) {
      if (c is! Map) continue;
      final id = int.tryParse('${c['student_id']}');
      if (id != null) byStudent[id] = c;
    }

    DateTime? date(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

    final children = <ChildConsent>[];
    for (final st in students) {
      if (st is! Map) continue;
      final id = int.tryParse('${st['id']}');
      if (id == null) continue;
      final name =
          (st['name'] ?? '${st['first_name'] ?? ''} ${st['last_name'] ?? ''}')
              .toString()
              .trim();
      final c = byStudent[id];
      children.add(ChildConsent(
        studentId: id,
        studentName: name.isEmpty ? 'your child' : name,
        version: c?['consent_version']?.toString(),
        agreedAt: date(c?['agreed_at']),
        withdrawnAt: date(c?['withdrawn_at']),
      ));
    }
    return children;
  }

  /// Asks for consent, one child at a time, for every child without an
  /// active consent on the server. Returns false when the parent chose to
  /// log out instead; true otherwise (including when the check itself could
  /// not be loaded — it runs again at the next sign-in).
  static Future<bool> showIfNeeded(BuildContext context) {
    // The parent shell can start more than once while signing in; share one
    // run so the same child is never asked twice.
    return _pendingCheck ??=
        _askPending(context).whenComplete(() => _pendingCheck = null);
  }

  static Future<bool>? _pendingCheck;

  /// Bumped whenever consent is recorded, so screens showing consent status
  /// (e.g. the parent profile) can reload.
  static final ValueNotifier<int> changed = ValueNotifier(0);

  static Future<bool> _askPending(BuildContext context) async {
    final children = await loadChildConsents();
    if (children == null) return true;
    final pending = children.where((c) => !c.isActive).toList();
    for (var i = 0; i < pending.length; i++) {
      if (!context.mounted) return true;
      final child = pending[i];
      // Re-check just before asking, in case consent was given meanwhile
      // (e.g. on another device).
      final latest = await loadChildConsents();
      if (!context.mounted) return true;
      if (latest != null &&
          latest.any((c) => c.studentId == child.studentId && c.isActive)) {
        continue;
      }
      final res = await show(
        context,
        studentId: child.studentId,
        studentName: child.studentName,
        dismissLabel: 'Log out',
        progressLabel:
            pending.length > 1 ? 'Child ${i + 1} of ${pending.length}' : null,
      );
      if (res != true) return false;
    }
    return true;
  }

  @override
  State<DpdpConsentDialog> createState() => _DpdpConsentDialogState();
}

class _DpdpConsentDialogState extends State<DpdpConsentDialog> {
  bool _agreedToClinicalProcessing = false;
  bool _agreedToRecordRetention = false;
  bool _agreedToEmergencyDisclosures = false;
  bool _isSubmitting = false;
  String? _error;

  bool get _canSubmit =>
      _agreedToClinicalProcessing &&
      _agreedToRecordRetention &&
      _agreedToEmergencyDisclosures;

  Future<void> _submitConsent() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final res = await ApiService().post('record_parental_consent', {
      'student_id': widget.studentId,
      'consent_version': kDpdpConsentVersion,
    });
    if (!mounted) return;

    if (res is Map && res['success'] == true) {
      DpdpConsentDialog.changed.value++;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Consent recorded for ${widget.studentName}.'),
          backgroundColor: AppColors.statusActive,
        ),
      );
      return;
    }
    setState(() {
      _isSubmitting = false;
      _error = (res is Map && res['error'] != null)
          ? res['error'].toString()
          : 'Could not record your consent. Check your connection and try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        // Near full-width on phones.
        insetPadding: Breakpoints.isCompact(context)
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          width: 520,
          padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 18 : 28),
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
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.gavel_rounded,
                          color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Digital Data Consent',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary),
                          ),
                          Text(
                            'India Digital Personal Data Protection (DPDP) Act 2023',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'For: ${widget.studentName}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ),
                    if (widget.progressLabel != null)
                      Text(
                        widget.progressLabel!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Ray of Hope Center for Autism securely processes health, behavioral, and developmental milestone records for your child, ${widget.studentName}.',
                  style: const TextStyle(
                      fontSize: 13, height: 1.5, color: Color(0xFF334155)),
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
                        onChanged: (v) => setState(
                            () => _agreedToClinicalProcessing = v ?? false),
                        title: const Text('Clinical & Therapy Data Processing',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        subtitle: const Text(
                            'I authorize certified therapists and BCBA supervisors to document behavioral trials and IEP progress.',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary)),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        value: _agreedToRecordRetention,
                        onChanged: (v) => setState(
                            () => _agreedToRecordRetention = v ?? false),
                        title: const Text('Retention & Portability Rights',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        subtitle: const Text(
                            'Records are maintained for clinical continuity. You retain the right to request a full data dossier export.',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary)),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        value: _agreedToEmergencyDisclosures,
                        onChanged: (v) => setState(
                            () => _agreedToEmergencyDisclosures = v ?? false),
                        title: const Text('Emergency Clinical Protocols',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        subtitle: const Text(
                            'Allergies and emergency contacts may be accessed immediately during on-site clinical urgencies.',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary)),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          AppColors.statusDeactivated.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.statusDeactivated
                              .withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 18, color: AppColors.statusDeactivated),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.statusDeactivated),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        !_canSubmit || _isSubmitting ? null : _submitConsent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _error == null
                                ? 'Record Digital Consent & Continue'
                                : 'Try Again',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary),
                    child: Text(widget.dismissLabel),
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
