// lib/features/parent/dashboard/widgets/parent_request_appointment_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';

class ParentRequestAppointmentDialog extends StatefulWidget {
  final String childName;
  final String parentName;

  const ParentRequestAppointmentDialog({
    super.key,
    this.childName = 'Alex Thomas Sam',
    this.parentName = 'Mr. John Wilson',
  });

  @override
  State<ParentRequestAppointmentDialog> createState() =>
      _ParentRequestAppointmentDialogState();
}

class _ParentRequestAppointmentDialogState
    extends State<ParentRequestAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  AppointmentType _selectedType = AppointmentType.parentConference;
  String? _selectedSlot;

  final _titleController = TextEditingController();
  final _phoneController = TextEditingController(text: '+1 (555) 382-9912');
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _titleController.text = 'Parent Conference & Progress Review';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(AppointmentType? type) {
    if (type == null) return;
    setState(() {
      _selectedType = type;
      if (type == AppointmentType.iepReview) {
        _titleController.text = 'IEP 6-Month Review for ${widget.childName}';
      } else if (type == AppointmentType.diagnosticIntake) {
        _titleController.text = 'Clinical Re-Evaluation Consultation';
      } else {
        _titleController.text = 'Parent Conference & Progress Review';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
    }
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an open time slot with the Director.'),
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
      id: 'DA-PAR-${DateTime.now().millisecondsSinceEpoch % 100000}',
      title: _titleController.text.trim(),
      type: _selectedType,
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      startTime: startTime,
      endTime: endTime,
      attendeeName: widget.parentName,
      attendeeRole: 'Parent of ${widget.childName}',
      attendeePhone: _phoneController.text.trim(),
      attendeeEmail: 'parent.wilson@example.com',
      location: 'Director Suite 201 / Zoom Video',
      scheduledBy: 'Parent Self-Service',
      status: AppointmentStatus.confirmed,
      notes: _notesController.text.trim().isEmpty
          ? 'Parent requested review of current VB-MAPP targets and home carryover.'
          : _notesController.text.trim(),
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
                  'Appointment confirmed with Clinical Director for ${DateFormat('dd MMM').format(_selectedDate)} at $startTime.',
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
          content: Text('Time conflict: Director already has an appointment in that slot.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  InputDecoration _inputDecoration({String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.primary, size: 20)
          : null,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            // Header
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
                    child: const Icon(Icons.event_available, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Director Consultation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Dr. Vincent Sterling, BCBA-D • Clinical Director',
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

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Child & Parent Info summary chip
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.child_care, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Requesting conference for student: ${widget.childName} (Parent: ${widget.parentName})',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Meeting Purpose / Category
                      const Text(
                        'Meeting Objective / Purpose',
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
                        items: const [
                          DropdownMenuItem(
                            value: AppointmentType.parentConference,
                            child: Text('Parent Conference & Goal Alignment', style: TextStyle(fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: AppointmentType.iepReview,
                            child: Text('IEP 6-Month Review / Evaluation', style: TextStyle(fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: AppointmentType.diagnosticIntake,
                            child: Text('Comprehensive Diagnostic Audit', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                        onChanged: _onTypeChanged,
                      ),
                      const SizedBox(height: 16),

                      // Title
                      const Text(
                        'Meeting Subject / Title',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration(prefixIcon: Icons.title),
                        validator: (v) => v == null || v.isEmpty ? 'Subject is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Date & Slot Selection
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 500;

                          final datePicker = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Preferred Date',
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

                          final slotPicker = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Director Open Slots',
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
                                      hint: const Text('Choose open slot', style: TextStyle(fontSize: 13)),
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
                                datePicker,
                                const SizedBox(height: 14),
                                slotPicker,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: datePicker),
                              const SizedBox(width: 14),
                              Expanded(child: slotPicker),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Contact Phone
                      const Text(
                        'Callback / Notification Phone',
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
                        validator: (v) => v == null || v.isEmpty ? 'Phone number required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Parent Questions & Notes
                      const Text(
                        'Specific Questions or Areas of Focus for the Director',
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
                          hintText: 'e.g. Would like to discuss recent mealtime transitions at home and review updated VB-MAPP milestone progress...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Buttons
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
                    onPressed: _submitRequest,
                    icon: const Icon(Icons.check, size: 18, color: Colors.white),
                    label: const Text(
                      'Confirm Appointment with Director',
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
}
