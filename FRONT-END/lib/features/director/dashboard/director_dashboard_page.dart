import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import '../../auth/auth_service.dart';
import 'widgets/schedule_therapist_session_dialog.dart';

class DirectorDashboardPage extends StatelessWidget {
  const DirectorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final now = DateTime.now();
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${dayNames[now.weekday - 1]}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Welcome Card + Caseload Capacity Card ──────────────
          LayoutBuilder(builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 800;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: _DirectorWelcomeCard(name: user?.name ?? 'Clinical Director', dateStr: dateStr)),
                      const SizedBox(width: 20),
                      const Expanded(flex: 5, child: _CenterCapacityCard()),
                    ],
                  )
                : Column(children: [
                    _DirectorWelcomeCard(name: user?.name ?? 'Clinical Director', dateStr: dateStr),
                    const SizedBox(height: 16),
                    const _CenterCapacityCard(),
                  ]);
          }),
          const SizedBox(height: 20),

          // ── Urgent Executive Action Banners ─────────────────────────────
          const _UrgentActionBanners(),
          const SizedBox(height: 20),

          // ── Center-Wide Clinical KPI Grid (Responsive 1/2/4 Columns) ────
          LayoutBuilder(builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final crossAxisCount = w < 520 ? 1 : (w < 950 ? 2 : 4);
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: crossAxisCount == 1 ? 3.0 : (crossAxisCount == 2 ? 2.4 : 1.8),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _KpiStatCard(
                  label: 'Active Caseload',
                  value: '24 / 30',
                  subtext: '80% Center Capacity',
                  icon: Icons.people_outline,
                  color: AppColors.primary,
                ),
                _KpiStatCard(
                  label: 'Mastery Velocity',
                  value: '248 Targets',
                  subtext: '+18.4% this quarter',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                _KpiStatCard(
                  label: 'Audit Compliance',
                  value: '96.4%',
                  subtext: 'On-time evaluations',
                  icon: Icons.verified_user_outlined,
                  color: Colors.blue,
                ),
                _KpiStatCard(
                  label: 'BACB Supervised',
                  value: '42.5 hrs',
                  subtext: '5.2% ratio (Compliant)',
                  icon: Icons.access_time_outlined,
                  color: Colors.teal,
                ),
              ],
            );
          }),
          const SizedBox(height: 24),

          // ── Executive Analytics & Caseload Intelligence (FRS 8) ────────
          const _DirectorExecutiveAnalyticsSection(),
          const SizedBox(height: 24),

          // ── Today's Center Operations & Live Therapist Timetable ────────
          const _DirectorLiveTimetableSection(),
          const SizedBox(height: 24),

          // ── Director's Executive Appointments (Scheduled by Admin) ──────
          const _DirectorExecutiveAppointmentsSection(),
          const SizedBox(height: 28),

          // ── Clinical Operations Tabbed Panel ────────────────────────────
          const _ClinicalOperationsSection(),
        ],
      ),
    );
  }
}

