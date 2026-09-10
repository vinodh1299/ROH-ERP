// lib/features/admin/dashboard/widgets/schedule_director_appointment_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';

class ScheduleDirectorAppointmentDialog extends StatefulWidget {
  final DateTime? initialDate;

  const ScheduleDirectorAppointmentDialog({super.key, this.initialDate});

  @override
  State<ScheduleDirectorAppointmentDialog> createState() =>
      _ScheduleDirectorAppointmentDialogState();
}

class _ScheduleDirectorAppointmentDialogState
    extends State<ScheduleDirectorAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  AppointmentType _selectedType = AppointmentType.diagnosticIntake;
  String? _selectedSlot;

  final _titleController = TextEditingController();
  final _attendeeNameController = TextEditingController();
  final _attendeeRoleController = TextEditingController(text: 'Parent');
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController(text: 'Director Suite 201');
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _titleController.text = _selectedType.label;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _attendeeNameController.dispose();
    _attendeeRoleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(AppointmentType? type) {
    if (type == null) return;
    setState(() {
      _selectedType = type;
      _titleController.text = type.label;
      if (type == AppointmentType.diagnosticIntake ||
          type == AppointmentType.parentConference) {
        _attendeeRoleController.text = 'Parent';
      } else if (type == AppointmentType.bacbSupervision) {
        _attendeeRoleController.text = 'BCBA Trainee / Supervisee';
      } else if (type == AppointmentType.iepReview) {
        _attendeeRoleController.text = 'Lead BCBA Clinician';
      } else {
        _attendeeRoleController.text = 'Staff';
      }
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
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null; // Reset slot when date changes
      });
    }
  }

  void _saveAppointment() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an available time slot for the Director.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final parts = _selectedSlot!.split(' - ');
    final startTime = parts[0].trim();
    final endTime = parts[1].trim();

    final scheduleService = context.read<ScheduleService>();
    final newAppointment = DirectorAppointment(
      id: 'DA-${DateTime.now().millisecondsSinceEpoch % 100000}',
      title: _titleController.text.trim(),
      type: _selectedType,
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      startTime: startTime,
      endTime: endTime,
      attendeeName: _attendeeNameController.text.trim(),
      attendeeRole: _attendeeRoleController.text.trim(),
      attendeePhone: _phoneController.text.trim(),
      attendeeEmail: _emailController.text.trim(),
      location: _locationController.text.trim(),
      scheduledBy: 'Admin',
      status: AppointmentStatus.confirmed,
      notes: _notesController.text.trim(),
    );

    final success = scheduleService.scheduleDirectorAppointment(newAppointment);

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
                  'Appointment scheduled with Director for ${_attendeeNameController.text.trim()} at $startTime.',
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
        const SnackBar(
          content: Text('Time conflict: Director already has an appointment at that time.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final availableSlots = scheduleService.getAvailableDirectorSlots(_selectedDate);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 620,
        constraints: BoxConstraints(
          maxWidth: 620,
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
                    child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Appointment for Director',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Admin Clinical Coordination Portal',
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
                      // Appointment Type Dropdown
                      const Text(
                        'Appointment Type',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<AppointmentType>(
                        value: _selectedType,
                        decoration: _inputDecoration(prefixIcon: Icons.category_outlined),
                        items: AppointmentType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.label, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: _onTypeChanged,
                      ),
                      const SizedBox(height: 16),

                      // Title / Subject Field
                      const Text(
                        'Appointment Title / Meeting Subject',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration(
                          hintText: 'e.g. Diagnostic Intake Evaluation',
                          prefixIcon: Icons.title,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
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
                                'Appointment Date',
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

                          final slotPickerWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Available Slots',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: availableSlots.isNotEmpty
                                          ? const Color(0xFFE8F5E9)
                                          : const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${availableSlots.length} open',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: availableSlots.isNotEmpty
                                            ? const Color(0xFF2E7D32)
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              availableSlots.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: const Text(
                                        'No open slots on this date',
                                        style: TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                    )
                                  : DropdownButtonFormField<String>(
                                      value: _selectedSlot,
                                      hint: const Text('Select time slot', style: TextStyle(fontSize: 13)),
                                      decoration: _inputDecoration(prefixIcon: Icons.access_time),
                                      items: availableSlots.map((slot) {
                                        return DropdownMenuItem(
                                          value: slot,
                                          child: Text(slot, style: const TextStyle(fontSize: 13)),
                                        );
                                      }).toList(),
                                      onChanged: (slot) => setState(() => _selectedSlot = slot),
                                    ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                datePickerWidget,
                                const SizedBox(height: 14),
                                slotPickerWidget,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: datePickerWidget),
                              const SizedBox(width: 14),
                              Expanded(child: slotPickerWidget),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Attendee Info (Responsive Layout)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 500;

                          final attendeeNameWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attendee / Parent Name',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _attendeeNameController,
                                decoration: _inputDecoration(
                                  hintText: 'e.g. Mr. John Wilson',
                                  prefixIcon: Icons.person_outline,
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Attendee name required' : null,
                              ),
                            ],
                          );

                          final attendeeRoleWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attendee Role / Relation',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _attendeeRoleController,
                                decoration: _inputDecoration(
                                  hintText: 'e.g. Parent of Jemi Wilson',
                                  prefixIcon: Icons.badge_outlined,
                                ),
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                attendeeNameWidget,
                                const SizedBox(height: 14),
                                attendeeRoleWidget,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: attendeeNameWidget),
                              const SizedBox(width: 14),
                              Expanded(child: attendeeRoleWidget),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone & Email (Responsive Layout)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 500;

                          final phoneWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact Phone',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _phoneController,
                                decoration: _inputDecoration(
                                  hintText: '+1 (555) 000-0000',
                                  prefixIcon: Icons.phone_outlined,
                                ),
                              ),
                            ],
                          );

                          final emailWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                decoration: _inputDecoration(
                                  hintText: 'parent@email.com',
                                  prefixIcon: Icons.email_outlined,
                                ),
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                phoneWidget,
                                const SizedBox(height: 14),
                                emailWidget,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: phoneWidget),
                              const SizedBox(width: 14),
                              Expanded(child: emailWidget),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Location
                      const Text(
                        'Location / Meeting Room',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _locationController,
                        decoration: _inputDecoration(
                          hintText: 'e.g. Director Suite 201 / Zoom Video Link',
                          prefixIcon: Icons.room_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Clinical Agenda & Notes
                      const Text(
                        'Clinical Agenda & Objectives',
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
                          hintText: 'Notes for Director: student background, assessment priorities, or required reports...',
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
                    onPressed: _saveAppointment,
                    icon: const Icon(Icons.check, size: 18, color: Colors.white),
                    label: const Text(
                      'Schedule Appointment',
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
