// lib/features/director/stud_progress_section/stud_progress_section_page.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/services/governance_settings.dart';
import 'package:roh_erp/core/services/progress_metrics.dart';
import 'package:roh_erp/core/services/report_pdf.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import 'package:roh_erp/core/widgets/edit_record_dialogs.dart';
import 'package:roh_erp/features/shared_progress/progress_data.dart';
import 'package:roh_erp/features/shared_progress/student_progress_table.dart';

class StagnationAlert {
  final String id;
  final String studentName;
  final String domain;
  final String targetDescription;
  final String therapistName;

  /// Days since the target last improved (last session whose success %
  /// beat every earlier session). Shown as "No recent progress".
  final int daysStagnant;

  /// Success % of the most recent session, e.g. "Last session: 60%".
  final String trend;
  bool reviewScheduled;

  StagnationAlert({
    required this.id,
    required this.studentName,
    required this.domain,
    required this.targetDescription,
    required this.therapistName,
    required this.daysStagnant,
    required this.trend,
    this.reviewScheduled = false,
  });
}

class StudProgressSectionPage extends StatefulWidget {
  const StudProgressSectionPage({super.key});

  @override
  State<StudProgressSectionPage> createState() =>
      _StudProgressSectionPageState();
}

class _StudProgressSectionPageState extends State<StudProgressSectionPage> {
  int _selectedViewTab =
      0; // 0: Overview & Domains, 1: VB-MAPP Cohort Heatmap, 2: Targets needing review
  final List<StagnationAlert> _alerts = [];
  final Set<String> _scheduledReviewIds = {};
  ProgressData? _data;
  bool _isLoading = true;

  /// A target is flagged when it has not improved for this many days, is
  /// still being run within this window and has not been mastered. Comes
  /// from the director's governance settings (default 21).
  int get _stagnationDays => GovernanceSettings.current.stagnationDays;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Title of the director appointment booked for a progress review; also
  /// used to recognise alerts that already have a review on the calendar.
  static String _reviewTitle(StagnationAlert a) =>
      'Progress review: ${a.studentName} (${a.targetDescription})';

  /// Title used before the wording change, so reviews booked earlier are
  /// still recognised.
  static String _legacyReviewTitle(StagnationAlert a) =>
      'Stagnation review: ${a.studentName} (${a.targetDescription})';

  Future<void> _loadData() async {
    final results = await Future.wait([
      ProgressData.load(),
      ApiService().get('get_director_appointments'),
    ]);
    final data = results[0] as ProgressData;
    final appts = results[1];
    if (!mounted) return;
    for (final a in _alerts) {
      if (a.reviewScheduled) _scheduledReviewIds.add(a.id);
    }
    final bookedTitles = <String>{
      if (appts is List)
        for (final r in appts)
          if (r is Map && (r['status'] ?? '').toString() != 'cancelled')
            (r['title'] ?? '').toString(),
    };
    setState(() {
      _data = data;
      _alerts
        ..clear()
        ..addAll(_buildAlerts(data));
      for (final a in _alerts) {
        if (bookedTitles.contains(_reviewTitle(a)) ||
            bookedTitles.contains(_legacyReviewTitle(a))) {
          a.reviewScheduled = true;
        }
      }
      _isLoading = false;
    });
  }

  List<StagnationAlert> _buildAlerts(ProgressData data) {
    final day = today();
    final cutoff = day.subtract(Duration(days: _stagnationDays));
    final alerts = <StagnationAlert>[];
    for (final t in data.targets) {
      final improved = t.lastImproved ?? t.firstSession;
      if (t.mastered || improved == null || t.lastSession == null) {
        continue;
      }
      // Still being run, but no new best score within the window.
      if (!improved.isBefore(cutoff) || t.lastSession!.isBefore(cutoff)) {
        continue;
      }
      final id =
          '${t.studentId}|${t.domain.toLowerCase()}|${t.target.toLowerCase()}';
      alerts.add(StagnationAlert(
        id: id,
        studentName: data.studentNames[t.studentId] ?? t.studentName,
        domain: t.domain.isEmpty ? 'General' : t.domain,
        targetDescription: t.target.isEmpty ? 'Unnamed target' : t.target,
        therapistName: t.therapistName.isEmpty ? 'Unassigned' : t.therapistName,
        daysStagnant: day.difference(improved).inDays,
        trend: 'Last session: ${(t.lastSuccessRatio * 100).round()}%',
        reviewScheduled: _scheduledReviewIds.contains(id),
      ));
    }
    alerts.sort((a, b) => b.daysStagnant.compareTo(a.daysStagnant));
    return alerts;
  }

