// lib/features/director/dashboard/widgets/schedule_therapist_session_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';

class ScheduleTherapistSessionDialog extends StatefulWidget {
  final DateTime? initialDate;
  final String? preselectedTherapistId;

  const ScheduleTherapistSessionDialog({
    super.key,
    this.initialDate,
    this.preselectedTherapistId,
  });

  @override
  State<ScheduleTherapistSessionDialog> createState() =>
      _ScheduleTherapistSessionDialogState();
}

class _ScheduleTherapistSessionDialogState
    extends State<ScheduleTherapistSessionDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late String _selectedTherapistId;
  late String _selectedStudentId;
  late String _selectedRoom;
  late String _selectedSlot;

  final _programController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();

    // Default therapist
    _selectedTherapistId = widget.preselectedTherapistId ??
        ScheduleService.centerTherapists.first['id']!;

    // Default student
    _selectedStudentId = ScheduleService.centerStudents.first['id'] as String;
    _programController.text =
        ScheduleService.centerStudents.first['programs'] as String;

    // Default room & slot
    _selectedRoom = ScheduleService.centerRooms.first;
    _selectedSlot = ScheduleService.standardTherapySlots.first;
  }

  @override
  void dispose() {
    _programController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onStudentChanged(String? studentId) {
    if (studentId == null) return;
    setState(() {
      _selectedStudentId = studentId;
      final student = ScheduleService.centerStudents.firstWhere(
        (s) => s['id'] == studentId,
        orElse: () => ScheduleService.centerStudents.first,
      );
      _programController.text = student['programs'] as String;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveSession() {
    if (!_formKey.currentState!.validate()) return;

    final parts = _selectedSlot.split(' - ');
    final startTime = parts[0].trim();
    final endTime = parts[1].trim();

    final therapist = ScheduleService.centerTherapists.firstWhere(
      (t) => t['id'] == _selectedTherapistId,
      orElse: () => ScheduleService.centerTherapists.first,
    );

    final student = ScheduleService.centerStudents.firstWhere(
      (s) => s['id'] == _selectedStudentId,
      orElse: () => ScheduleService.centerStudents.first,
    );

    final scheduleService = context.read<ScheduleService>();
    final newSession = TherapySession(
      id: 'TS-${DateTime.now().millisecondsSinceEpoch % 100000}',
      therapistId: _selectedTherapistId,
      therapistName: therapist['name']!,
      studentId: _selectedStudentId,
      studentName: student['name'] as String,
      studentAge: student['age'] as int,
      programTitle: _programController.text.trim(),
      room: _selectedRoom,
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      startTime: startTime,
      endTime: endTime,
      status: SessionStatus.upcoming,
      notes: _notesController.text.trim(),
    );

    final success = scheduleService.scheduleTherapySession(newSession);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Session scheduled: ${therapist['name']} with ${student['name']} at $startTime in $_selectedRoom.',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Schedule Conflict: ${therapist['name']} is already assigned to a session at $startTime.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 640,
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header with Gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                gradient: AppColors.welcomeGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medical_services, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Therapy Session for Clinician',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Director Clinical Caseload & Time Allocation',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clinician & Student (Responsive Layout)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 500;

                          final clinicianSelector = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assign Therapist',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedTherapistId,
                                decoration: _inputDecoration(prefixIcon: Icons.badge_outlined),
                                items: ScheduleService.centerTherapists.map((t) {
                                  return DropdownMenuItem(
                                    value: t['id'],
                                    child: Text(
                                      t['name']!,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (id) {
                                  if (id != null) setState(() => _selectedTherapistId = id);
                                },
                              ),
                            ],
                          );

                          final studentSelector = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Student',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedStudentId,
                                decoration: _inputDecoration(prefixIcon: Icons.child_care),
                                items: ScheduleService.centerStudents.map((s) {
                                  return DropdownMenuItem(
                                    value: s['id'] as String,
                                    child: Text(
                                      '${s['name']} (${s['age']}y)',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: _onStudentChanged,
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                clinicianSelector,
                                const SizedBox(height: 14),
                                studentSelector,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: clinicianSelector),
                              const SizedBox(width: 14),
                              Expanded(child: studentSelector),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Program Focus Field
                      const Text(
                        'Target Therapy Program & Objectives',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _programController,
                        decoration: _inputDecoration(
                          hintText: 'e.g. VB-MAPP Manding & Tact Probes',
                          prefixIcon: Icons.psychology_outlined,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Program title is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Date & Time Slot (Responsive Layout)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 500;

                          final datePickerWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Session Date',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.divider),
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFFFAFAFA),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('dd MMM yyyy (EEE)').format(_selectedDate),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );

                          final timeSlotWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Session Time Slot',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedSlot,
                                decoration: _inputDecoration(prefixIcon: Icons.access_time),
                                items: ScheduleService.standardTherapySlots.map((slot) {
                                  return DropdownMenuItem(
                                    value: slot,
                                    child: Text(slot, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (slot) {
                                  if (slot != null) setState(() => _selectedSlot = slot);
                                },
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                datePickerWidget,
                                const SizedBox(height: 14),
                                timeSlotWidget,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: datePickerWidget),
                              const SizedBox(width: 14),
                              Expanded(child: timeSlotWidget),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Room / Station Dropdown
                      const Text(
                        'Assigned Center Room / Therapy Station',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedRoom,
                        decoration: _inputDecoration(prefixIcon: Icons.meeting_room_outlined),
                        items: ScheduleService.centerRooms.map((room) {
                          return DropdownMenuItem(
                            value: room,
                            child: Text(room, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (room) {
                          if (room != null) setState(() => _selectedRoom = room);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Clinical Protocol Notes
                      const Text(
                        'Director Clinical Guidance & Instructions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          hintText: 'Specific protocol directives: e.g. run cold probes first, ensure VR reinforcement schedule, take ABC data on transitions...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Buttons (Responsive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: LayoutBuilder(
                builder: (context, footerConstraints) {
                  final isNarrow = footerConstraints.maxWidth < 450;

                  final cancelBtn = OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  );

                  final submitBtn = ElevatedButton.icon(
                    onPressed: _saveSession,
                    icon: const Icon(Icons.check, size: 18, color: Colors.white),
                    label: const Text(
                      'Assign & Schedule Session',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        submitBtn,
                        const SizedBox(height: 10),
                        cancelBtn,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      cancelBtn,
                      const Spacer(),
                      submitBtn,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primary, size: 18) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
