import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/db_queries.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';
import '../../../core/services/vbmapp_protocol_content.dart';
import 'assessment_records.dart';
import 'milestone_matrix.dart';
import 'vbmapp_charts.dart';

class VbMappReportPage extends StatefulWidget {
  const VbMappReportPage({super.key});

  @override
  State<VbMappReportPage> createState() => _VbMappReportPageState();
}

class _VbMappReportPageState extends State<VbMappReportPage> {
  String? _selectedStudent;
  bool _isBarrierMode = false;
  int _activeMilestoneLevel = 1; // 1, 2, or 3
  int? _selectedStudentId;
  List<Map<String, dynamic>> _milestoneRecords = [];
  List<Map<String, dynamic>> _barrierRecords = [];
  List<Map<String, dynamic>> _transitionRecords = [];
  List<Map<String, dynamic>> _eesaRecords = [];

  Future<void> _loadMilestoneData() async {
    final studentId = _selectedStudentId;
    if (studentId == null) return;
    final results = await Future.wait([
      MilestoneAssessmentQueries.fetchForStudent('$studentId'),
      BarriersAssessmentQueries.fetchForStudent('$studentId'),
      TransitionAssessmentQueries.fetchForStudent('$studentId'),
      EesaAssessmentQueries.fetchForStudent('$studentId'),
    ]);
    if (!mounted) return;
    setState(() {
      _milestoneRecords = results[0];
      _barrierRecords = results[1];
      _transitionRecords = results[2];
      _eesaRecords = results[3];
    });
  }

  /// Sum of the item scores of each test (null = test not saved).
  Map<int, double?> _itemTotals(
      List<Map<String, dynamic>> records, String column) {
    final perTest = scoresPerTest(records, column);
    return {
      for (int t = 1; t <= 4; t++)
        t: (perTest[t]?.isNotEmpty ?? false)
            ? perTest[t]!.values.fold<int>(0, (a, b) => a + b).toDouble()
            : null,
    };
  }

