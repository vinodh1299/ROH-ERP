// lib/features/director/students_section/widgets/add_student_dialog.dart
//
// Multi-step "Add Student" dialog matching the Figma:
//   Tab 1: Students Information
//   Tab 2: Medication History
//   Tab 3: Emergency Contact Info
//
// Each tab is its own file in this folder. This file is just the shell:
// header, tab bar, and Previous/Next/Submit footer logic.

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/db_queries.dart';
import 'student_info_tab.dart';
import 'medication_history_tab.dart';
import 'emergency_contact_tab.dart';

class AddStudentDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const AddStudentDialog({super.key, required this.onSaved});

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  int _currentTab = 0;
  bool _submitting = false;

  // Holds the newly created student's id once tab 1 is saved — tabs 2 & 3
  // need this to attach medications / guardians / emergency contacts.
  String? _studentId;

  // ── Form state shared across tabs ─────────────────────────────────────
  final studentInfoKey = GlobalKey<StudentInfoTabState>();
  final medicationKey = GlobalKey<MedicationHistoryTabState>();
  final emergencyKey = GlobalKey<EmergencyContactTabState>();

  Future<void> _goNext() async {
    if (_currentTab == 0) {
      // Validate + save student info first, since later tabs need student_id
      final formData = studentInfoKey.currentState?.collect();
      if (formData == null) return; // validation failed

      setState(() => _submitting = true);
      final result = await StudentQueries.add(formData);
      setState(() => _submitting = false);

      if (result == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save student info.'), backgroundColor: Colors.red),
        );
        return;
      }
      _studentId = '${result['id']}';
      setState(() => _currentTab = 1);
    } else if (_currentTab == 1) {
      setState(() => _currentTab = 2);
    }
  }

  void _goPrevious() {
    if (_currentTab > 0) setState(() => _currentTab--);
  }

  Future<void> _submitFinal() async {
    setState(() => _submitting = true);
    // Tab 3 (Emergency Contact) saves its own data via its internal state.
    await emergencyKey.currentState?.saveAll(_studentId!);
    setState(() => _submitting = false);
    if (!mounted) return;
    widget.onSaved();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student added successfully!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                child: Row(
                  children: [
                    const Text('Add Student',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // ── Tab bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _TabButton(label: 'Students Information', index: 0, current: _currentTab),
                      _TabButton(label: 'Medication History', index: 1, current: _currentTab),
                      _TabButton(label: 'Emergency Contact Info', index: 2, current: _currentTab),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ── Tab content ─────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: IndexedStack(
                    index: _currentTab,
                    children: [
                      StudentInfoTab(key: studentInfoKey),
                      MedicationHistoryTab(key: medicationKey, studentId: _studentId),
                      EmergencyContactTab(key: emergencyKey, studentId: _studentId),
                    ],
                  ),
                ),
              ),
              // ── Footer buttons ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : (_currentTab == 0
                              ? () => Navigator.of(context).pop()
                              : _goPrevious),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                      child: Text(_currentTab == 0 ? 'Cancel' : 'Previous'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : (_currentTab < 2 ? _goNext : _submitFinal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_currentTab < 2 ? 'Next' : 'Submit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int index;
  final int current;
  const _TabButton({required this.label, required this.index, required this.current});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}
