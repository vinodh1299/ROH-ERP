import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import 'package:roh_erp/core/widgets/edit_record_dialogs.dart';
import 'package:roh_erp/features/auth/auth_service.dart';
import 'package:roh_erp/features/auth/widgets/forced_password_change_dialog.dart';
import 'package:roh_erp/features/parent/consent/dpdp_consent_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _prefEmailNotifs = 'pref_notify_email_digest';
  static const _prefSessionAlerts = 'pref_notify_session_completion';
  static const _prefIepUpdates = 'pref_notify_iep_updates';

  bool _emailNotifs = true;
  bool _sessionAlerts = true;
  bool _iepUpdates = true;

  /// Children with their latest consent; null while loading or on error.
  List<ChildConsent>? _consents;
  bool _consentLoading = true;
  bool _consentLoadFailed = false;
  final Set<int> _consentBusy = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadConsents();
    DpdpConsentDialog.changed.addListener(_loadConsents);
  }

  @override
  void dispose() {
    DpdpConsentDialog.changed.removeListener(_loadConsents);
    super.dispose();
  }

  Future<void> _loadConsents() async {
    setState(() {
      _consentLoading = true;
      _consentLoadFailed = false;
    });
    final list = await DpdpConsentDialog.loadChildConsents();
    if (!mounted) return;
    setState(() {
      _consents = list;
      _consentLoadFailed = list == null;
      _consentLoading = false;
    });
  }

  Future<void> _giveConsent(ChildConsent child) async {
    final ok = await DpdpConsentDialog.show(context,
        studentId: child.studentId, studentName: child.studentName);
    if (ok == true) await _loadConsents();
  }

  Future<void> _withdrawConsent(ChildConsent child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text('Withdraw consent for ${child.studentName}?'),
        content: const SizedBox(
          width: 420,
          child: Text(
            'You are withdrawing your consent for the centre to process your '
            "child's therapy, behaviour and progress records.\n\n"
            '• The centre will be notified and may contact you about how '
            'this affects ongoing therapy.\n'
            '• Records already created are not deleted by this step. You can '
            'ask the centre for a copy or for erasure.\n'
            '• You can give consent again at any time from this page.',
            style: TextStyle(
                fontSize: 13, height: 1.5, color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep consent'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDeactivated,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Withdraw consent'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _consentBusy.add(child.studentId));
    final res = await ApiService()
        .post('withdraw_parental_consent', {'student_id': child.studentId});
    if (!mounted) return;
    setState(() => _consentBusy.remove(child.studentId));
    if (showApiResult(
        context, res, 'Consent withdrawn. The centre has been notified.')) {
      await _loadConsents();
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _emailNotifs = prefs.getBool(_prefEmailNotifs) ?? true;
        _sessionAlerts = prefs.getBool(_prefSessionAlerts) ?? true;
        _iepUpdates = prefs.getBool(_prefIepUpdates) ?? true;
      });
    } catch (_) {}
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final parentName = user?.name.isNotEmpty == true ? user!.name : 'User';
    final parentEmail =
        user?.email.isNotEmpty == true ? user!.email : 'Not provided';

    final isPhone = Breakpoints.isCompact(context);
    final cardPadding = EdgeInsets.all(isPhone ? 16 : 24);
    return SingleChildScrollView(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Title ──
          const Text(
            'Parent Profile & Account Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage guardian contacts, emergency notifications, and view enrolled child information.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // ── Parent Guardian Card ──
          Container(
            padding: cardPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: isPhone ? 28 : 36,
                  backgroundColor:
                      AppColors.primaryLight.withValues(alpha: 0.15),
                  child: Icon(Icons.person,
                      size: isPhone ? 30 : 40, color: AppColors.primary),
                ),
                SizedBox(width: isPhone ? 14 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + "Primary Guardian" chip; the chip wraps under
                      // the name when there isn't room beside it.
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            parentName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Primary Guardian',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: $parentEmail',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Contact your center administrator to update profile details.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            ForcedPasswordChangeDialog.show(context),
                        icon: const Icon(Icons.lock_outline,
                            size: 16, color: AppColors.primary),
                        label: const Text('Change Password',
                            style: TextStyle(color: AppColors.primary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Enrolled Child Overview Card ──
          Container(
            padding: cardPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
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
                const Row(
                  children: [
                    Icon(Icons.child_care, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enrolled Child Information',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.divider),
                if (ScheduleService.centerStudents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.child_care_outlined,
                              size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text(
                            'No Enrolled Child Linked Yet',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Once your child is enrolled by the Center Director, their clinical profile, assigned BCBA, and health protocols will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  _buildInfoRow('Child Name',
                      ScheduleService.centerStudents.first['name'] as String),
                  _buildInfoRow('Age',
                      '${ScheduleService.centerStudents.first['age']} years'),
                  _buildInfoRow(
                      'Active Program',
                      (ScheduleService.centerStudents.first['programs']
                              as String?) ??
                          'Comprehensive Behavioral Program'),
                  _buildInfoRow(
                      'Assigned Clinical BCBA',
                      ScheduleService.centerTherapists.isNotEmpty
                          ? ScheduleService.centerTherapists.first['name']!
                          : 'Pending Assignment'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Data Consent (DPDP Act 2023) ──
          _buildConsentCard(cardPadding),
          const SizedBox(height: 24),

          // ── Communication & Notification Preferences ──
          Container(
            padding: cardPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
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
                const Row(
                  children: [
                    Icon(Icons.notifications_active_outlined,
                        color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Center Alerts & Notification Preferences',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Session Completion Alerts',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text(
                      'Receive notifications when therapist concludes daily session.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  value: _sessionAlerts,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _sessionAlerts = val);
                    _savePreference(_prefSessionAlerts, val);
                  },
                ),
                const Divider(height: 16, color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('IEP Approval & Clinical Milestone Updates',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text(
                      'Instant notification when Clinical Director authorizes quarterly IEP.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  value: _iepUpdates,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _iepUpdates = val);
                    _savePreference(_prefIepUpdates, val);
                  },
                ),
                const Divider(height: 16, color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Email Digest & Progress Reports',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text(
                      'Weekly summary of skills mastered sent to parent email.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  value: _emailNotifs,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _emailNotifs = val);
                    _savePreference(_prefEmailNotifs, val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentCard(EdgeInsets cardPadding) {
    final consents = _consents;
    Widget body;
    if (_consentLoading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    } else if (_consentLoadFailed || consents == null) {
      body = Row(
        children: [
          const Expanded(
            child: Text('Could not load consent status.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          TextButton(onPressed: _loadConsents, child: const Text('Retry')),
        ],
      );
    } else if (consents.isEmpty) {
      body = const Text('No enrolled child is linked to your account yet.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary));
    } else {
      body = Column(
        children: [
          for (var i = 0; i < consents.length; i++) ...[
            if (i > 0) const Divider(height: 20, color: AppColors.divider),
            _buildConsentRow(consents[i]),
          ],
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
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
          const Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data consent',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Your consent for the centre to process each child's records "
            '(India DPDP Act 2023).',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(height: 24, color: AppColors.divider),
          body,
        ],
      ),
    );
  }

  Widget _buildConsentRow(ChildConsent child) {
    final fmt = DateFormat('d MMM yyyy');
    final String status;
    final Color color;
    if (child.isGiven) {
      final outdated = child.version != kDpdpConsentVersion;
      status = 'Given on ${fmt.format(child.agreedAt!)} · '
          '${child.version ?? 'unknown version'}'
          '${outdated ? ' (please review the updated terms)' : ''}';
      color = outdated ? AppColors.statusPending : AppColors.statusActive;
    } else if (child.isWithdrawn) {
      status = 'Withdrawn on ${fmt.format(child.withdrawnAt!)}';
      color = AppColors.statusDeactivated;
    } else {
      status = 'Not given';
      color = AppColors.statusPending;
    }

    final busy = _consentBusy.contains(child.studentId);
    final Widget action;
    if (busy) {
      action = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2));
    } else if (child.isActive) {
      action = OutlinedButton(
        onPressed: () => _withdrawConsent(child),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.statusDeactivated,
          side: const BorderSide(color: AppColors.statusDeactivated),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Withdraw consent'),
      );
    } else {
      action = ElevatedButton(
        onPressed: () => _giveConsent(child),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Give consent'),
      );
    }

    // Action wraps below the status on narrow screens.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 10,
      spacing: 12,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(child.studentName,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(status,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: color)),
                  ),
                ],
              ),
            ],
          ),
        ),
        action,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            // Narrower label column on phones.
            width: Breakpoints.isCompact(context) ? 130 : 200,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
