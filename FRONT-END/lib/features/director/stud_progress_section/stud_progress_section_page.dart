// lib/features/director/stud_progress_section/stud_progress_section_page.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';

class StagnationAlert {
  final String id;
  final String studentName;
  final String domain;
  final String targetDescription;
  final String therapistName;
  final int daysStagnant;
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
  State<StudProgressSectionPage> createState() => _StudProgressSectionPageState();
}

class _StudProgressSectionPageState extends State<StudProgressSectionPage> {
  int _selectedViewTab = 0; // 0: Overview & Domains, 1: VB-MAPP Cohort Heatmap, 2: Stagnation Alerts

  final List<StagnationAlert> _alerts = [
    StagnationAlert(
      id: 'STAG-01',
      studentName: 'Alex Thomas Sam',
      domain: 'Echoic (Vocal)',
      targetDescription: 'Target 8M: Repeats 3-syllable phrases with distinct consonant sounds.',
      therapistName: 'Dr. Sarah Lee (BCBA)',
      daysStagnant: 24,
      trend: 'Flat (0% change)',
    ),
    StagnationAlert(
      id: 'STAG-02',
      studentName: 'Matt Dickerson',
      domain: 'Tacting (Labeling)',
      targetDescription: 'Target 11M: Tacts 4 different prepositional relationships (in, on, under).',
      therapistName: 'James Rodriguez (RBT)',
      daysStagnant: 21,
      trend: '-15% Regression',
    ),
    StagnationAlert(
      id: 'STAG-03',
      studentName: 'Cameron Williamson',
      domain: 'Social Behavior',
      targetDescription: 'Target 9M: Spontaneously initiates peer play in naturalistic setting.',
      therapistName: 'James Rodriguez (RBT)',
      daysStagnant: 26,
      trend: 'Flat (12% prompt dep)',
    ),
    StagnationAlert(
      id: 'STAG-04',
      studentName: 'Brooklyn Simmons',
      domain: 'Manding (Requests)',
      targetDescription: 'Target 7M: Mands for actions using 2-word carrier phrases ("push swing").',
      therapistName: 'Emily Chen (BCBA)',
      daysStagnant: 22,
      trend: '-10% Prompt drift',
    ),
  ];

  void _scheduleReview(StagnationAlert alert) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Text('Schedule Clinical Review: ${alert.studentName}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assigned Clinician: ${alert.therapistName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Text('Stagnant Target: ${alert.targetDescription}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
              child: Text(
                'Alert: Target has not progressed for ${alert.daysStagnant} days (${alert.trend}). A protocol modification or prompt hierarchy shift is recommended.',
                style: const TextStyle(fontSize: 12, color: Color(0xFFB76E00), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                alert.reviewScheduled = true;
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Clinical protocol review meeting scheduled with ${alert.therapistName}!'),
                  backgroundColor: AppColors.statusActive,
                ),
              );
            },
            child: const Text('Confirm Review Meeting', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unresolvedCount = _alerts.where((a) => !a.reviewScheduled).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
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
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Aggregate developmental milestones, domain mastery velocities, and stagnation alerts across all enrolled students.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              );

