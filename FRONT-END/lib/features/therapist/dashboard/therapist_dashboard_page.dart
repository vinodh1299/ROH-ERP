import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/services/web_storage/web_storage.dart';
import 'package:roh_erp/features/auth/auth_service.dart';
import 'package:roh_erp/features/therapist/daily_data_sheet/daily_data_sheet_page.dart';
import 'package:roh_erp/features/therapist/iep/iep_page.dart';
import 'package:roh_erp/features/therapist/widgets/complete_session.dart';

class TherapistDashboardPage extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const TherapistDashboardPage({super.key, this.onNavigateTab});

  @override
  State<TherapistDashboardPage> createState() => _TherapistDashboardPageState();
}

class _TherapistDashboardPageState extends State<TherapistDashboardPage> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _iepReports = [];
  bool _isLoading = true;
  bool _showReturned = false; // Recent Activities tab
  int _page = 0;
  static const _pageSize = 5;
  static const _iepTabIndex = 8; // IepPage in TherapistShell._pages

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  Future<void> _fetchRealData() async {
    try {
      final api = ApiService();
      final studentsRes = await api.get('get_students');
      final iepRes = await api.get('get_iep_reports');

      if (mounted) {
        setState(() {
          if (studentsRes is List) {
            _students = List<Map<String, dynamic>>.from(studentsRes);
          }
          if (iepRes is List) {
            _iepReports = List<Map<String, dynamic>>.from(iepRes);
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Whole years since [dob], or null when the date of birth is missing or
  /// unparseable (callers then show no age instead of a made-up one).
  int? _ageFromDob(dynamic dob) {
    final raw = dob?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    // MySQL DATE columns arrive as UTC midnight ISO strings; read them in
    // local time so the birthday doesn't shift by a day.
    final birthDate = parsed.isUtc ? parsed.toLocal() : parsed;
    final now = DateTime.now();
    if (birthDate.isAfter(now)) return null;
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Age of the student with [studentId], from the loaded student records'
  /// date of birth. Session objects don't carry a real age.
  int? _ageForStudent(String studentId) {
    for (final s in _students) {
      if (s['id']?.toString() == studentId) return _ageFromDob(s['dob']);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final scheduleService = context.watch<ScheduleService>();
    final therapistId =
        (auth.currentUser?.id != null && auth.currentUser!.id > 0)
            ? auth.currentUser!.id.toString()
            : (getWebStorage('user_id') ?? '3');
    final todaySessions = scheduleService.getSessionsForTherapist(therapistId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1050;

        final leftColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Banner
            Container(
              padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hi, Therapist !',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back to your therapist panel.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Row (Responsive)
            LayoutBuilder(
              builder: (context, statsConstraints) {
                final isNarrow = statsConstraints.maxWidth < 450;
                final studentsCard = _buildStatCard(
                  'Total Students',
                  _isLoading ? '...' : '${_students.length}',
                  Icons.people_outline,
                  Colors.pinkAccent,
                );
                final sessionsCard = _buildStatCard(
                  'Todays Sessions',
                  todaySessions.length.toString(),
                  Icons.calendar_today_outlined,
                  AppColors.accentTeal,
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      studentsCard,
                      const SizedBox(height: 12),
                      sessionsCard,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: studentsCard),
                    const SizedBox(width: 16),
                    Expanded(child: sessionsCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Activities Table Container
            Container(
              padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tabs
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      const Text(
                        'Recent Activities',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildTabButton('Recent IEP Requested',
                              !_showReturned, () => _selectTab(false)),
                          _buildTabButton('Returned IEP', _showReturned,
                              () => _selectTab(true)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Phones: one compact card per student. Wider: the table keeps a
                  // readable 700px minimum and scrolls sideways when narrower.
                  LayoutBuilder(
                    builder: (context, tableConstraints) {
                      final rows = _pageRows;
                      if (rows.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                              child: Text(
                                  _isLoading
                                      ? 'Loading…'
                                      : _showReturned
                                          ? 'No IEPs returned for revision'
                                          : 'No IEPs awaiting approval',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary))),
                        );
                      }
                      if (tableConstraints.maxWidth < 520) {
                        return Column(
                          children: [
                            for (int i = 0; i < rows.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              _buildActivityCard(rows[i]),
                            ],
                          ],
                        );
                      }
                      return ScrollableMinWidth(
                        minWidth: 700,
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                      flex: 2, child: _TableHeaderText('Name')),
                                  Expanded(
                                      flex: 2,
                                      child: _TableHeaderText('Email Id')),
                                  Expanded(
                                      flex: 2,
                                      child: _TableHeaderText('Phone')),
                                  Expanded(
                                      flex: 1, child: _TableHeaderText('Age')),
                                  Expanded(
                                      flex: 2,
                                      child: _TableHeaderText('Created Date')),
                                  Expanded(
                                      flex: 2,
                                      child: _TableHeaderText('Status')),
                                  Expanded(
                                      flex: 1,
                                      child: _TableHeaderText('Action')),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Table Content with real student records
                            ...rows.map((r) => Column(
                                  children: [
                                    _buildTableRow(
                                      row: r,
                                      name: r.name,
                                      email: r.email,
                                      phone: r.phone,
                                      age: r.age,
                                      date: r.date,
                                      status: r.status,
                                    ),
                                    const Divider(color: AppColors.divider),
                                  ],
                                )),
                          ],
                        ),
                      );
                    },
                  ),

                  // Pagination (only when there is more than one page)
                  if (_pageCount > 1) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPaginationBtn(
                                'Previous',
                                false,
                                _page > 0
                                    ? () => setState(() => _page--)
                                    : null),
                            for (int i = 0; i < _pageCount; i++)
                              _buildPaginationBtn('${i + 1}', i == _page,
                                  () => setState(() => _page = i)),
                            _buildPaginationBtn(
                                'Next',
                                false,
                                _page < _pageCount - 1
                                    ? () => setState(() => _page++)
                                    : null),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

        final rightColumn = Container(
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
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    "Today's Timetable",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${todaySessions.length} Sessions',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Director-Assigned Caseload',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (widget.onNavigateTab != null)
                    InkWell(
                      onTap: () => widget.onNavigateTab!(1),
                      child: const Text(
                        'Full Schedule →',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Sessions List
              if (todaySessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_available,
                          size: 36, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      const Text(
                        'No sessions today',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Director has not scheduled any sessions for today yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todaySessions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final session = todaySessions[index];
                    final isLive = session.status == SessionStatus.inProgress;
                    final isDone = session.status == SessionStatus.completed;

                    Color statusColor = isLive
                        ? const Color(0xFF2E7D32)
                        : isDone
                            ? Colors.grey.shade600
                            : AppColors.primary;
                    Color statusBg = isLive
                        ? const Color(0xFFE8F5E9)
                        : isDone
                            ? Colors.grey.shade200
                            : AppColors.primaryLight;
                    String statusText = isLive
                        ? '● LIVE NOW'
                        : isDone
                            ? '✓ Completed'
                            : 'Upcoming';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLive
                            ? const Color(0xFFFAFFFA)
                            : const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLive
                              ? const Color(0xFF4CAF50)
                              : AppColors.divider,
                          width: isLive ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time & Status Row
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 13, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                '${session.startTime} - ${session.endTime}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Student & Room Row
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  session.studentName.isNotEmpty
                                      ? session.studentName[0]
                                      : 'S',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.studentName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _ageForStudent(session.studentId) != null
                                          ? 'Age: ${_ageForStudent(session.studentId)}y • ${session.room}'
                                          : session.room,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Program Tag
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: const Color(0xFFEEEEEE)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.psychology,
                                    size: 13, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    session.programTitle,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Action Buttons Row
                          Row(
                            children: [
                              // Completion (no separate Start step)
                              if (sessionAwaitingCompletion(session) &&
                                  sessionHasStarted(session))
                                InkWell(
                                  onTap: () =>
                                      confirmSessionCompleted(context, session),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.check,
                                            size: 12, color: Colors.white),
                                        SizedBox(width: 2),
                                        Text(
                                          'Mark Completed',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const Spacer(),

                              // Open Data Sheet Button
                              InkWell(
                                onTap: () {
                                  final id = int.tryParse(session.studentId);
                                  if (id != null) {
                                    DailyDataSheetPage.openStudent.value =
                                        (id: id, name: session.studentName);
                                  }
                                  widget.onNavigateTab
                                      ?.call(9); // Daily Data Sheet
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit_note,
                                          size: 13, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'Data Sheet',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: leftColumn),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: rightColumn),
            ],
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftColumn,
              const SizedBox(height: 24),
              rightColumn,
            ],
          ),
        );
      },
    );
  }

  void _selectTab(bool returned) {
    if (_showReturned == returned) return;
    setState(() {
      _showReturned = returned;
      _page = 0;
    });
  }

  /// IEPs for the selected tab: awaiting the director's approval, or sent
  /// back for revision. Newest first (the API orders by id DESC).
  List<_ActivityRow> get _tabRows {
    final wanted = _showReturned ? 'Returned for Revision' : 'Pending Approval';
    return _iepReports
        .where((r) => r['status']?.toString() == wanted)
        .map(_activityRowData)
        .toList();
  }

  int get _pageCount => (_tabRows.length / _pageSize).ceil();

  List<_ActivityRow> get _pageRows {
    final rows = _tabRows;
    final page = _page.clamp(0, _pageCount == 0 ? 0 : _pageCount - 1);
    return rows.skip(page * _pageSize).take(_pageSize).toList();
  }

  Map<String, dynamic>? _studentById(String id) {
    for (final s in _students) {
      if (s['id']?.toString() == id) return s;
    }
    return null;
  }

  _ActivityRow _activityRowData(Map<String, dynamic> iep) {
    final studentId = iep['student_id']?.toString() ?? '';
    final student = _studentById(studentId);
    String field(String key) {
      final v = student?[key]?.toString() ?? '';
      return v.isNotEmpty ? v : 'Not provided';
    }

    final name = (iep['student_name'] ??
            (student == null
                ? 'Student'
                : '${student['first_name']} ${student['last_name']}'))
        .toString();
    final age =
        _ageFromDob(iep['student_dob'] ?? student?['dob'])?.toString() ?? '';
    final createdDate = iep['created_at'] != null
        ? iep['created_at'].toString().split('T')[0]
        : '—';
    return _ActivityRow(
        studentId: int.tryParse(studentId),
        name: name,
        email: field('email'),
        phone: field('phone'),
        age: age,
        date: createdDate,
        status: (iep['status'] ?? 'Pending Approval').toString());
  }

  /// Opens the student's IEP on the IEP tab.
  void _openIep(_ActivityRow r) {
    final id = r.studentId;
    if (id == null) return;
    IepPage.openStudent.value = (id: id, name: r.name);
    widget.onNavigateTab?.call(_iepTabIndex);
  }

  (Color, Color) _statusColors(String status) {
    if (status == 'Pending' || status == 'Pending Approval') {
      return (AppColors.statusPending, AppColors.statusPendingBg);
    }
    if (status == 'Approved' || status == 'Active' || status == 'Completed') {
      return (AppColors.statusActive, AppColors.statusActiveBg);
    }
    return (AppColors.statusDeactivated, AppColors.statusDeactivatedBg);
  }

  /// Compact (phone) version of one Recent Activities table row.
  Widget _buildActivityCard(_ActivityRow r) {
    final (statusColor, statusBg) = _statusColors(r.status);
    const labelStyle = TextStyle(
        fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary);
    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$label: ', style: labelStyle),
              TextSpan(text: value, style: _rowTextStyle()),
            ]),
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.name,
                  style: _rowTextStyle().copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: statusBg, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  r.status,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          line('Email Id', r.email),
          line('Phone', r.phone),
          if (r.age.isNotEmpty) line('Age', r.age),
          line('Created Date', r.date),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _viewButton(r,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewButton(_ActivityRow r, {required EdgeInsets padding}) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _openIep(r),
        child: Padding(
          padding: padding,
          child: const Text(
            'View',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow({
    required _ActivityRow row,
    required String name,
    required String email,
    required String phone,
    required String age,
    required String date,
    required String status,
  }) {
    final (statusColor, statusBg) = _statusColors(status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: _rowTextStyle())),
          Expanded(flex: 2, child: Text(email, style: _rowTextStyle())),
          Expanded(flex: 2, child: Text(phone, style: _rowTextStyle())),
          Expanded(flex: 1, child: Text(age, style: _rowTextStyle())),
          Expanded(flex: 2, child: Text(date, style: _rowTextStyle())),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: _viewButton(row,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
          ),
        ],
      ),
    );
  }

  TextStyle _rowTextStyle() {
    return const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      color: AppColors.textPrimary,
    );
  }

  Widget _buildPaginationBtn(
      String text, bool isSelected, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null && !isSelected ? 0.4 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityRow {
  final int? studentId;
  final String name;
  final String email;
  final String phone;
  final String age;
  final String date;
  final String status;
  const _ActivityRow({
    required this.studentId,
    required this.name,
    required this.email,
    required this.phone,
    required this.age,
    required this.date,
    required this.status,
  });
}

class _TableHeaderText extends StatelessWidget {
  final String text;
  const _TableHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.tableHeaderText,
      ),
    );
  }
}
