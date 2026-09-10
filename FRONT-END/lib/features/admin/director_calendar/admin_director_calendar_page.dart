// lib/features/admin/director_calendar/admin_director_calendar_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import '../dashboard/widgets/schedule_director_appointment_dialog.dart';

class AdminDirectorCalendarPage extends StatefulWidget {
  const AdminDirectorCalendarPage({super.key});

  @override
  State<AdminDirectorCalendarPage> createState() =>
      _AdminDirectorCalendarPageState();
}

class _AdminDirectorCalendarPageState extends State<AdminDirectorCalendarPage> {
  DateTime _selectedDate = DateTime.now();

  void _openBookingDialog([String? prefilledSlot]) {
    showDialog(
      context: context,
      builder: (ctx) => ScheduleDirectorAppointmentDialog(
        initialDate: _selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final dayAppointments = scheduleService.getDirectorAppointments(date: _selectedDate);
    final availableSlots = scheduleService.getAvailableDirectorSlots(_selectedDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header Banner (Responsive)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.welcomeGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: LayoutBuilder(
              builder: (context, bannerConstraints) {
                final isNarrow = bannerConstraints.maxWidth < 650;
                final textColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Executive Appointment Coordinator',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Director's Calendar & Scheduling Portal",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Check Director availability, inspect booked clinical evaluations, and schedule parent diagnostic intakes, IEP audits, and conferences.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                );

                final actionBtn = ElevatedButton.icon(
                  onPressed: () => _openBookingDialog(),
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text(
                    '+ Schedule Appointment for Director',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textColumn,
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity, child: actionBtn),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: textColumn),
                    const SizedBox(width: 16),
                    actionBtn,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Date Navigator & Availability Strip (Responsive)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: LayoutBuilder(
              builder: (context, stripConstraints) {
                final isNarrow = stripConstraints.maxWidth < 750;

                final datePickers = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildQuickDateBtn('Today', DateTime.now()),
                    _buildQuickDateBtn('Tomorrow', DateTime.now().add(const Duration(days: 1))),
                    _buildQuickDateBtn('In 2 Days', DateTime.now().add(const Duration(days: 2))),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      icon: const Icon(Icons.calendar_month, size: 16, color: AppColors.primary),
                      label: Text(
                        DateFormat('dd MMM yyyy (EEE)').format(_selectedDate),
                        style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                );

                final statusBadges = Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 6),
                          Text(
                            '${availableSlots.length} Slots Available',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_seat, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${dayAppointments.length} Booked',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      datePickers,
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 12),
                      statusBadges,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: datePickers),
                    const SizedBox(width: 12),
                    statusBadges,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Two Columns Layout: Left = Available Slots Picker, Right = Booked Appointments Agenda
          LayoutBuilder(
            builder: (context, gridConstraints) {
              final isMobile = gridConstraints.maxWidth < 900;

              final slotsCard = Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        const Text(
                          'Open Booking Slots',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd MMM').format(_selectedDate),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Click any open slot below to immediately schedule an appointment for the Director.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 16),

                    if (availableSlots.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: const Text(
                          'Director has no open slots remaining on this date.',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: availableSlots.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final slot = availableSlots[i];
                          return InkWell(
                            onTap: () => _openBookingDialog(slot),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8E9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFA5D6A7)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.add_circle, size: 16, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 10),
                                  Text(
                                    slot,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Book Slot',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );

              // Right: Booked Appointments for Selected Date
              final agendaCard = Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_note, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          "Director's Day Agenda (${dayAppointments.length} scheduled)",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Scheduled for Dr. Vincent Sterling • Clinical Director',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 16),

                    if (dayAppointments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 36, color: AppColors.textHint),
                              const SizedBox(height: 12),
                              const Text(
                                'No appointments booked yet on this date',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Use the slots on the left or "+ Schedule Appointment" to book.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dayAppointments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, i) {
                            final appt = dayAppointments[i];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${appt.startTime} - ${appt.endTime}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          appt.type.label,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0369A1),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'Confirmed',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    appt.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Attendee: ${appt.attendeeName} (${appt.attendeeRole})',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  if (appt.attendeePhone.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          appt.attendeePhone,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                        if (appt.attendeeEmail.isNotEmpty) ...[
                                          const SizedBox(width: 12),
                                          const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            appt.attendeeEmail,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.room_outlined, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        appt.location,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  if (appt.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFEEEEEE)),
                                      ),
                                      child: Text(
                                        'Agenda: ${appt.notes}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );

              if (isMobile) {
                return Column(
                  children: [
                    slotsCard,
                    const SizedBox(height: 20),
                    agendaCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: slotsCard),
                  const SizedBox(width: 24),
                  Expanded(flex: 6, child: agendaCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateBtn(String label, DateTime date) {
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    return ElevatedButton(
      onPressed: () => setState(() => _selectedDate = date),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}