  // ── KPI helpers ──────────────────────────────────────────────────────────
  int get _masteredLast30 {
    final since = today().subtract(const Duration(days: 30));
    return (_data?.targets ?? const [])
        .where((t) => t.masteredOn != null && !t.masteredOn!.isBefore(since))
        .length;
  }

  double? get _avgDaysToMastery {
    final days = (_data?.targets ?? const [])
        .map((t) => t.daysToMastery)
        .whereType<int>()
        .toList();
    if (days.isEmpty) return null;
    return days.reduce((a, b) => a + b) / days.length;
  }

  /// Average latest VB-MAPP milestone total across students (out of 170).
  /// Students are at different levels, so this is a raw average, not a
  /// percentage of each student's level.
  ({double avg, int students})? get _milestoneRate {
    final latest = _data?.latestMilestoneByStudent.values.toList() ?? const [];
    if (latest.isEmpty) return null;
    final sum =
        latest.map((m) => numValue(m['total_score'])).reduce((a, b) => a + b);
    return (avg: sum / latest.length, students: latest.length);
  }

  void _scheduleReview(StagnationAlert alert) {
    DateTime date = DateTime.now().add(const Duration(days: 1));
    String slot = ScheduleService.standardTimeSlots.first;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      Text('Schedule Clinical Review: ${alert.studentName}')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assigned Clinician: ${alert.therapistName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Text('Target: ${alert.targetDescription}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'No recent progress: this target has not improved for ${alert.daysStagnant} days and is not yet mastered (${alert.trend}). Consider reviewing the teaching plan with the therapist.',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB76E00),
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event, size: 16),
                  label: Text(
                      'Date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
                  onPressed: saving
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: date,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => date = picked);
                          }
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: slot,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Time slot',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ScheduleService.standardTimeSlots
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: saving
                      ? null
                      : (v) {
                          if (v != null) setDialogState(() => slot = v);
                        },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      final times = slot.split(' - ');
                      final res =
                          await ApiService().post('save_director_appointment', {
                        'title': _reviewTitle(alert),
                        'appointment_type': 'staffConsultation',
                        'date':
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                        'start_time': times.first,
                        'end_time': times.length > 1 ? times[1] : times.first,
                        'attendee_name': alert.therapistName,
                        'attendee_role': 'Therapist',
                        'notes':
                            '${alert.domain} target "${alert.targetDescription}" — no recent progress for ${alert.daysStagnant} days, not yet mastered (${alert.trend}).',
                      });
                      if (!mounted) return;
                      final ok = showApiResult(context, res,
                          'Clinical protocol review meeting scheduled with ${alert.therapistName}!');
                      if (ok) {
                        setState(() {
                          alert.reviewScheduled = true;
                          _scheduledReviewIds.add(alert.id);
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      } else {
                        setDialogState(() => saving = false);
                      }
                    },
              child: const Text('Confirm Review Meeting',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportReport() async {
    final data = _data;
    if (data == null || !data.hasAnyData) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No progress data to export yet.')));
      return;
    }
    final milestoneRate = _milestoneRate;
    final avg = _avgDaysToMastery;

    // Domain mastery (same grouping as the Domain Mastery tab).
    final names = <String, String>{};
    final introduced = <String, int>{};
    final mastered = <String, int>{};
    for (final t in data.targets) {
      final label = t.domain.trim().isEmpty ? 'General' : t.domain.trim();
      final key = label.toLowerCase();
      names.putIfAbsent(key, () => label);
      introduced[key] = (introduced[key] ?? 0) + 1;
      if (t.mastered) mastered[key] = (mastered[key] ?? 0) + 1;
    }
    final domainKeys = introduced.keys.toList()
      ..sort((x, y) => introduced[y]!.compareTo(introduced[x]!));

    await ReportPdf.share(
      title: 'Center-Wide Student Progress Report',
      subtitle: '${data.studentNames.length} students',
      fileName: 'student_progress_report.pdf',
      sections: [
        ReportSection('Key Indicators', columns: const [
          'Indicator',
          'Value'
        ], rows: [
          ['Targets mastered (last 30 days)', '$_masteredLast30'],
          ['Avg days to mastery', avg == null ? '—' : avg.toStringAsFixed(1)],
          [
            'Average milestones achieved (of 170)',
            milestoneRate == null
                ? '—'
                : '${milestoneRate.avg.toStringAsFixed(1)} (${milestoneRate.students} students)'
          ],
          [
            'Targets needing review (open)',
            '${_alerts.where((a) => !a.reviewScheduled).length}'
          ],
        ]),
        if (domainKeys.isNotEmpty)
          ReportSection('Targets Mastered by Domain', columns: const [
            'Domain',
            'Mastered',
            'Introduced',
            'Rate'
          ], rows: [
            for (final k in domainKeys)
              [
                names[k]!,
                '${mastered[k] ?? 0}',
                '${introduced[k]}',
                '${((mastered[k] ?? 0) / introduced[k]! * 100).round()}%',
              ],
          ]),
        ReportSection('Student Progress', columns: const [
          'Student',
          'Targets mastered',
          'Sessions (30d)',
          'Success (30d)',
          'Latest VB-MAPP'
        ], rows: [
          for (final r in data.studentRows())
            [
              r.name,
              '${r.targetsMastered}',
              '${r.sessions30d}',
              r.successPct30d == null
                  ? '—'
                  : '${r.successPct30d!.toStringAsFixed(0)}%',
              StudentProgressTable.milestoneText(r.latestMilestone),
            ],
        ]),
        if (_alerts.isNotEmpty)
          ReportSection('Targets Needing Review', columns: const [
            'Student',
            'Domain',
            'Target',
            'Therapist',
            'Days without progress',
            'Review'
          ], rows: [
            for (final a in _alerts)
              [
                a.studentName,
                a.domain,
                a.targetDescription,
                a.therapistName,
                '${a.daysStagnant}',
                a.reviewScheduled ? 'Scheduled' : 'Open',
              ],
          ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final unresolvedCount = _alerts.where((a) => !a.reviewScheduled).length;
    final milestoneRate = _milestoneRate;

    return SingleChildScrollView(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final titleColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Center-Wide Macro Student Progress & Clinical Analytics',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Developmental milestones, targets mastered by domain, and targets needing review across all enrolled students.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              );

              final exportBtn = OutlinedButton.icon(
                icon: const Icon(Icons.file_download_outlined,
                    color: AppColors.primary, size: 16),
                label: const Text('Export Clinical Report',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _exportReport,
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleColumn,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: exportBtn),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: titleColumn),
                  const SizedBox(width: 16),
                  exportBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 4 Executive KPI Cards (Responsive 1/2/4 Grid)
          LayoutBuilder(
            builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              final crossAxisCount = w < 520 ? 1 : (w < 950 ? 2 : 4);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: crossAxisCount == 1
                    ? 3.6
                    : (crossAxisCount == 2 ? 2.5 : 1.7),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildProgressKpiItem(
                      'Targets mastered (30 days)',
                      _isLoading ? '…' : '$_masteredLast30 Targets',
                      'mastery: $masteryRuleText',
                      Icons.trending_up,
                      Colors.green),
                  _buildProgressKpiItem(
                      'Avg Acquisition Speed',
                      _avgDaysToMastery == null
                          ? '—'
                          : '${_avgDaysToMastery!.toStringAsFixed(1)} Days',
                      'first session to mastery',
                      Icons.speed_outlined,
                      Colors.purple),
                  _buildProgressKpiItem(
                      'Average milestones achieved (of 170)',
                      milestoneRate == null
                          ? '—'
                          : '${milestoneRate.avg.toStringAsFixed(1)} / 170',
                      milestoneRate == null
                          ? 'No milestone tests yet'
                          : 'Latest test, ${milestoneRate.students} students at mixed levels',
                      Icons.military_tech_outlined,
                      Colors.blue),
                  _buildProgressKpiItem(
                      'Targets needing review',
                      '$unresolvedCount Flags',
                      unresolvedCount > 0
                          ? 'No recent progress for >$_stagnationDays days'
                          : 'No targets need review',
                      Icons.warning_amber_rounded,
                      Colors.orange),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // View Switcher Tabs (Scrollable on small screens)
          // Wraps onto extra lines on narrow screens.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildViewTab(0, 'Domain Mastery Trends', Icons.bar_chart),
              _buildViewTab(1, 'VB-MAPP Cohort Heatmap', Icons.grid_view),
              _buildViewTab(2, 'Targets Needing Review ($unresolvedCount)',
                  Icons.notification_important_outlined),
            ],
          ),
          const SizedBox(height: 18),

          // Content Area based on tab
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (_selectedViewTab == 0) _buildDomainMasterySection(),
            if (_selectedViewTab == 1) _buildVbMappCohortHeatmapSection(),
            if (_selectedViewTab == 2) _buildStagnationAlertsSection(),
            if (_data?.hasAnyData ?? false) ...[
              const SizedBox(height: 24),
              StudentProgressTable(rows: _data!.studentRows()),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildProgressKpiItem(
      String label, String value, String subtext, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: TextStyle(
                      fontSize: 11, color: color, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab(int index, String label, IconData icon) {
    final isSelected = _selectedViewTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedViewTab = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 0: Domain Mastery ──────────────────────────────────────────────────
  Widget _buildDomainMasterySection() {
    final targets = _data?.targets ?? const [];
    if (targets.isEmpty) {
      return const ProgressEmptyState(
        icon: Icons.insights_outlined,
        title: 'No Clinical Domain Data Available',
        message:
            'Domain mastery will calculate and display here once therapists log discrete trial data sheets for students.',
      );
    }

    // Group targets by domain (case-insensitive), keeping the first spelling.
    final names = <String, String>{};
    final introduced = <String, int>{};
    final mastered = <String, int>{};
    for (final t in targets) {
      final label = t.domain.trim().isEmpty ? 'General' : t.domain.trim();
      final key = label.toLowerCase();
      names.putIfAbsent(key, () => label);
      introduced[key] = (introduced[key] ?? 0) + 1;
      if (t.mastered) mastered[key] = (mastered[key] ?? 0) + 1;
    }
    final keys = introduced.keys.toList()
      ..sort((x, y) => introduced[y]!.compareTo(introduced[x]!));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Targets Mastered by Domain',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            'Mastered / introduced skill targets across ${_data!.studentNames.length} students, from daily data sheets.',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          for (final k in keys) ...[
            _buildDomainBar(names[k]!, mastered[k] ?? 0, introduced[k]!),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildDomainBar(String domain, int mastered, int introduced) {
    final ratio = introduced == 0 ? 0.0 : mastered / introduced;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(domain,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text('$mastered / $introduced (${(ratio * 100).round()}%)',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  // ── Tab 1: VB-MAPP Cohort Heatmap ──────────────────────────────────────────
  Widget _buildVbMappCohortHeatmapSection() {
    final data = _data;
    final latest = data?.latestMilestoneByStudent ?? const {};
    if (data == null || latest.isEmpty) {
      return const ProgressEmptyState(
        icon: Icons.grid_view_outlined,
        title: 'No Cohort Assessment Heatmap Data',
        message:
            'The VB-MAPP cohort heatmap will render here once milestone scoring forms are completed by clinical staff.',
      );
    }

    final rows = latest.entries.toList()
      ..sort((x, y) => (data.studentNames[x.key] ?? '')
          .toLowerCase()
          .compareTo((data.studentNames[y.key] ?? '').toLowerCase()));

    const nameWidth = 150.0;
    const cellWidth = 64.0;
    const headerStyle = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary);

    Widget cell(double score, double max) {
      final t = (score / max).clamp(0.0, 1.0);
      return Container(
        width: cellWidth - 4,
        height: 34,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06 + 0.84 * t),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          formatScore(score),
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: t >= 0.5 ? Colors.white : AppColors.textPrimary),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VB-MAPP Milestone Scores by Domain',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text(
            'Each student\'s latest milestone test. Shading is relative to each domain\'s maximum (5 per VB-MAPP level the domain appears in: Mand, Tact, Listener, VP/MTS, Play, Social out of 15; Imitation, Echoic, LRFFC, Intraverbal, Group, Linguistics out of 10; Vocal, Reading, Writing, Math out of 5). Darker = closer to the maximum.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                        width: nameWidth,
                        child: Text('STUDENT', style: headerStyle)),
                    for (final d in vbMappDomains)
                      SizedBox(
                        width: cellWidth,
                        child: Text('${d.label}\n/${formatScore(d.max)}',
                            textAlign: TextAlign.center,
                            style: headerStyle,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final e in rows)
                  Row(
                    children: [
                      SizedBox(
                        width: nameWidth,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.studentNames[e.key] ?? 'Student',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  StudentProgressTable.milestoneDetail(e.value),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                      for (final d in vbMappDomains)
                        SizedBox(
                          width: cellWidth,
                          child: cell(numValue(e.value[d.key]), d.max),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Stagnation Alerts ───────────────────────────────────────────────
  Widget _buildStagnationAlertsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7ED),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFC2410C), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Targets Needing Review',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF7C2D12))),
                      Text(
                          'Flagged when a target is still being run, is not yet mastered and has shown no recent progress (no new best session score) for more than $_stagnationDays days. Mastery: $masteryRuleText.',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9A3412))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No targets need review right now.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _alerts.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (ctx, i) {
              final a = _alerts[i];
              return Padding(
                padding: const EdgeInsets.all(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;

                    if (isNarrow) {
                      // Responsive stacked layout for mobile
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: a.reviewScheduled
                                      ? AppColors.statusActiveBg
                                      : AppColors.statusPendingBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  a.reviewScheduled
                                      ? Icons.check_circle_outline
                                      : Icons.flag_outlined,
                                  color: a.reviewScheduled
                                      ? AppColors.statusActive
                                      : AppColors.statusPending,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.studentName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.textPrimary)),
                                    Text('Therapist: ${a.therapistName}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.statusDeactivatedBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${a.daysStagnant}d no progress',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: AppColors.statusDeactivated)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F7FB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(a.domain,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary)),
                                ),
                                const SizedBox(height: 4),
                                Text(a.targetDescription,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text(a.trend,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: a.reviewScheduled
                                    ? Colors.grey.shade200
                                    : AppColors.primary,
                                foregroundColor: a.reviewScheduled
                                    ? AppColors.textSecondary
                                    : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: a.reviewScheduled
                                  ? null
                                  : () => _scheduleReview(a),
                              child: Text(
                                a.reviewScheduled
                                    ? 'Review Set'
                                    : 'Schedule Review',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // Desktop row
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: a.reviewScheduled
                                ? AppColors.statusActiveBg
                                : AppColors.statusPendingBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            a.reviewScheduled
                                ? Icons.check_circle_outline
                                : Icons.flag_outlined,
                            color: a.reviewScheduled
                                ? AppColors.statusActive
                                : AppColors.statusPending,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.studentName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary)),
                              Text('Therapist: ${a.therapistName}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text(a.domain,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary)),
                              ),
                              const SizedBox(height: 4),
                              Text(a.targetDescription,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No recent progress: ${a.daysStagnant} days',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.statusDeactivated)),
                              Text(a.trend,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: a.reviewScheduled
                                ? Colors.grey.shade200
                                : AppColors.primary,
                            foregroundColor: a.reviewScheduled
                                ? AppColors.textSecondary
                                : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: a.reviewScheduled
                              ? null
                              : () => _scheduleReview(a),
                          child: Text(
                            a.reviewScheduled
                                ? 'Review Set'
                                : 'Schedule Review',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