              final exportBtn = OutlinedButton.icon(
                icon: const Icon(Icons.file_download_outlined, color: AppColors.primary, size: 16),
                label: const Text('Export Clinical Report', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting center-wide clinical progress report...')),
                  );
                },
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
                childAspectRatio: crossAxisCount == 1 ? 3.6 : (crossAxisCount == 2 ? 2.5 : 1.7),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildProgressKpiItem('Mastery Velocity', '248 Targets', '+18.4% vs Q2', Icons.trending_up, Colors.green),
                  _buildProgressKpiItem('Avg Acquisition Speed', '3.8 Days', 'per discrete skill target', Icons.speed_outlined, Colors.purple),
                  _buildProgressKpiItem('VB-MAPP Milestone Rate', '74.2%', 'Center-wide average', Icons.military_tech_outlined, Colors.blue),
                  _buildProgressKpiItem('Stagnation Alerts', '$unresolvedCount Flags', 'Targets >21d flat', Icons.warning_amber_rounded, Colors.orange),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // View Switcher Tabs (Scrollable on small screens)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildViewTab(0, 'Domain Mastery Trends', Icons.bar_chart),
                const SizedBox(width: 10),
                _buildViewTab(1, 'VB-MAPP Cohort Heatmap', Icons.grid_view),
                const SizedBox(width: 10),
                _buildViewTab(2, 'Stagnation Alerts ($unresolvedCount)', Icons.notification_important_outlined),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Content Area based on tab
          if (_selectedViewTab == 0) _buildDomainMasterySection(),
          if (_selectedViewTab == 1) _buildVbMappCohortHeatmapSection(),
          if (_selectedViewTab == 2) _buildStagnationAlertsSection(),
        ],
      ),
    );
  }

  Widget _buildProgressKpiItem(String label, String value, String subtext, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
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
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtext, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
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
    final domains = [
      {'name': 'Manding (Expressive Requests)', 'rate': 0.88, 'count': '420 / 477 targets mastered', 'color': const Color(0xFF7B2FBE)},
      {'name': 'Tacting (Labeling & Vocabulary)', 'rate': 0.82, 'count': '390 / 475 targets mastered', 'color': const Color(0xFF4A89DC)},
      {'name': 'Listener Responding (Receptive Language)', 'rate': 0.78, 'count': '320 / 410 targets mastered', 'color': const Color(0xFF00BCD4)},
      {'name': 'Motor Imitation (Fine & Gross)', 'rate': 0.85, 'count': '340 / 400 targets mastered', 'color': const Color(0xFF4CAF50)},
      {'name': 'Echoic (Vocal Imitation & Clarity)', 'rate': 0.71, 'count': '285 / 400 targets mastered', 'color': const Color(0xFFFF9800)},
      {'name': 'Social Behavior & Naturalistic Play', 'rate': 0.65, 'count': '260 / 400 targets mastered', 'color': const Color(0xFFE53935)},
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final standardChip = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Mastery Standard: 80% with 2 Clinicians', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Center-Wide Clinical Domain Velocity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    standardChip,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Center-Wide Clinical Domain Velocity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  standardChip,
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          ...domains.map((d) {
            final rate = d['rate'] as double;
            final color = d['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(d['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                      const SizedBox(width: 8),
                      Text('${(rate * 100).toInt()}% • ${d['count']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: rate,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Tab 1: VB-MAPP Cohort Heatmap ──────────────────────────────────────────
  Widget _buildVbMappCohortHeatmapSection() {
    final cohortData = [
      {
        'cohort': 'Level 1 Cohort (0 - 18 Months)',
        'students': '8 Students enrolled',
        'scores': [
          {'domain': 'Mand', 'score': 92},
          {'domain': 'Tact', 'score': 84},
          {'domain': 'Listener', 'score': 88},
          {'domain': 'Visual Perc.', 'score': 90},
          {'domain': 'Indep. Play', 'score': 80},
          {'domain': 'Social', 'score': 74},
          {'domain': 'Motor Imitation', 'score': 86},
          {'domain': 'Echoic', 'score': 78},
        ],
      },
      {
        'cohort': 'Level 2 Cohort (18 - 30 Months)',
        'students': '11 Students enrolled',
        'scores': [
          {'domain': 'Mand', 'score': 80},
          {'domain': 'Tact', 'score': 76},
          {'domain': 'Listener', 'score': 72},
          {'domain': 'Visual Perc.', 'score': 82},
          {'domain': 'Play', 'score': 68},
          {'domain': 'Social', 'score': 62},
          {'domain': 'Motor Imitation', 'score': 75},
          {'domain': 'Echoic', 'score': 69},
          {'domain': 'Intraverbal', 'score': 58},
          {'domain': 'Classroom', 'score': 64},
        ],
      },
      {
        'cohort': 'Level 3 Cohort (30 - 48 Months)',
        'students': '5 Students enrolled',
        'scores': [
          {'domain': 'Mand', 'score': 65},
          {'domain': 'Tact', 'score': 68},
          {'domain': 'Listener', 'score': 62},
          {'domain': 'Visual Perc.', 'score': 72},
          {'domain': 'Social', 'score': 54},
          {'domain': 'Reading', 'score': 48},
          {'domain': 'Writing', 'score': 42},
          {'domain': 'Math', 'score': 38},
          {'domain': 'Intraverbal', 'score': 52},
        ],
      },
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final legendWrap = Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _legendPill('>80% High Mastery', const Color(0xFF4CAF50)),
                  _legendPill('60-80% Moderate', const Color(0xFF00BCD4)),
                  _legendPill('40-60% Developing', const Color(0xFFFF9800)),
                  _legendPill('<40% Intensive Need', const Color(0xFFE53935)),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VB-MAPP Milestone Cohort Heatmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                    legendWrap,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('VB-MAPP Milestone Cohort Heatmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  legendWrap,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          ...cohortData.map((cohort) {
            final scores = cohort['scores'] as List<Map<String, dynamic>>;
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cohort['cohort'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Text(cohort['students'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: scores.map((s) {
                      final score = s['score'] as int;
                      Color bg;
                      Color fg;
                      if (score >= 80) {
                        bg = const Color(0xFFE8F5E9);
                        fg = const Color(0xFF2E7D32);
                      } else if (score >= 60) {
                        bg = const Color(0xFFE0F7FA);
                        fg = const Color(0xFF00838F);
                      } else if (score >= 40) {
                        bg = const Color(0xFFFFF3E0);
                        fg = const Color(0xFFE65100);
                      } else {
                        bg = const Color(0xFFFFEBEE);
                        fg = const Color(0xFFC62828);
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            Text(s['domain'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
                            const SizedBox(height: 2),
                            Text('$score%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: fg)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _legendPill(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
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
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFC2410C), size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Clinical Stagnation & Regression Sentinel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF7C2D12))),
                      Text('Flagged when a student has zero mastery acquisition over 21 consecutive days or registers >15% prompt dependency regression.', style: TextStyle(fontSize: 12, color: Color(0xFF9A3412))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _alerts.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
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
                                  color: a.reviewScheduled ? AppColors.statusActiveBg : AppColors.statusPendingBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  a.reviewScheduled ? Icons.check_circle_outline : Icons.flag_outlined,
                                  color: a.reviewScheduled ? AppColors.statusActive : AppColors.statusPending,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                                    Text('Therapist: ${a.therapistName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.statusDeactivatedBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${a.daysStagnant}d Stagnant', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.statusDeactivated)),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(a.domain, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ),
                                const SizedBox(height: 4),
                                Text(a.targetDescription, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text(a.trend, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: a.reviewScheduled ? Colors.grey.shade200 : AppColors.primary,
                                foregroundColor: a.reviewScheduled ? AppColors.textSecondary : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: a.reviewScheduled ? null : () => _scheduleReview(a),
                              child: Text(
                                a.reviewScheduled ? 'Review Set' : 'Schedule Review',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                            color: a.reviewScheduled ? AppColors.statusActiveBg : AppColors.statusPendingBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            a.reviewScheduled ? Icons.check_circle_outline : Icons.flag_outlined,
                            color: a.reviewScheduled ? AppColors.statusActive : AppColors.statusPending,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                              Text('Therapist: ${a.therapistName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(a.domain, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                              const SizedBox(height: 4),
                              Text(a.targetDescription, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${a.daysStagnant} Days Inactive', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.statusDeactivated)),
                              Text(a.trend, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: a.reviewScheduled ? Colors.grey.shade200 : AppColors.primary,
                            foregroundColor: a.reviewScheduled ? AppColors.textSecondary : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: a.reviewScheduled ? null : () => _scheduleReview(a),
                          child: Text(
                            a.reviewScheduled ? 'Review Set' : 'Schedule Review',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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

