// lib/features/parent/dashboard/parent_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/services/db_queries.dart';
import 'package:roh_erp/core/services/progress_metrics.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import 'package:roh_erp/core/widgets/edit_record_dialogs.dart';
import 'package:roh_erp/features/auth/auth_service.dart';
import 'widgets/parent_request_appointment_dialog.dart';

class ParentDashboardPage extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const ParentDashboardPage({super.key, this.onNavigateTab});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  DateTime _selectedDate = DateTime.now();
  String get _childName {
    final students = ScheduleService.centerStudents;
    return students.isNotEmpty ? (students.first['name'] as String) : '';
  }

  String get _childId {
    final students = ScheduleService.centerStudents;
    return students.isNotEmpty ? '${students.first['id'] ?? ''}' : '';
  }

  // Mastered-target count for the child, loaded from daily data sheets
  // without blocking the rest of the page.
  String? _masteryLoadedFor;
  int? _masteredTargets;
  bool _masteryLoading = false;

  void _ensureMasteryLoaded() {
    final id = _childId;
    if (id.isEmpty || id == _masteryLoadedFor) return;
    _masteryLoadedFor = id;
    _masteryLoading = true;
    _masteredTargets = null;
    DailyDataQueries.fetchForStudent(id).then((rows) {
      if (!mounted || _masteryLoadedFor != id) return;
      final childRows = rows.where((r) => '${r['student_id']}' == id).toList();
      setState(() {
        _masteredTargets = childRows.isEmpty
            ? null
            : targetProgress(childRows).where((t) => t.mastered).length;
        _masteryLoading = false;
      });
    });
  }

  // Appointments cancelled from this page, kept so they show as cancelled
  // even before the next background sync reports the new status.
  final Set<String> _cancelledAppointmentIds = {};

  bool _isCancelled(DirectorAppointment appt) =>
      appt.status == AppointmentStatus.cancelled ||
      _cancelledAppointmentIds.contains(appt.id);

  /// Not cancelled or completed, and dated today or later.
  bool _canCancel(DirectorAppointment appt) {
    if (_isCancelled(appt) || appt.status == AppointmentStatus.completed) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(appt.date.year, appt.date.month, appt.date.day);
    return !day.isBefore(today);
  }

  Future<void> _cancelAppointment(DirectorAppointment appt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text(
            '${appt.title} on ${DateFormat('dd MMM yyyy').format(appt.date)} at ${appt.startTime} will be cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final res = await ApiService().post('update_director_appointment', {
      'id': appt.id,
      'status': 'cancelled',
    });
    if (!mounted) return;
    if (showApiResult(context, res, 'Appointment cancelled.')) {
      setState(() => _cancelledAppointmentIds.add(appt.id));
      final service = context.read<ScheduleService>();
      await service.syncWithBackend();
      service.updateAppointmentStatus(appt.id, AppointmentStatus.cancelled);
    }
  }

  void _openAppointmentDialog(String parentName) {
    showDialog(
      context: context,
      builder: (_) => ParentRequestAppointmentDialog(
        childName: _childName.isNotEmpty ? _childName : 'Student',
        parentName: parentName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final parentName = auth.currentUser?.name.isNotEmpty == true
        ? auth.currentUser!.name
        : 'Parent User';
    final scheduleService = context.watch<ScheduleService>();
    final childSessions = _childName.isNotEmpty
        ? scheduleService.getSessionsForStudent(_childName, date: _selectedDate)
        : <TherapySession>[];
    final allStudentSessions = _childName.isNotEmpty
        ? scheduleService.getSessionsForStudent(_childName)
        : <TherapySession>[];
    _ensureMasteryLoaded();

    // Director appointments for parent / student
    final parentAppointments = _childName.isNotEmpty
        ? scheduleService.getAppointmentsForStudentOrParent(_childName)
        : <DirectorAppointment>[];

    return SingleChildScrollView(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Top Welcome & Child Info Banner (Responsive) ───
          _buildChildHeaderBanner(parentName),
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
                  _buildHomeCarryoverCard(allStudentSessions),
                ],
              );

              final rightColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Director Appointments & Booking Card
                  _buildDirectorAppointmentsCard(
                      parentAppointments, parentName),
                  const SizedBox(height: 24),

                  // Child's Clinical KPI Summary
                  _buildClinicalKpiCard(allStudentSessions),
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
  Widget _buildChildHeaderBanner(String parentName) {
    final now = DateTime.now();
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${dayNames[now.weekday - 1]}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Parent Monitoring & Clinical Tracking Station',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hi, $parentName !',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _childName.isNotEmpty
                          ? 'Child: $_childName • Enrolled Center Student'
                          : 'No enrolled child linked to this parent account',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                );

                final actionBtn = Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openAppointmentDialog(parentName),
                      icon: const Icon(Icons.event_available,
                          color: AppColors.primary, size: 18),
                      label: const Text(
                        '+ Request Meeting with Director',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(3);
                        }
                      },
                      icon: const Icon(Icons.show_chart,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'View Real-Time Graphs',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                  ],
                ),
                const Text(
                  'Center Status: Open & Active',
                  style: TextStyle(
                      color: Color(0xFFE8F5E9),
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
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
                child: const Icon(Icons.schedule,
                    size: 18, color: AppColors.primary),
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
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              _buildDateFilterBtn(
                  'Tomorrow', DateTime.now().add(const Duration(days: 1))),
              _buildDateFilterBtn(
                  'In 2 Days', DateTime.now().add(const Duration(days: 2))),
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
                  const Icon(Icons.event_busy,
                      size: 36, color: AppColors.textHint),
                  const SizedBox(height: 10),
                  Text(
                    'No scheduled therapy sessions for ${DateFormat('dd MMM').format(_selectedDate)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sessions are assigned by the Clinical Director based on weekly IEP allocations.',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
      case SessionStatus.upcoming:
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  const Icon(Icons.badge_outlined,
                      size: 15, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Therapist: ${session.therapistName}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.room_outlined,
                      size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    session.room,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
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
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 3. Home Carryover & Clinical Takeaway Card ───
  Widget _buildHomeCarryoverCard(List<TherapySession> sessions) {
    final sessionsWithDirectives =
        sessions.where((s) => s.notes.isNotEmpty).toList();

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
                child: const Icon(Icons.lightbulb_outline,
                    size: 18, color: Color(0xFF2E7D32)),
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
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          if (sessionsWithDirectives.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text(
                    'No Home Carryover Directives Yet',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'When therapists complete clinical sessions with practice notes, home carryover directives will appear here.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...sessionsWithDirectives.take(3).map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTakeawayItem(
                    icon: Icons.record_voice_over_outlined,
                    tag: s.programTitle.toUpperCase(),
                    title: 'Clinical Practice Directive',
                    instruction: s.notes,
                    therapist: s.therapistName,
                  ),
                )),
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
              const SizedBox(width: 8),
              const Spacer(),
              Flexible(
                flex: 3,
                child: Text(
                  therapist,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
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
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF374151), height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── 4. Director Consultations & Booking Card ───
  Widget _buildDirectorAppointmentsCard(
      List<DirectorAppointment> appointments, String parentName) {
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
                child: const Icon(Icons.event_note,
                    size: 18, color: AppColors.primary),
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
                      'Conferences & Evaluations with the Clinical Director',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openAppointmentDialog(parentName),
                icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                label: const Text('Book',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
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
                  const Icon(Icons.calendar_today_outlined,
                      size: 32, color: AppColors.textHint),
                  const SizedBox(height: 8),
                  const Text(
                    'No Upcoming Director Meetings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Click "Book" to schedule your 6-month IEP conference or diagnostic review.',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                final cancelled = _isCancelled(appt);
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cancelled
                                  ? const Color(0xFFFFEBEE)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              cancelled
                                  ? 'Cancelled'
                                  : switch (appt.status) {
                                      AppointmentStatus.tentative =>
                                        'Tentative',
                                      AppointmentStatus.completed =>
                                        'Completed',
                                      _ => 'Confirmed',
                                    },
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: cancelled
                                    ? const Color(0xFFC62828)
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appt.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.room_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              appt.location,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      if (_canCancel(appt))
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _cancelAppointment(appt),
                            icon: const Icon(Icons.event_busy_outlined,
                                size: 16, color: Colors.red),
                            label: const Text(
                              'Cancel appointment',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
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
  Widget _buildClinicalKpiCard(List<TherapySession> sessions) {
    final totalSessions = sessions.length;
    final completedSessions =
        sessions.where((s) => s.status == SessionStatus.completed).length;
    // Attendance = completed / sessions dated up to today that are no
    // longer upcoming (future and still-upcoming sessions are excluded).
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    final dueSessions = sessions
        .where((s) =>
            s.date.isBefore(endOfToday) && s.status != SessionStatus.upcoming)
        .length;
    final attendance = dueSessions == 0
        ? '—'
        : '${(completedSessions / dueSessions * 100).round()}%';
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
              const Expanded(
                child: Text(
                  "Clinical Progress Summary",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.onNavigateTab != null)
                InkWell(
                  onTap: () => widget.onNavigateTab!(2), // IEP Goal Data
                  child: const Text(
                    'Full IEP Goals →',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, kpiConstraints) {
              final isNarrow = kpiConstraints.maxWidth < 360;

              final stat1 = _buildKpiBox(
                'Mastered Targets',
                _masteryLoading ? '…' : (_masteredTargets?.toString() ?? '—'),
                _masteryLoading
                    ? 'Loading data sheets'
                    : (_masteredTargets == null
                        ? 'No data sheets yet'
                        : 'Skill targets at 80%+ criteria'),
                Colors.green,
              );
              final stat2 = _buildKpiBox(
                'Total Sessions',
                '$completedSessions / $totalSessions',
                totalSessions > 0
                    ? 'Attendance: $attendance'
                    : 'No sessions scheduled',
                AppColors.primary,
              );

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

  Widget _buildKpiBox(
      String title, String value, String subtitle, Color color) {
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
          Text(title,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
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
          side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.divider),
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
