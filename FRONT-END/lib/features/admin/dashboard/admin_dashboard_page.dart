import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/widgets/edit_record_dialogs.dart';
import 'widgets/schedule_director_appointment_dialog.dart';

class AdminDashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateCalendar;
  final VoidCallback? onNavigateStudents;

  const AdminDashboardPage({
    super.key,
    this.onNavigateCalendar,
    this.onNavigateStudents,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _therapists = [];
  bool _isLoading = true;

  static const int _studentsPerPage = 5;
  int _studentPage = 0;

  int get _studentPageCount =>
      (_students.length / _studentsPerPage).ceil().clamp(1, 1 << 30);

  List<Map<String, dynamic>> get _pagedStudents {
    final page = _studentPage.clamp(0, _studentPageCount - 1);
    return _students
        .skip(page * _studentsPerPage)
        .take(_studentsPerPage)
        .toList();
  }

  /// Opens the edit dialog for [s]; falls back to the Students tab when the
  /// row has no id.
  Future<void> _viewStudent(Map<String, dynamic> s) async {
    if (int.tryParse(s['id']?.toString() ?? '') == null) {
      widget.onNavigateStudents?.call();
      return;
    }
    if (await EditStudentDialog.show(context, s)) _loadDashboardData();
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final sRes = await ApiService().get('get_students');
      final tRes = await ApiService().get('get_therapists');

      if (mounted) {
        setState(() {
          if (sRes is List) {
            _students = List<Map<String, dynamic>>.from(sRes);
            if (_studentPage >= _studentPageCount) {
              _studentPage = _studentPageCount - 1;
            }
          }
          if (tRes is List) _therapists = List<Map<String, dynamic>>.from(tRes);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calculateAge(dynamic dob) {
    if (dob == null) return 10;
    try {
      final birthDate = DateTime.parse(dob.toString());
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age > 0 ? age : 1;
    } catch (_) {
      return 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final welcomeAndStats = Column(
              children: [
                Container(
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
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ROH Admin !',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Welcome back to the work station',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Builder(
                          builder: (context) {
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
                            return Text(
                              dateStr,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (ctx, innerConstraints) {
                  final stackStats = innerConstraints.maxWidth < 450;
                  final sCount = _isLoading ? '...' : '${_students.length}';
                  final tCount = _isLoading ? '...' : '${_therapists.length}';

                  return stackStats
                      ? Column(
                          children: [
                            _buildStatCard(Icons.group, Colors.pink.shade50,
                                Colors.pink.shade300, 'Students', sCount),
                            const SizedBox(height: 12),
                            _buildStatCard(
                                Icons.medical_services,
                                Colors.teal.shade50,
                                AppColors.accentTeal,
                                'Staffs',
                                tCount),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                  Icons.group,
                                  Colors.pink.shade50,
                                  Colors.pink.shade300,
                                  'Students',
                                  sCount),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                  Icons.medical_services,
                                  Colors.teal.shade50,
                                  AppColors.accentTeal,
                                  'Staffs',
                                  tCount),
                            ),
                          ],
                        );
                }),
              ],
            );

            return welcomeAndStats;
          }),
          const SizedBox(height: 20),

          // ── Director's Calendar & Scheduling Dispatcher (Admin Portal) ───
          _AdminDirectorSchedulingDashboardWidget(
              onNavigateCalendar: widget.onNavigateCalendar),
          const SizedBox(height: 24),

          const Text('Recent Students',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 16),
          SizedBox(height: 400, child: _buildStudentsTable()),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, Color bg, Color iconColor, String title, String count) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 14)),
                Text(count,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTable() {
    // Phone: one card per student instead of the 7-column table.
    if (Breakpoints.isCompact(context)) return _buildStudentCards();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 750,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text('Name',
                            style: TextStyle(
                                color: AppColors.tableHeaderText,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 2,
                        child: Text('Email Id',
                            style: TextStyle(
                                color: AppColors.tableHeaderText,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 2,
                        child: Text('Phone',
                            style: TextStyle(
                                color: AppColors.tableHeaderText,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 1,
                        child: Text('Age',
                            style: TextStyle(
                                color: AppColors.tableHeaderText,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 2,
                        child: Text('Created Date',
                            style: TextStyle(
                                color: AppColors.tableHeaderText,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 1,
                        child: Text('Status',
                            style: TextStyle(
                                color: AppColors.tableHeaderText,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 1,
                        child: Text('',
                            style: TextStyle(
                                color: AppColors.tableHeaderText,
                                fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Expanded(
                child: _students.isEmpty
                    ? const Center(
                        child: Text('No student records found in database',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        itemCount: _pagedStudents.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppColors.divider),
                        itemBuilder: (context, index) {
                          final s = _pagedStudents[index];
                          final name = s['name'] ??
                              '${s['first_name']} ${s['last_name']}';
                          final email =
                              s['email']?.toString().isNotEmpty == true
                                  ? s['email'].toString()
                                  : 'Not provided';
                          final phone =
                              s['phone']?.toString().isNotEmpty == true
                                  ? s['phone'].toString()
                                  : 'Not provided';
                          final age = _calculateAge(s['dob']);
                          final createdDate = s['created_at'] != null
                              ? s['created_at'].toString().split('T')[0]
                              : '—';
                          final isActive =
                              (s['status'] ?? 'Active') == 'Active';

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 2,
                                    child: Text(name,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w500))),
                                Expanded(
                                    flex: 2,
                                    child: Text(email,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary))),
                                Expanded(
                                    flex: 2,
                                    child: Text(phone,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary))),
                                Expanded(
                                    flex: 1,
                                    child: Text('$age',
                                        style: const TextStyle(
                                            color: AppColors.textPrimary))),
                                Expanded(
                                    flex: 2,
                                    child: Text(createdDate,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary))),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppColors.statusActiveBg
                                            : AppColors.statusDeactivatedBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'De-Activated',
                                        style: TextStyle(
                                          color: isActive
                                              ? AppColors.statusActive
                                              : AppColors.statusDeactivated,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: OutlinedButton(
                                    onPressed: () => _viewStudent(s),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                          color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                    ),
                                    child: const Text('View',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (_studentPageCount > 1) ...[
                const Divider(height: 1, color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildStudentPagination(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _cardLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  color: AppColors.tableHeaderText,
                  fontWeight: FontWeight.w600)),
          TextSpan(
              text: value,
              style: const TextStyle(color: AppColors.textPrimary)),
        ]),
        style: const TextStyle(fontSize: 12.5),
      ),
    );
  }

  /// Phone layout of "Recent Students".
  Widget _buildStudentCards() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: _students.isEmpty
          ? const Center(
              child: Text('No student records found in database',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: _pagedStudents.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final s = _pagedStudents[index];
                      final name =
                          s['name'] ?? '${s['first_name']} ${s['last_name']}';
                      final email = s['email']?.toString().isNotEmpty == true
                          ? s['email'].toString()
                          : 'Not provided';
                      final phone = s['phone']?.toString().isNotEmpty == true
                          ? s['phone'].toString()
                          : 'Not provided';
                      final age = _calculateAge(s['dob']);
                      final createdDate = s['created_at'] != null
                          ? s['created_at'].toString().split('T')[0]
                          : '—';
                      final isActive = (s['status'] ?? 'Active') == 'Active';
                      return Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Text(name,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14))),
                                const SizedBox(width: 8),
                                isActive
                                    ? _statusChip(
                                        'Active',
                                        AppColors.statusActive,
                                        AppColors.statusActiveBg)
                                    : _statusChip(
                                        'De-Activated',
                                        AppColors.statusDeactivated,
                                        AppColors.statusDeactivatedBg),
                              ],
                            ),
                            const SizedBox(height: 4),
                            _cardLine('Email Id', email),
                            _cardLine('Phone', phone),
                            _cardLine('Age', '$age'),
                            _cardLine('Created Date', createdDate),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton(
                                onPressed: () => _viewStudent(s),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                      color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                ),
                                child: const Text('View',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_studentPageCount > 1) ...[
                  const Divider(height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: _buildStudentPagination(),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildStudentPagination() {
    final page = _studentPage.clamp(0, _studentPageCount - 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPaginationBtn('Previous', false,
            page > 0 ? () => setState(() => _studentPage = page - 1) : null),
        for (int i = 0; i < _studentPageCount; i++)
          _buildPaginationBtn(
              '${i + 1}', i == page, () => setState(() => _studentPage = i)),
        _buildPaginationBtn(
            'Next',
            false,
            page < _studentPageCount - 1
                ? () => setState(() => _studentPage = page + 1)
                : null),
      ],
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

// ── Director's Calendar & Scheduling Dispatcher (Admin Portal) ──────────────
class _AdminDirectorSchedulingDashboardWidget extends StatelessWidget {
  final VoidCallback? onNavigateCalendar;

  const _AdminDirectorSchedulingDashboardWidget({this.onNavigateCalendar});

  void _openBookingDialog(BuildContext context, [String? slot]) {
    showDialog(
      context: context,
      builder: (ctx) => ScheduleDirectorAppointmentDialog(
        initialDate: DateTime.now(),
        initialSlot: slot,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final todayAppointments =
        scheduleService.getDirectorAppointments(date: DateTime.now());
    final availableSlots =
        scheduleService.getAvailableDirectorSlots(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final headerInfo = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event_available,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Director's Calendar & Scheduling Dispatcher",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Admin Clinical Coordination • Check availability & book parent diagnostic intakes for the Clinical Director',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionBtn = ElevatedButton.icon(
                onPressed: () => _openBookingDialog(context),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  '+ Schedule Appointment for Director',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 1,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    headerInfo,
                    const SizedBox(height: 12),
                    actionBtn,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: headerInfo),
                  const SizedBox(width: 12),
                  actionBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // Two-Column Grid: Left: Available Slots, Right: Today's Booked Agenda (responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 850;

              final slotsWidget = Container(
                padding: const EdgeInsets.all(14),
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
                        const Icon(Icons.schedule,
                            size: 16, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 6),
                        const Text(
                          "Today's Available Slots",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${availableSlots.length} Open',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (availableSlots.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'All standard slots are booked for today.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableSlots.map((slot) {
                          return InkWell(
                            onTap: () => _openBookingDialog(context, slot),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8E9),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFFA5D6A7)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add,
                                      size: 12, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 4),
                                  Text(
                                    slot,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),
                    if (onNavigateCalendar != null)
                      InkWell(
                        onTap: onNavigateCalendar,
                        child: const Row(
                          children: [
                            Text(
                              'View Full Availability Calendar',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward,
                                size: 12, color: AppColors.primary),
                          ],
                        ),
                      ),
                  ],
                ),
              );

              final agendaWidget = Container(
                padding: const EdgeInsets.all(14),
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
                        const Icon(Icons.assignment_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text(
                          "Director's Booked Agenda (Today)",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          '${todayAppointments.length} Booked',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (todayAppointments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No appointments booked for today yet.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: todayAppointments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final appt = todayAppointments[i];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFEEEEEE)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    appt.startTime,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appt.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${appt.attendeeName} • ${appt.location}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    appt.type.shortTag,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0369A1),
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

              if (isStacked) {
                return Column(
                  children: [
                    slotsWidget,
                    const SizedBox(height: 16),
                    agendaWidget,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: slotsWidget),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: agendaWidget),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
