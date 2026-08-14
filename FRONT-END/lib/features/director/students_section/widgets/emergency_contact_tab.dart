// lib/features/director/students_section/widgets/emergency_contact_tab.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/db_queries.dart';
import 'add_guardian_dialog.dart';

class EmergencyContactTab extends StatefulWidget {
  final String? studentId;
  const EmergencyContactTab({super.key, required this.studentId});

  @override
  State<EmergencyContactTab> createState() => EmergencyContactTabState();
}

class EmergencyContactTabState extends State<EmergencyContactTab> {
  final List<Map<String, String>> _guardians = [];

  // 3 contact-name + message slots (matches the Figma's 3-column layout)
  final List<TextEditingController> _names = [TextEditingController(), TextEditingController(), TextEditingController()];
  final List<TextEditingController> _messages = [TextEditingController(), TextEditingController(), TextEditingController()];

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    for (final c in _messages) {
      c.dispose();
    }
    super.dispose();
  }

  void _openAddGuardian() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => AddGuardianDialog(
        onSubmit: (data) => setState(() => _guardians.add(data)),
      ),
    );
  }

  /// Called by the parent dialog's Submit button.
  /// Saves all guardians + emergency contact rows now that student_id exists.
  Future<void> saveAll(String studentId) async {
    for (final g in _guardians) {
      await StudentQueries.addGuardian({
        'student_id': studentId,
        ...g,
      });
    }
    for (int i = 0; i < _names.length; i++) {
      final name = _names[i].text.trim();
      final message = _messages[i].text.trim();
      if (name.isEmpty && message.isEmpty) continue;
      await StudentQueries.saveEmergencyContact(
        studentId: studentId,
        contactName: name,
        message: message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Guardian cards ─────────────────────────────────────────────
          Row(
            children: [
              const Text('Guardians', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              TextButton.icon(
                onPressed: _openAddGuardian,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _guardians.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Center(
                    child: Text(
                      'No guardians added yet. Tap "Add" to add Guardian #1, #2, etc.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                )
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(_guardians.length, (i) => _GuardianCard(
                        index: i + 1,
                        data: _guardians[i],
                        onRemove: () => setState(() => _guardians.removeAt(i)),
                      )),
                ),
          const SizedBox(height: 20),

          // ── Emergency contact info ──────────────────────────────────────
          const Text('Emergency Contact Information',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ContactSlot(nameCtrl: _names[0], messageCtrl: _messages[0])),
              const SizedBox(width: 12),
              Expanded(child: _ContactSlot(nameCtrl: _names[1], messageCtrl: _messages[1])),
              const SizedBox(width: 12),
              Expanded(child: _ContactSlot(nameCtrl: _names[2], messageCtrl: _messages[2])),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Guardian card preview (shows after adding via dialog) ─────────────────────
class _GuardianCard extends StatelessWidget {
  final int index;
  final Map<String, String> data;
  final VoidCallback onRemove;
  const _GuardianCard({required this.index, required this.data, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FA)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('GUARDIAN #$index',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const Spacer(),
              InkWell(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 14, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(data['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text(data['relationship'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(data['phone_number'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(data['email'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ── Contact name + message slot ───────────────────────────────────────────────
class _ContactSlot extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController messageCtrl;
  const _ContactSlot({required this.nameCtrl, required this.messageCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        TextFormField(
          controller: nameCtrl,
          decoration: InputDecoration(
            hintText: 'Value',
            hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 10),
        const Text('Message', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        TextFormField(
          controller: messageCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Value',
            hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}