// ── Welcome Card ─────────────────────────────────────────────────────────────
class _DirectorWelcomeCard extends StatelessWidget {
  final String name;
  final String dateStr;
  const _DirectorWelcomeCard({required this.name, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                    'BCBA-D Clinical Director Command',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.shield_outlined, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text('Hi, $name !', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Clinical oversight, BACB governance, and treatment plan authorization station.', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Center Capacity Card ─────────────────────────────────────────────────────
class _CenterCapacityCard extends StatelessWidget {
  const _CenterCapacityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Center Clinical Caseload Capacity',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                child: const Text('6 Open Slots', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Enrolled: 24 / 30 Students', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text('80% Utilized', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.8,
              minHeight: 10,
              backgroundColor: Color(0xFFF3E8FF),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.hourglass_top_outlined, size: 16, color: AppColors.statusPending),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Admissions Waitlist: 7 Students (3 in Intake Assessment)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Urgent Action Banners ────────────────────────────────────────────────────
class _UrgentActionBanners extends StatelessWidget {
  const _UrgentActionBanners();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.priority_high, color: Color(0xFFD97706), size: 20),
              SizedBox(width: 8),
              Text('Director Clinical Attention Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E))),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _actionItem(
                Icons.assignment_turned_in_outlined,
                '3 IEP Reports Awaiting Approval',
                'Alex Thomas Sam, Matt Dickerson, Wade Warren',
                const Color(0xFFD97706),
              ),
              _actionItem(
                Icons.warning_amber_rounded,
                '1 Crisis ABC Incident Flagged',
                'Task refusal & elopement (Room B) • Clinician review needed',
                const Color(0xFFDC2626),
              ),
              _actionItem(
                Icons.supervisor_account_outlined,
                'BACB 5% Supervision Alert',
                'James Rodriguez (RBT) at 4.8% with 5 days remaining',
                AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String title, String subtitle, Color color) {
    return Builder(
      builder: (context) {
        final isMobile = MediaQuery.of(context).size.width < 768;
        return Container(
          width: isMobile ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), softWrap: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── KPI Stat Card ────────────────────────────────────────────────────────────
class _KpiStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;

  const _KpiStatCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtext, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clinical Operations Section ──────────────────────────────────────────────
class _ClinicalOperationsSection extends StatefulWidget {
  const _ClinicalOperationsSection();

  @override
  State<_ClinicalOperationsSection> createState() => _ClinicalOperationsSectionState();
}

class _ClinicalOperationsSectionState extends State<_ClinicalOperationsSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clinical Operations & Governance',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Text('Live Supervision Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    const Text('Clinical Operations & Governance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Live Supervision Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                );
              },
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            tabs: const [
              Tab(text: 'Pending IEP Approvals (3)'),
              Tab(text: 'BACB Clinician Supervision'),
              Tab(text: 'Center Domain Velocity'),
            ],
          ),
          const Divider(height: 1, color: AppColors.divider),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                _PendingIepsTab(),
                _ClinicianSupervisionTab(),
                _DomainVelocityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Pending IEPs ──────────────────────────────────────────────────────
class _PendingIepsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pendingList = [
      {'student': 'Alex Thomas Sam', 'age': '15', 'therapist': 'Dr. Sarah Lee (BCBA)', 'cycle': 'Annual 2026-2027', 'targets': '12 Targets', 'submitted': '18-08-2026'},
      {'student': 'Matt Dickerson', 'age': '14', 'therapist': 'James Rodriguez (RBT)', 'cycle': 'Q3 Behavioral Plan', 'targets': '8 Targets', 'submitted': '17-08-2026'},
      {'student': 'Wade Warren', 'age': '12', 'therapist': 'Dr. Sarah Lee (BCBA)', 'cycle': 'Annual 2026-2027', 'targets': '10 Targets', 'submitted': '16-08-2026'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 650,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pendingList.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (ctx, i) {
            final item = pendingList[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(item['student']!.substring(0, 1), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['student']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                        Text('Age: ${item['age']} yrs • Sub: ${item['submitted']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Therapist: ${item['therapist']!}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['cycle']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text(item['targets']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.statusPendingBg, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Pending Audit', style: TextStyle(color: AppColors.statusPending, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Tab 2: Clinician Supervision ─────────────────────────────────────────────
class _ClinicianSupervisionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final clinicians = [
      {'name': 'Dr. Sarah Lee', 'role': 'Lead BCBA', 'cases': '8 Cases', 'hours': '14.5 / 12 hrs', 'percent': 1.0, 'compliant': true},
      {'name': 'James Rodriguez', 'role': 'Registered Behavior Tech (RBT)', 'cases': '6 Cases', 'hours': '3.8 / 4.0 hrs', 'percent': 0.95, 'compliant': false},
      {'name': 'Emily Chen', 'role': 'BCBA Clinical Supervisor', 'cases': '5 Cases', 'hours': '11.0 / 8.0 hrs', 'percent': 1.0, 'compliant': true},
      {'name': 'Michael Chang', 'role': 'Senior Behavioral Therapist', 'cases': '5 Cases', 'hours': '8.2 / 8.0 hrs', 'percent': 1.0, 'compliant': true},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 650,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: clinicians.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (ctx, i) {
            final c = clinicians[i];
            final percent = c['percent'] as double;
            final compliant = c['compliant'] as bool;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                        Text(c['role'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(c['cases'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Supervision: ${c['hours']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text(compliant ? 'BACB Compliant' : 'Needs 0.2 hr', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: compliant ? Colors.green : Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent > 1.0 ? 1.0 : percent,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(compliant ? Colors.green : Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Tab 3: Domain Velocity ───────────────────────────────────────────────────
class _DomainVelocityTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final domains = [
      {'name': 'Manding (Speech/Requests)', 'percent': '88% Mastery', 'speed': '3.4 days / target'},
      {'name': 'Tacting (Labeling/Objects)', 'percent': '82% Mastery', 'speed': '3.7 days / target'},
      {'name': 'Listener Responding', 'percent': '78% Mastery', 'speed': '4.1 days / target'},
      {'name': 'Motor Imitation', 'percent': '85% Mastery', 'speed': '3.2 days / target'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: domains.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (ctx, i) {
        final d = domains[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(d['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                child: Text(d['percent']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF2E7D32))),
              ),
              Text('Acquisition speed: ${d['speed']!}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        );
      },
    );
  }
}

// ── Today's Center Operations & Live Therapist Timetable ────────────────────
class _DirectorLiveTimetableSection extends StatelessWidget {
  const _DirectorLiveTimetableSection();

  void _openScheduleDialog(BuildContext context, [String? therapistId]) {
    showDialog(
      context: context,
      builder: (ctx) => ScheduleTherapistSessionDialog(
        initialDate: DateTime.now(),
        preselectedTherapistId: therapistId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final todaySessions = scheduleService.getAllSessionsForDate(DateTime.now());

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
          // Section Header Row (Responsive)
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;
            return isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.people_alt_outlined, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Today's Center Operations & Therapist Timetable",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Real-time room occupancy & clinician session progress (${todaySessions.length} total sessions today)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openScheduleDialog(context),
                          icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
                          label: const Text(
                            '+ Schedule Session for Therapist',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 1,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.people_alt_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Center Operations & Therapist Timetable",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Real-time room occupancy & clinician session progress (${todaySessions.length} total sessions today)',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openScheduleDialog(context),
                        icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
                        label: const Text(
                          '+ Schedule Session for Therapist',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  );
          }),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // 6 Clinicians Live Status Grid
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : (constraints.maxWidth > 600 ? 2 : 1),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 182,
              ),
              itemCount: ScheduleService.centerTherapists.length,
              itemBuilder: (context, index) {
                final therapist = ScheduleService.centerTherapists[index];
                final sessions = todaySessions
                    .where((s) => s.therapistId == therapist['id'])
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));

                final activeSession = sessions.firstWhere(
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

                final hasLive = activeSession.id.isNotEmpty;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: hasLive ? const Color(0xFFFAFFFA) : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasLive ? const Color(0xFF4CAF50) : AppColors.divider,
                      width: hasLive ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar, Name, Status
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: hasLive ? const Color(0xFFE8F5E9) : AppColors.primaryLight,
                            child: Text(
                              therapist['name']!.substring(0, 1),
                              style: TextStyle(
                                color: hasLive ? const Color(0xFF2E7D32) : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  therapist['name']!,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${sessions.length} sessions today',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasLive ? const Color(0xFFE8F5E9) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hasLive ? '● LIVE' : 'FREE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: hasLive ? const Color(0xFF2E7D32) : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Current / Next Session Detail
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: hasLive
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'With: ${activeSession.studentName} (${activeSession.studentAge}y)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '📍 ${activeSession.room} (${activeSession.startTime})',
                                      style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      activeSession.programTitle,
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                )
                              : sessions.isNotEmpty
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Next: ${sessions.first.startTime} - ${sessions.first.studentName}',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Room: ${sessions.first.room}',
                                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    )
                                  : const Center(
                                      child: Text(
                                        'No sessions scheduled yet',
                                        style: TextStyle(fontSize: 11, color: AppColors.textHint),
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Bottom Quick Action: + Assign
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => _openScheduleDialog(context, therapist['id']),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 12, color: AppColors.primary),
                              SizedBox(width: 2),
                              Text(
                                'Assign Session',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

// ── Director's Executive Appointments (Scheduled by Admin) ──────────────────
class _DirectorExecutiveAppointmentsSection extends StatelessWidget {
  const _DirectorExecutiveAppointmentsSection();

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final todayAppointments = scheduleService.getDirectorAppointments(date: DateTime.now());

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
          // Header Row (Responsive)
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;
            return isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.event_available, color: Color(0xFF0284C7), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Director's Executive Appointments & Clinical Audits",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Parent diagnostic intakes & clinical case audits scheduled by the Admin office',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${todayAppointments.length} Appointments Today',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.event_available, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Director's Executive Appointments & Clinical Audits",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Parent diagnostic intakes & clinical case audits scheduled by the Admin office',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${todayAppointments.length} Appointments Today',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  );
          }),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          if (todayAppointments.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text(
                'No executive appointments scheduled for today. Admin books parent intakes and reviews here.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayAppointments.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final appt = todayAppointments[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      // Time badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              appt.startTime,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              appt.endTime,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Appointment Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 450;
                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appt.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Scheduled by ${appt.scheduledBy}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0369A1),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        appt.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Scheduled by ${appt.scheduledBy}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0369A1),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${appt.attendeeName} (${appt.attendeeRole})',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.room, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      appt.location,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (appt.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                appt.notes,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
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
}

// ── Executive Analytics & Caseload Intelligence Section (FRS 8) ──────────────
class _DirectorExecutiveAnalyticsSection extends StatelessWidget {
  const _DirectorExecutiveAnalyticsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Executive Analytics & Caseload Intelligence',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Therapist capacity, completion velocities, and security audit monitoring (FRS 8.0)',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Live Sync Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Caseload & Attendance Breakdown
          LayoutBuilder(builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;
            return isWide
                ? const Row(
                    children: [
                      Expanded(child: _CaseloadBar(name: 'Dr. Sarah Lee (Lead BCBA)', caseload: 8, maxCaseload: 10, color: AppColors.primary)),
                      SizedBox(width: 16),
                      Expanded(child: _CaseloadBar(name: 'Dr. Michael Chen (Senior Analyst)', caseload: 9, maxCaseload: 10, color: Color(0xFF3B82F6))),
                      SizedBox(width: 16),
                      Expanded(child: _CaseloadBar(name: 'Priya Sharma (RBT Specialist)', caseload: 6, maxCaseload: 8, color: Color(0xFF10B981))),
                    ],
                  )
                : const Column(
                    children: [
                      _CaseloadBar(name: 'Dr. Sarah Lee (Lead BCBA)', caseload: 8, maxCaseload: 10, color: AppColors.primary),
                      SizedBox(height: 12),
                      _CaseloadBar(name: 'Dr. Michael Chen (Senior Analyst)', caseload: 9, maxCaseload: 10, color: Color(0xFF3B82F6)),
                      SizedBox(height: 12),
                      _CaseloadBar(name: 'Priya Sharma (RBT Specialist)', caseload: 6, maxCaseload: 8, color: Color(0xFF10B981)),
                    ],
                  );
          }),
        ],
      ),
    );
  }
}

class _CaseloadBar extends StatelessWidget {
  final String name;
  final int caseload;
  final int maxCaseload;
  final Color color;

  const _CaseloadBar({
    required this.name,
    required this.caseload,
    required this.maxCaseload,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (caseload / maxCaseload).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$caseload / $maxCaseload Students', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              Text('${(ratio * 100).toInt()}% Capacity', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}



