// lib/features/therapist/timetable/therapist_timetable_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';

class TherapistTimetablePage extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const TherapistTimetablePage({super.key, this.onNavigateTab});

  @override
  State<TherapistTimetablePage> createState() => _TherapistTimetablePageState();
}

class _TherapistTimetablePageState extends State<TherapistTimetablePage> {
  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final sessions = scheduleService.getSessionsForTherapist('T1', date: _selectedDate);

    final filteredSessions = sessions.where((s) {
      if (_statusFilter == 'All') return true;
      if (_statusFilter == 'In Progress') return s.status == SessionStatus.inProgress;
      if (_statusFilter == 'Upcoming') return s.status == SessionStatus.upcoming;
      if (_statusFilter == 'Completed') return s.status == SessionStatus.completed;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.welcomeGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                final textSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Dr. Sarah Lee • Senior BCBA Clinician',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Director Scheduled Schedule',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Therapy Timetable & Daily Schedule',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Review assigned therapy sessions, target IEP programs, room locations, and launch direct data collection.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                );

                final dateBadge = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('EEEE').format(_selectedDate),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textSection,
                      const SizedBox(height: 16),
                      dateBadge,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: textSection),
                    const SizedBox(width: 16),
                    dateBadge,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Date Selector & Filters
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final dateButtons = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDateQuickBtn('Today', DateTime.now()),
                  _buildDateQuickBtn('Tomorrow', DateTime.now().add(const Duration(days: 1))),
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
                    label: const Text('Pick Date', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              );

              final filterChips = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['All', 'In Progress', 'Upcoming', 'Completed'].map((filter) {
                  final isSelected = _statusFilter == filter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _statusFilter = filter);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                  );
                }).toList(),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    dateButtons,
                    const SizedBox(height: 14),
                    filterChips,
                  ],
                );
              }

              return Row(
                children: [
                  dateButtons,
                  const Spacer(),
                  filterChips,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Session Timeline List
          if (filteredSessions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  const Icon(Icons.event_busy, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(
                    'No sessions scheduled for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sessions are assigned and scheduled daily by the Clinical Director.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredSessions.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                final session = filteredSessions[i];
                return _buildSessionTimelineCard(session, scheduleService);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDateQuickBtn(String label, DateTime date) {
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

  Widget _buildSessionTimelineCard(TherapySession session, ScheduleService service) {
    Color statusColor;
    Color statusBg;
    String statusText;

    switch (session.status) {
      case SessionStatus.inProgress:
        statusColor = const Color(0xFF2E7D32);
        statusBg = const Color(0xFFE8F5E9);
        statusText = 'LIVE NOW';
        break;
      case SessionStatus.upcoming:
        statusColor = AppColors.primary;
        statusBg = AppColors.primaryLight;
        statusText = 'UPCOMING';
        break;
      case SessionStatus.completed:
        statusColor = Colors.grey.shade700;
        statusBg = Colors.grey.shade200;
        statusText = 'COMPLETED';
        break;
      case SessionStatus.cancelled:
        statusColor = Colors.red;
        statusBg = const Color(0xFFFFEBEE);
        statusText = 'CANCELLED';
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 750;

        final timeBox = Container(
          width: isNarrow ? double.infinity : 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.scaffold,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    session.startTime,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'to ${session.endTime}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        final detailsSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    session.studentName.isNotEmpty ? session.studentName[0] : 'S',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Age: ${session.studentAge} years • ID: ${session.studentId}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.meeting_room, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        session.room,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Program Objectives Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TARGET CLINICAL PROGRAM (SCHEDULED BY DIRECTOR)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.programTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (session.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            session.notes,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening Daily Data Sheet for ${session.studentName}...'),
                    backgroundColor: AppColors.primary,
                  ),
                );
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(8);
                }
              },
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 16, color: Colors.white),
              label: const Text(
                'Daily Data Sheet',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (session.status == SessionStatus.upcoming)
              OutlinedButton.icon(
                onPressed: () {
                  service.updateSessionStatus(session.id, SessionStatus.inProgress);
                },
                icon: const Icon(Icons.play_arrow, size: 14, color: Color(0xFF2E7D32)),
                label: const Text('Start Session', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            else if (session.status == SessionStatus.inProgress)
              ElevatedButton.icon(
                onPressed: () {
                  service.updateSessionStatus(session.id, SessionStatus.completed);
                },
                icon: const Icon(Icons.check, size: 14, color: Colors.white),
                label: const Text('Mark Completed', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: session.status == SessionStatus.inProgress
                  ? const Color(0xFF4CAF50)
                  : AppColors.divider,
              width: session.status == SessionStatus.inProgress ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    timeBox,
                    const SizedBox(height: 16),
                    detailsSection,
                    const SizedBox(height: 16),
                    actionButtons,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    timeBox,
                    const SizedBox(width: 20),
                    Expanded(child: detailsSection),
                    const SizedBox(width: 20),
                    actionButtons,
                  ],
                ),
        );
      },
    );
  }
}
