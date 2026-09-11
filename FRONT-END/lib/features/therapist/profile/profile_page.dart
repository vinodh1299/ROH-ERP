import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController(text: 'Dr. Sarah Lee');
  final TextEditingController _designationController = TextEditingController(text: 'Senior ABA Therapist & BCBA');
  final TextEditingController _emailController = TextEditingController(text: 'sarah.lee@rayofhope.center');
  final TextEditingController _phoneController = TextEditingController(text: '+1 (555) 342-8920');
  final TextEditingController _empIdController = TextEditingController(text: 'ROH-TH-0042');
  final TextEditingController _specializationController = TextEditingController(text: 'VB-MAPP, Early Intervention, PECS');
  final TextEditingController _experienceController = TextEditingController(text: '8+ Years Clinical Practice');
  final TextEditingController _aboutController = TextEditingController(
    text: 'Board Certified Behavior Analyst (BCBA) specializing in verbal behavior assessment, functional communication training, and individualized curriculum design for children on the autism spectrum.',
  );

  bool _emailNotifications = true;
  bool _sessionAlerts = true;

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _empIdController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
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
                // Avatar with Edit Badge
                Stack(
                  children: [
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
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
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
                          const Text(
                            'Dr. Sarah Lee, BCBA',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        'Senior Verbal Behavior Therapist | Ray of Hope Center for Autism',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, size: 16, color: Colors.white70),
                          const SizedBox(width: 6),
                          const Text(
                            'Employee ID: ROH-TH-0042',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 24),
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.white70),
                          const SizedBox(width: 6),
                          const Text(
                            'Joined: Sept 2021',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white),
                          ),
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
                    Expanded(child: _buildFormField('Full Name', _nameController, Icons.person_outline)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildFormField('Designation', _designationController, Icons.work_outline)),
                  ],
                ),
                const SizedBox(height: 18),

                // Row 2: Email & Phone
                Row(
                  children: [
                    Expanded(child: _buildFormField('Email Address', _emailController, Icons.email_outlined)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildFormField('Phone Number', _phoneController, Icons.phone_outlined)),
                  ],
                ),
                const SizedBox(height: 18),

                // Row 3: Specialization & Experience
                Row(
                  children: [
                    Expanded(child: _buildFormField('Specialization', _specializationController, Icons.school)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildFormField('Clinical Experience', _experienceController, Icons.timer_outlined)),
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
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
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
                          title: const Text('Email Notifications for New IEP Requests', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500)),
                          subtitle: const Text('Receive email alerts when parents or admin submit new IEP requests', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          value: _emailNotifications,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _emailNotifications = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          title: const Text('Daily Session Reminders', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500)),
                          subtitle: const Text('Show pending daily data sheet reminders every morning', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          value: _sessionAlerts,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _sessionAlerts = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Save Changes Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reset', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins')),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated successfully!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
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

  Widget _buildFormField(String label, TextEditingController controller, IconData icon) {
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
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
