// lib/features/parent/dashboard/parent_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import 'widgets/parent_request_appointment_dialog.dart';

class ParentDashboardPage extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const ParentDashboardPage({super.key, this.onNavigateTab});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  DateTime _selectedDate = DateTime.now();
  final String _childName = 'Alex Thomas Sam';
  final String _parentName = 'Mr. John Wilson';

  void _openAppointmentDialog() {
    showDialog(
      context: context,
      builder: (_) => ParentRequestAppointmentDialog(
        childName: _childName,
        parentName: _parentName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final childSessions = scheduleService.getSessionsForStudent(_childName, date: _selectedDate);
    final allStudentSessions = scheduleService.getSessionsForStudent(_childName);
    final completedSessionsCount = allStudentSessions.where((s) => s.status == SessionStatus.completed).length;

    // Director appointments for parent / student
    final parentAppointments = scheduleService.getAppointmentsForStudentOrParent(_childName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Top Welcome & Child Info Banner (Responsive) ───
          _buildChildHeaderBanner(),
          const SizedBox(height: 24),

          // ── 2. Two-Column Layout: Left = Child's Day Timetable & Carryover, Right = Director Appointments & KPIs ───
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 950;

              final leftColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Child's Daily Timetable Card
                  _buildChildTimetableCard(childSessions),
                  const SizedBox(height: 24),

                  // Today's Clinical Takeaway & Home Carryover Directives
                  _buildHomeCarryoverCard(),
                ],
              );

              final rightColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Director Appointments & Booking Card
                  _buildDirectorAppointmentsCard(parentAppointments),
                  const SizedBox(height: 24),

                  // Child's Clinical KPI Summary
                  _buildClinicalKpiCard(allStudentSessions.length, completedSessionsCount),
                ],
              );

              if (isStacked) {
                return Column(
                  children: [
                    leftColumn,
                    const SizedBox(height: 24),
                    rightColumn,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: leftColumn),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: rightColumn),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 1. Child Info & Greeting Banner ───
  Widget _buildChildHeaderBanner() {
    final now = DateTime.now();
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${dayNames[now.weekday - 1]}';

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.welcomeGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, bannerConstraints) {
                final isNarrow = bannerConstraints.maxWidth < 650;

                final textContent = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Parent Monitoring & Clinical Tracking Station',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Hi, Mr. John Wilson !',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Child: $_childName • Age 15 • Program: VB-MAPP Manding & Behavior Plan',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                );

                final actionBtn = ElevatedButton.icon(
                  onPressed: _openAppointmentDialog,
                  icon: const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
                  label: const Text(
                    '+ Request Meeting with Director',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textContent,
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity, child: actionBtn),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: textContent),
                    const SizedBox(width: 16),
                    actionBtn,
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                const Text(
                  'Center Status: Open & Active',
                  style: TextStyle(color: Color(0xFFC8E6C9), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Child's Daily Timetable Card ───
  Widget _buildChildTimetableCard(List<TherapySession> sessions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.schedule, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Therapy Timetable",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "Real-time schedule for $_childName",
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sessions.length} Sessions',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Date Quick Picker Strip
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDateFilterBtn('Today', DateTime.now()),
              _buildDateFilterBtn('Tomorrow', DateTime.now().add(const Duration(days: 1))),
              _buildDateFilterBtn('In 2 Days', DateTime.now().add(const Duration(days: 2))),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // Sessions List
          if (sessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.event_busy, size: 36, color: AppColors.textHint),
                  const SizedBox(height: 10),
                  Text(
                    'No scheduled therapy sessions for ${DateFormat('dd MMM').format(_selectedDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sessions are assigned by the Clinical Director based on weekly IEP allocations.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final s = sessions[i];
                return _buildChildSessionItem(s);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChildSessionItem(TherapySession session) {
    Color statusColor;
    Color statusBg;
    String statusLabel;

    switch (session.status) {
      case SessionStatus.inProgress:
        statusColor = const Color(0xFF1565C0);
        statusBg = const Color(0xFFE3F2FD);
        statusLabel = 'In Progress (Active Now)';
        break;
      case SessionStatus.completed:
        statusColor = const Color(0xFF2E7D32);
        statusBg = const Color(0xFFE8F5E9);
        statusLabel = 'Completed';
        break;
      case SessionStatus.cancelled:
        statusColor = const Color(0xFFC62828);
        statusBg = const Color(0xFFFFEBEE);
        statusLabel = 'Cancelled';
        break;
      case SessionStatus.upcoming:
      default:
        statusColor = const Color(0xFFE65100);
        statusBg = const Color(0xFFFFF3E0);
        statusLabel = 'Upcoming';
    }

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
          // Time badge + Status pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${session.startTime} - ${session.endTime}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Program Title
          Text(
            session.programTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Therapist & Room Details
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.badge_outlined, size: 15, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Therapist: ${session.therapistName}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.room_outlined, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    session.room,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          if (session.notes.isNotEmpty) ...[
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
                'Clinical Protocol: ${session.notes}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 3. Home Carryover & Clinical Takeaway Card ───
  Widget _buildHomeCarryoverCard() {
    return Container(
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Clinical Takeaway & Home Carryover",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "Specific directives from supervising therapists for evening practice",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // Directive 1
          _buildTakeawayItem(
            icon: Icons.record_voice_over_outlined,
            tag: 'MANDING (REQUESTS)',
            title: '3-Second Prompt Delay on Snack Time',
            instruction:
                'During evening snack time, wait 3 seconds before opening packages. Encourage vocal word approximations ("open", "cookie") before delivering.',
            therapist: 'Dr. Sarah Lee (Lead BCBA)',
          ),
          const SizedBox(height: 12),

          // Directive 2
          _buildTakeawayItem(
            icon: Icons.touch_app_outlined,
            tag: 'INTRAVERBALS & CONVERSATION',
            title: 'Functional Object Association Fill-ins',
            instruction:
                'Ask simple daily associations: "You sleep in a... (bed)", "You brush with a... (toothbrush)". Reinforce immediate vocal responses.',
            therapist: 'Michael Chang (BCaBA)',
          ),
        ],
      ),
    );
  }

  Widget _buildTakeawayItem({
    required IconData icon,
    required String tag,
    required String title,
    required String instruction,
    required String therapist,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                therapist,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            instruction,
            style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── 4. Director Consultations & Booking Card ───
  Widget _buildDirectorAppointmentsCard(List<DirectorAppointment> appointments) {
    return Container(
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_note, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Director Consultations',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Conferences & Evaluations with Dr. Sterling',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _openAppointmentDialog,
                icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                label: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          if (appointments.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 32, color: AppColors.textHint),
                  const SizedBox(height: 8),
                  const Text(
                    'No Upcoming Director Meetings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Click "Book" to schedule your 6-month IEP conference or diagnostic review.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final appt = appointments[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
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
                              '${DateFormat('dd MMM').format(appt.date)} • ${appt.startTime}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
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
                      const SizedBox(height: 8),
                      Text(
                        appt.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
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
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── 5. Child's Clinical KPI Summary Card ───
  Widget _buildClinicalKpiCard(int totalSessions, int completedSessions) {
    return Container(
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
              const Icon(Icons.bar_chart, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                "Clinical Progress Summary",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (widget.onNavigateTab != null)
                InkWell(
                  onTap: () => widget.onNavigateTab!(2), // IEP Goal Data
                  child: const Text(
                    'Full IEP Goals →',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, kpiConstraints) {
              final isNarrow = kpiConstraints.maxWidth < 360;

              final stat1 = _buildKpiBox('Mastered Targets', '42', 'VB-MAPP Domains', Colors.green);
              final stat2 = _buildKpiBox('Total Sessions', '$completedSessions / $totalSessions', 'Attendance: 96%', AppColors.primary);

              if (isNarrow) {
                return Column(
                  children: [
                    stat1,
                    const SizedBox(height: 10),
                    stat2,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: stat1),
                  const SizedBox(width: 12),
                  Expanded(child: stat2),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiBox(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildDateFilterBtn(String label, DateTime date) {
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    return ElevatedButton(
      onPressed: () => setState(() => _selectedDate = date),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}
