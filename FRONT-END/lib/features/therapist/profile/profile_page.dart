import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/widgets/edit_record_dialogs.dart';
import 'package:roh_erp/features/auth/auth_service.dart';
import 'package:roh_erp/features/auth/widgets/forced_password_change_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  static const _prefEmailNotifications = 'pref_notify_email_iep_requests';
  static const _prefSessionAlerts = 'pref_notify_daily_session_reminders';

  bool _emailNotifications = true;
  bool _sessionAlerts = true;

  // Profile as last loaded from / saved to the server (Reset restores it).
  Map<String, dynamic> _profile = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      _profile = {'name': user.name, 'email': user.email};
      _fillFields();
    }
    _loadProfile();
    _loadPreferences();
  }

  String _str(String key) => (_profile[key] ?? '').toString().trim();

  void _fillFields() {
    _nameController.text = _str('name');
    _emailController.text = _str('email');
    _designationController.text = _str('designation');
    _phoneController.text = _str('phone');
    _specializationController.text = _str('specialties');
    _qualificationController.text = _str('qualification');
    _aboutController.text = _str('about');
  }

  Future<void> _loadProfile() async {
    final res = await ApiService().get('get_my_profile');
    if (!mounted) return;
    setState(() {
      if (res is Map && res['error'] == null) {
        _profile = Map<String, dynamic>.from(res);
        _fillFields();
      }
      _loading = false;
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _emailNotifications = prefs.getBool(_prefEmailNotifications) ?? true;
        _sessionAlerts = prefs.getBool(_prefSessionAlerts) ?? true;
      });
    } catch (_) {}
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Full name is required.'),
        backgroundColor: AppColors.statusDeactivated,
      ));
      return;
    }
    setState(() => _saving = true);
    final body = {
      'name': name,
      'phone': _phoneController.text.trim(),
      'qualification': _qualificationController.text.trim(),
      'specialties': _specializationController.text.trim(),
      'about': _aboutController.text.trim(),
    };
    final res = await ApiService().post('update_my_profile', body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (showApiResult(context, res, 'Profile updated successfully.')) {
      setState(() => _profile = {..._profile, ...body});
      context.read<AuthService>().updateDisplayName(body['name'] as String);
    }
  }

  /// "Joined: Sept 2021" from date_of_joining (or the account's creation).
  String? get _joinedLabel {
    final raw = _str('date_of_joining').isNotEmpty
        ? _str('date_of_joining')
        : _str('created_at');
    final date = DateTime.tryParse(raw);
    return date == null ? null : DateFormat('MMM yyyy').format(date.toLocal());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _qualificationController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          const Text(
            'Therapist Profile & Settings',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Profile Banner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AppImages.therapistAvatar(
                    radius: 45,
                  ),
                ),
                const SizedBox(width: 24),

                // Name & Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            _str('name').isNotEmpty
                                ? _str('name')
                                : 'Clinical Staff',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Active Staff',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _str('designation').isNotEmpty
                            ? '${_str('designation')} | Ray of Hope Center for Autism'
                            : 'Ray of Hope Center for Autism',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 24,
                        runSpacing: 6,
                        children: [
                          if (_str('employee_id').isNotEmpty)
                            _bannerInfo(Icons.badge_outlined,
                                'Employee ID: ${_str('employee_id')}'),
                          if (_str('license_number').isNotEmpty)
                            _bannerInfo(Icons.verified_outlined,
                                'License: ${_str('license_number')}'),
                          if (_joinedLabel != null)
                            _bannerInfo(Icons.calendar_today_outlined,
                                'Joined: $_joinedLabel'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Details Form Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6EFF5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal & Professional Information',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Row 1: Full Name & Designation
                Row(
                  children: [
                    Expanded(
                        child: _buildFormField('Full Name', _nameController,
                            Icons.person_outline)),
                    const SizedBox(width: 20),
                    Expanded(
                        child: _buildFormField('Designation',
                            _designationController, Icons.work_outline,
                            readOnly: true)),
                  ],
                ),
                const SizedBox(height: 18),

                // Row 2: Email & Phone
                Row(
                  children: [
                    Expanded(
                        child: _buildFormField('Email Address',
                            _emailController, Icons.email_outlined,
                            readOnly: true)),
                    const SizedBox(width: 20),
                    Expanded(
                        child: _buildFormField('Phone Number', _phoneController,
                            Icons.phone_outlined)),
                  ],
                ),
                const SizedBox(height: 18),

                // Row 3: Specialization & Qualification
                Row(
                  children: [
                    Expanded(
                        child: _buildFormField('Specialization',
                            _specializationController, Icons.school)),
                    const SizedBox(width: 20),
                    Expanded(
                        child: _buildFormField(
                            'Qualification',
                            _qualificationController,
                            Icons.workspace_premium_outlined)),
                  ],
                ),
                const SizedBox(height: 18),

                // Row 4: Bio / About
                const Text(
                  'Professional Biography',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: TextField(
                    controller: _aboutController,
                    maxLines: 3,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Workstation Preferences
                const Divider(color: Color(0xFFE6EFF5)),
                const SizedBox(height: 20),
                const Text(
                  'Workstation & Notification Preferences',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          title: const Text(
                              'Email Notifications for New IEP Requests',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          subtitle: const Text(
                              'Receive email alerts when parents or admin submit new IEP requests',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          value: _emailNotifications,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() => _emailNotifications = val);
                            _savePreference(_prefEmailNotifications, val);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          title: const Text('Daily Session Reminders',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          subtitle: const Text(
                              'Show pending daily data sheet reminders every morning',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          value: _sessionAlerts,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() => _sessionAlerts = val);
                            _savePreference(_prefSessionAlerts, val);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Save Changes Button
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ForcedPasswordChangeDialog.show(context),
                      icon: const Icon(Icons.lock_outline,
                          size: 18, color: AppColors.primary),
                      label: const Text('Change Password',
                          style: TextStyle(
                              color: AppColors.primary, fontFamily: 'Poppins')),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _loading || _saving
                          ? null
                          : () => setState(_fillFields),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reset',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontFamily: 'Poppins')),
                    ),
                    ElevatedButton(
                      onPressed: _loading || _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 36, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        _saving ? 'Saving…' : 'Save Changes',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _bannerInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFormField(
      String label, TextEditingController controller, IconData icon,
      {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color:
                    readOnly ? AppColors.textSecondary : AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