  /// A saved numeric column of each test's newest record (null = not saved).
  Map<int, double?> _columnPerTest(
      List<Map<String, dynamic>> records, String column) {
    return {
      for (int t = 1; t <= 4; t++)
        t: () {
          final r = newestRecordForTest(records, t);
          return r == null
              ? null
              : double.tryParse(r[column]?.toString() ?? '');
        }(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStudent == null) {
      return StudentCardGrid(
        title: _isBarrierMode
            ? 'Students VB MAPP Barriers Master Scoring Form'
            : 'Students VB MAPP Milestones Master Scoring Form',
        buttonLabel: 'View',
        extraTopRightWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Barrier',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _isBarrierMode,
              activeThumbColor: AppColors.primary,
              onChanged: (val) {
                setState(() {
                  _isBarrierMode = val;
                });
              },
            ),
          ],
        ),
        onStudentAction: (student, studentId) {
          setState(() {
            _selectedStudent = student;
            _selectedStudentId = studentId;
            _milestoneRecords = [];
            _barrierRecords = [];
            _transitionRecords = [];
            _eesaRecords = [];
          });
          _loadMilestoneData();
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Switch & Back Button — title wraps to 2 lines and
          // the Barrier switch drops below it when the content area is narrow.
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              final titleRow = Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: AppColors.primary),
                    onPressed: () => setState(() => _selectedStudent = null),
                    tooltip: 'Back to students',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isBarrierMode
                          ? 'Students VB MAPP Barriers Master Scoring Form'
                          : 'Students VB MAPP Milestones Master Scoring Form',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              );
              final barrierSwitch = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Barrier',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _isBarrierMode,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isBarrierMode = val;
                      });
                    },
                  ),
                ],
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: barrierSwitch,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 16),
                  barrierSwitch,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Student Assessment Banner
          StudentAssessmentBanner(
            studentName: _selectedStudent!,
            records: _isBarrierMode ? _barrierRecords : _milestoneRecords,
          ),
          const SizedBox(height: 24),

          // Render Either Barriers Master Scoring Grid OR Milestones Master Scoring Chart
          if (_isBarrierMode) ...[
            TestTotalsChart(
              title: 'Barriers total score per test',
              subtitle: 'Sum of the scored barriers (24 barriers, max 96; '
                  'lower is better).',
              totals: _itemTotals(_barrierRecords, 'barrier_scores'),
              maxScore: vbBarriersMaxScore.toDouble(),
            ),
            const SizedBox(height: 20),
            _buildBarriersMasterForm(),
          ] else
            _buildMilestonesMasterForm(),
          const SizedBox(height: 24),
          _buildSummary(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── MILESTONES MASTER SCORING FORM ──
  Widget _buildMilestonesMasterForm() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE), // Soft purple container
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 20),
      child: Column(
        children: [
          // Level Tabs: Level 1 | Level 2 | Level 3
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF9333EA), // Purple bar
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildLevelTab('Level 1', 1),
                _buildLevelTab('Level 2', 2),
                _buildLevelTab('Level 3', 3),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // The Scoring Matrix
          Container(
            padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            // Keep each skill column >= 56px; scroll sideways when narrower.
            child: ScrollableMinWidth(
              minWidth: 40 + _activeColumnCount() * 56.0,
              child: _buildMilestoneMatrix(),
            ),
          ),
        ],
      ),
    );
  }

  int _activeColumnCount() =>
      milestoneLevelColumns[_activeMilestoneLevel]!.length;

  Widget _buildLevelTab(String label, int level) {
    final isSelected = _activeMilestoneLevel == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeMilestoneLevel = level),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: Breakpoints.isCompact(context) ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF9333EA) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneMatrix() {
    final cols = milestoneLevelColumns[_activeMilestoneLevel]!;
    // Highest milestone of the level on top (e.g. Level 2: 10 down to 6).
    final topRow = _activeMilestoneLevel * 5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double colWidth = (constraints.maxWidth - 40) / cols.length;

        return Column(
          children: [
            // Header Row of skill columns
            Row(
              children: [
                const SizedBox(width: 40),
                for (final col in cols)
                  SizedBox(
                    width: colWidth,
                    child: Text(
                      col,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 5 Data Rows: ½ fills a cell's bottom half, 1 the whole cell.
            for (int row = topRow; row > topRow - 5; row--) ...[
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$row',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  for (final col in cols)
                    Builder(builder: (context) {
                      final tests =
                          milestoneCellTests(_milestoneRecords, col, row);
                      return Container(
                        width: colWidth,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFD8B4E2), width: 0.8),
                        ),
                        child: MilestoneMatrixCell(
                          row: row,
                          bottomTest: tests.bottom,
                          topTest: tests.top,
                          height: 32,
                        ),
                      );
                    }),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  // ── BARRIERS MASTER SCORING FORM ──
  Widget _buildBarriersMasterForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 6;
        if (constraints.maxWidth < 1300) crossAxisCount = 4;
        if (constraints.maxWidth < 900) crossAxisCount = 3;
        if (constraints.maxWidth < 600) crossAxisCount = 2;
        if (constraints.maxWidth < 300) crossAxisCount = 1;

        final barrierScores = scoresPerTest(_barrierRecords, 'barrier_scores');
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vbBarriers.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final b = vbBarriers[index];
            // Same chart as the Barriers graph (shared widget).
            return BarrierMiniChart(
              title: '${b.number}. ${b.label}',
              barrierKey: b.key,
              scoresPerTest: barrierScores,
            );
          },
        );
      },
    );
  }

  // ── SUMMARY: totals of every assessment per test ──
  Widget _buildSummary() {
    final milestones = _columnPerTest(_milestoneRecords, 'total_score');
    final barriers = _itemTotals(_barrierRecords, 'barrier_scores');
    final transition = _itemTotals(_transitionRecords, 'area_scores');
    final eesa = _columnPerTest(_eesaRecords, 'total_score');
    final transitionPerTest = scoresPerTest(_transitionRecords, 'area_scores');

    String v(double? x) => x == null ? '–' : formatVbScore(x);
    const headStyle = TextStyle(
        fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary);
    const cellStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary);
    Widget pad(String text, {TextStyle style = cellStyle}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Text(text, style: style),
        );
    TableRow row(String label, List<String> cells,
            {TextStyle style = cellStyle, Color? color}) =>
        TableRow(
          decoration: BoxDecoration(color: color),
          children: [
            pad(label, style: headStyle),
            for (final c in cells) pad(c, style: style),
          ],
        );

    String transitionCategory(int test, int c) {
      final scores = transitionPerTest[test];
      if (scores == null || scores.isEmpty) return '–';
      final areas = vbTransitionAreas.where((a) => a.category == c).toList();
      final sum =
          areas.fold<int>(0, (s, a) => s + (scores['${a.number}'] ?? 0));
      return '$sum/${areas.length * 5}';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VB-MAPP Summary',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text(
            'Totals of each assessment per test. Barriers: lower is better.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ScrollableMinWidth(
            minWidth: 560,
            child: Table(
              border: TableBorder.all(color: AppColors.divider),
              columnWidths: const {0: FixedColumnWidth(200)},
              children: [
                row(
                    'Assessment',
                    [
                      for (final l in vbTestLabels) '$l test',
                    ],
                    style: headStyle,
                    color: const Color(0xFFEDE9FE)),
                row('Milestones (/170)',
                    [for (int t = 1; t <= 4; t++) v(milestones[t])]),
                row('Barriers (/96)',
                    [for (int t = 1; t <= 4; t++) v(barriers[t])]),
                row('Transition (/90)',
                    [for (int t = 1; t <= 4; t++) v(transition[t])]),
                for (int c = 0; c < vbTransitionCategories.length; c++)
                  row('  · ${vbTransitionCategories[c]}', [
                    for (int t = 1; t <= 4; t++) transitionCategory(t, c),
                  ]),
                row('EESA (/100)', [for (int t = 1; t <= 4; t++) v(eesa[t])]),
                for (int g = 1; g <= eesaGroupCount; g++)
                  row('  · EESA group $g', [
                    for (int t = 1; t <= 4; t++)
                      v(_columnPerTest(_eesaRecords, 'group${g}_score')[t]),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
