// lib/features/director/schedule_section/director_schedule_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import '../dashboard/widgets/schedule_therapist_session_dialog.dart';

class DirectorSchedulePage extends StatefulWidget {
  const DirectorSchedulePage({super.key});

  @override
  State<DirectorSchedulePage> createState() => _DirectorSchedulePageState();
}

class _DirectorSchedulePageState extends State<DirectorSchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _therapistFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openScheduleDialog([String? therapistId]) {
    showDialog(
      context: context,
      builder: (ctx) => ScheduleTherapistSessionDialog(
        initialDate: _selectedDate,
        preselectedTherapistId: therapistId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final allSessions = scheduleService.getAllSessionsForDate(_selectedDate);
    final directorAppointments = scheduleService.getDirectorAppointments(date: _selectedDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Schedule Header Banner
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'BCBA-D Clinical Master Schedule',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Center Timetable & Executive Calendar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Monitor all therapist room sessions in real time, assign daily therapy timings, and review executive appointments scheduled by Admin.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                );

                final scheduleButton = ElevatedButton.icon(
                  onPressed: () => _openScheduleDialog(),
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text(
                    '+ Schedule Session for Therapist',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      textSection,
                      const SizedBox(height: 16),
                      scheduleButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: textSection),
                    const SizedBox(width: 16),
                    scheduleButton,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Tabs: Tab 1: All Therapists Master Timetable, Tab 2: Director Executive Calendar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 18),
                      const SizedBox(width: 8),
                      Text('All Therapists Timetable (${allSessions.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month, size: 18),
                      const SizedBox(width: 8),
                      Text("Director's Calendar (${directorAppointments.length})"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date Selector Bar
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

              final showingLabel = Text(
                'Showing ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 12),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dateButtons,
                    const SizedBox(height: 10),
                    showingLabel,
                  ],
                );
              }

              return Row(
                children: [
                  dateButtons,
                  const Spacer(),
                  showingLabel,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Tab Content
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                return _buildAllTherapistsTab(allSessions, scheduleService);
              } else {
                return _buildDirectorCalendarTab(directorAppointments, scheduleService);
              }
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

  // ── Tab 1: All Therapists Master Timetable ─────────────────────────────────
  Widget _buildAllTherapistsTab(List<TherapySession> allSessions, ScheduleService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clinician Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTherapistFilterChip('All', 'All Clinicians'),
              ...ScheduleService.centerTherapists.map((t) {
                return _buildTherapistFilterChip(t['id']!, t['name']!);
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Clinicians Roster & Room Matrix Grid
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ScheduleService.centerTherapists.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 16),
          itemBuilder: (ctx, i) {
            final therapist = ScheduleService.centerTherapists[i];
            if (_therapistFilter != 'All' && therapist['id'] != _therapistFilter) {
              return const SizedBox.shrink();
            }

            final therapistSessions = allSessions
                .where((s) => s.therapistId == therapist['id'])
                .toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));

            return _buildTherapistRosterCard(therapist, therapistSessions, service);
          },
        ),
      ],
    );
  }

  Widget _buildTherapistFilterChip(String id, String label) {
    final isSelected = _therapistFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _therapistFilter = id);
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
      ),
    );
  }

  Widget _buildTherapistRosterCard(
    Map<String, String> therapist,
    List<TherapySession> sessions,
    ScheduleService service,
  ) {
    final currentSession = sessions.firstWhere(
      (s) => s.status == SessionStatus.inProgress,
      orElse: () => TherapySession(
        id: '',
        therapistId: '',
        therapistName: '',
        studentId: '',
        studentName: '',
        studentAge: 0,
        programTitle: '',
        room: '',
        date: DateTime.now(),
        startTime: '',
        endTime: '',
      ),
    );
    final hasActiveSession = currentSession.id.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Therapist Header (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              final therapistInfo = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      therapist['name']!.substring(0, 1),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        therapist['name']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        therapist['designation']!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              );

              final statusPillAndBtn = Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hasActiveSession ? const Color(0xFFE8F5E9) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: hasActiveSession ? const Color(0xFF2E7D32) : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasActiveSession
                              ? 'In Session (${currentSession.room})'
                              : 'Available / Prep Time',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: hasActiveSession ? const Color(0xFF2E7D32) : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openScheduleDialog(therapist['id']),
                    icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                    label: const Text('+ Assign Session', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    therapistInfo,
                    const SizedBox(height: 12),
                    statusPillAndBtn,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: therapistInfo),
                  statusPillAndBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),

          // Daily Sessions Horizontal Stream for this therapist
          if (sessions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No sessions scheduled for this therapist on this date. Click "+ Assign Session" to add.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: sessions.map((session) {
                final isLive = session.status == SessionStatus.inProgress;
                final isDone = session.status == SessionStatus.completed;

                return Container(
                  width: 280,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLive ? const Color(0xFFF1F8E9) : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLive ? const Color(0xFF4CAF50) : AppColors.divider,
                      width: isLive ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: isLive ? Colors.green.shade800 : AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${session.startTime} - ${session.endTime}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isLive ? Colors.green.shade800 : AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            session.status.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isLive ? Colors.green.shade800 : isDone ? Colors.grey : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        session.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Room: ${session.room}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.programTitle,
                        style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ── Tab 2: Director Executive Calendar ────────────────────────────────────
  Widget _buildDirectorCalendarTab(List<DirectorAppointment> appointments, ScheduleService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informational Note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'These clinical appointments and parent diagnostic intakes are scheduled by the Admin office for the Director. Any updates here reflect center-wide.',
                  style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (appointments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Column(
              children: [
                Icon(Icons.event_available, size: 48, color: AppColors.textHint),
                SizedBox(height: 12),
                Text(
                  'No executive appointments scheduled for this date.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  'Admin coordinates and books all parent diagnostic intakes and clinical case reviews.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appointments.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) {
              final appt = appointments[i];
              return _buildAppointmentCard(appt, service);
            },
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(DirectorAppointment appt, ScheduleService service) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final timeBox = Container(
          width: isNarrow ? double.infinity : 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    appt.startTime,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'to ${appt.endTime}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  appt.type.shortTag,
                  style: const TextStyle(
                    color: AppColors.primary,
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
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  appt.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 12, color: Color(0xFF0369A1)),
                      const SizedBox(width: 4),
                      Text(
                        'Scheduled by ${appt.scheduledBy}',
                        style: const TextStyle(
                          color: Color(0xFF0369A1),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${appt.attendeeName} (${appt.attendeeRole})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (appt.attendeePhone.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(appt.attendeePhone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(appt.location, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            if (appt.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Text(
                  'Notes: ${appt.notes}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    timeBox,
                    const SizedBox(height: 14),
                    detailsSection,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    timeBox,
                    const SizedBox(width: 20),
                    Expanded(child: detailsSection),
                  ],
                ),
        );
      },
    );
  }
}
