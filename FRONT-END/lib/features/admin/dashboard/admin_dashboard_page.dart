import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import 'widgets/schedule_director_appointment_dialog.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'widgets/schedule_director_appointment_dialog.dart';

class AdminDashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateCalendar;

  const AdminDashboardPage({super.key, this.onNavigateCalendar});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _therapists = [];
  List<Map<String, dynamic>> _iepReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final sRes = await ApiService().get('get_students');
      final tRes = await ApiService().get('get_therapists');
      final iRes = await ApiService().get('get_iep_reports');

      if (mounted) {
        setState(() {
          if (sRes is List) _students = List<Map<String, dynamic>>.from(sRes);
          if (tRes is List) _therapists = List<Map<String, dynamic>>.from(tRes);
          if (iRes is List) _iepReports = List<Map<String, dynamic>>.from(iRes);
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
    final pendingIeps = _iepReports.where((r) => (r['status'] ?? '').toString().contains('Pending')).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 950;

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
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Welcome back to the work station',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
                            const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                            final dateStr =
                                '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${dayNames[now.weekday - 1]}';
                            return Text(
                              dateStr,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
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
                            _buildStatCard(Icons.group, Colors.pink.shade50, Colors.pink.shade300, 'Students', sCount),
                            const SizedBox(height: 12),
                            _buildStatCard(Icons.medical_services, Colors.teal.shade50, AppColors.accentTeal, 'Staffs', tCount),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(Icons.group, Colors.pink.shade50, Colors.pink.shade300, 'Students', sCount),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(Icons.medical_services, Colors.teal.shade50, AppColors.accentTeal, 'Staffs', tCount),
                            ),
                          ],
                        );
                }),
              ],
            );

            final pendingReports = Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending IEP Reports',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (pendingIeps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: Text('No pending IEP sign-offs', style: TextStyle(color: AppColors.textSecondary))),
                    )
                  else
                    ...pendingIeps.take(4).map((iep) {
                      final sName = iep['student_name'] ?? 'Student';
                      final createdDate = iep['created_at'] != null ? iep['created_at'].toString().split('T')[0] : '2026-09-11';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            AppImages.therapistAvatar(radius: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                  Text(createdDate, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.statusPendingBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('Pending', style: TextStyle(color: AppColors.statusPending, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: welcomeAndStats),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: pendingReports),
                ],
              );
            }

            return Column(
              children: [
                welcomeAndStats,
                const SizedBox(height: 20),
                pendingReports,
              ],
            );
          }),
          const SizedBox(height: 20),

          // ── Director's Calendar & Scheduling Dispatcher (Admin Portal) ───
          _AdminDirectorSchedulingDashboardWidget(onNavigateCalendar: widget.onNavigateCalendar),
          const SizedBox(height: 24),

          const Text('Recent Activities', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TabBar(
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textHint,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Recent Students'),
                    Tab(text: 'Recent IEP Requested'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    children: [
                      _buildStudentsTable(),
                      _buildIepTable(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, Color bg, Color iconColor, String title, String count) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.primary, fontSize: 14)),
              Text(count, style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTable() {
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Name', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Email Id', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Phone', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('Age', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Created Date', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('Status', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Expanded(
                child: _students.isEmpty
                    ? const Center(child: Text('No student records found in database', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        itemCount: _students.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
                        itemBuilder: (context, index) {
                          final s = _students[index];
                          final name = s['name'] ?? '${s['first_name']} ${s['last_name']}';
                          final email = '${(s['first_name'] ?? 'student').toString().toLowerCase()}@rohcenter.org';
                          final phone = s['phone'] ?? '+1 (555) 019-2834';
                          final age = _calculateAge(s['dob']);
                          final createdDate = s['created_at'] != null ? s['created_at'].toString().split('T')[0] : '2026-09-11';
                          final isActive = (s['status'] ?? 'Active') == 'Active';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
                                Expanded(flex: 2, child: Text(email, style: const TextStyle(color: AppColors.textPrimary))),
                                Expanded(flex: 2, child: Text(phone, style: const TextStyle(color: AppColors.textPrimary))),
                                Expanded(flex: 1, child: Text('$age', style: const TextStyle(color: AppColors.textPrimary))),
                                Expanded(flex: 2, child: Text(createdDate, style: const TextStyle(color: AppColors.textPrimary))),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isActive ? AppColors.statusActiveBg : AppColors.statusDeactivatedBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'De-Activated',
                                        style: TextStyle(
                                          color: isActive ? AppColors.statusActive : AppColors.statusDeactivated,
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
                                    onPressed: () {},
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    child: const Text('View', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('Previous', style: TextStyle(color: AppColors.textHint))),
                    const SizedBox(width: 8),
                    _buildPageNum(1, true),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () {}, child: const Text('Next', style: TextStyle(color: AppColors.primary))),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIepTable() {
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Student', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Therapist', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Title', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Cycle', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('Status', style: TextStyle(color: AppColors.tableHeaderText, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Expanded(
                child: _iepReports.isEmpty
                    ? const Center(child: Text('No IEP records found in database', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        itemCount: _iepReports.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
                        itemBuilder: (context, index) {
                          final iep = _iepReports[index];
                          final sName = iep['student_name'] ?? 'Student';
                          final tName = iep['therapist_name'] ?? 'Therapist';
                          final title = iep['title'] ?? 'IEP Plan';
                          final cycle = iep['cycle_term'] ?? 'Q3 2026';
                          final status = iep['status'] ?? 'Active';
                          final isActive = status == 'Active';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(sName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
                                Expanded(flex: 2, child: Text(tName, style: const TextStyle(color: AppColors.textPrimary))),
                                Expanded(flex: 2, child: Text(title, style: const TextStyle(color: AppColors.textPrimary))),
                                Expanded(flex: 2, child: Text(cycle, style: const TextStyle(color: AppColors.textPrimary))),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isActive ? AppColors.statusActiveBg : AppColors.statusPendingBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: isActive ? AppColors.statusActive : AppColors.statusPending,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageNum(int num, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        num.toString(),
        style: TextStyle(color: active ? Colors.white : AppColors.textPrimary),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final todayAppointments = scheduleService.getDirectorAppointments(date: DateTime.now());
    final availableSlots = scheduleService.getAvailableDirectorSlots(DateTime.now());

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
                    child: const Icon(Icons.event_available, color: AppColors.primary, size: 20),
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
                          'Admin Clinical Coordination • Check availability & book parent diagnostic intakes for Dr. Vincent Sterling',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        const Icon(Icons.schedule, size: 16, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 6),
                        const Text(
                          "Today's Available Slots",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8E9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFA5D6A7)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, size: 12, color: Color(0xFF2E7D32)),
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
                            Icon(Icons.arrow_forward, size: 12, color: AppColors.primary),
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
                        const Icon(Icons.assignment_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text(
                          "Director's Booked Agenda (Today)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          '${todayAppointments.length} Booked',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (todayAppointments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No appointments booked for today yet.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                              border: Border.all(color: const Color(0xFFEEEEEE)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

