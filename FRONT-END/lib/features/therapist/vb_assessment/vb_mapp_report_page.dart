import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/db_queries.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';
import 'milestone_matrix.dart';

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

  Future<void> _loadMilestoneData() async {
    final studentId = _selectedStudentId;
    if (studentId == null) return;
    final res = await MilestoneAssessmentQueries.fetchForStudent('$studentId');
    if (mounted) setState(() => _milestoneRecords = res);
  }

  final List<String> _level1Columns = [
    'Mand',
    'Tact',
    'Listener',
    'VP/ MTS',
    'Play',
    'Social',
    'Imitation',
    'Echoic',
    'Vocal'
  ];

  final List<String> _level2Columns = [
    'Mand',
    'Tact',
    'Listener',
    'VP/ MTS',
    'Play',
    'Social',
    'Imitation',
    'Echoic',
    'LRFFC',
    'Intraverbal',
    'Group',
    'Linguistics'
  ];

  final List<String> _level3Columns = [
    'Mand',
    'Tact',
    'Listener',
    'VP/ MTS',
    'Play',
    'Social',
    'Reading',
    'LRFFC',
    'writing',
    'Intraverbal',
    'Group',
    'Linguistics',
    'Math'
  ];

  final List<String> _barrierChartTitles = [
    'Behaviour Problems',
    'Instructional Control',
    'Impaired Mand',
    'Impaired Tact',
    'Impaired Imitation',
    'Impaired Echoic',
    'Impaired VP-MTS',
    'Impaired Listener Responding',
    'Impaired Intraverbal',
    'Impaired Social Skills',
    'Prompt Dependent',
    'Scrolling',
    'Impaired Scanning',
    'Impaired Conditional Discrimination',
    'Failure to Generalize',
    'Weak Motivators',
    'Response Requirement weakens MO',
    'Reinforcer Dependent',
  ];

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
          StudentAssessmentBanner(studentName: _selectedStudent!),
          const SizedBox(height: 24),

          // Render Either Barriers Master Scoring Grid OR Milestones Master Scoring Chart
          if (_isBarrierMode)
            _buildBarriersMasterForm()
          else
            _buildMilestonesMasterForm(),
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

  int _activeColumnCount() {
    if (_activeMilestoneLevel == 1) return _level1Columns.length;
    if (_activeMilestoneLevel == 2) return _level2Columns.length;
    return _level3Columns.length;
  }

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
    List<String> cols;
    if (_activeMilestoneLevel == 1) {
      cols = _level1Columns;
    } else if (_activeMilestoneLevel == 2) {
      cols = _level2Columns;
    } else {
      cols = _level3Columns;
    }
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

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _barrierChartTitles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textPrimary, width: 1.5),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(
                    _barrierChartTitles[index],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildBarrierMasterGrid(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBarrierMasterGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 4;
        final cellHeight = constraints.maxHeight / 5;

        return Column(
          children: List.generate(5, (_) {
            return Row(
              children: List.generate(4, (colIndex) {
                Color cellColor = Colors.transparent;

                return Container(
                  width: cellWidth,
                  height: cellHeight,
                  decoration: BoxDecoration(
                    color: cellColor,
                    border:
                        Border.all(color: const Color(0xFFE5D5F5), width: 0.8),
                  ),
                );
              }),
            );
          }),
        );
      },
    );
  }
}
