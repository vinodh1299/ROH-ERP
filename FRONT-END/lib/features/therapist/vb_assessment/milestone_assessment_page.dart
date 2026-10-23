import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/db_queries.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';
import 'assessment_records.dart';
import 'milestone_matrix.dart';

class MilestoneAssessmentPage extends StatefulWidget {
  const MilestoneAssessmentPage({super.key});

  @override
  State<MilestoneAssessmentPage> createState() =>
      _MilestoneAssessmentPageState();
}

class _MilestoneAssessmentPageState extends State<MilestoneAssessmentPage> {
  String? _selectedStudent;
  int? _selectedStudentId;
  int _activeTab = 0; // 0: Assessment, 1: Graph
  String _selectedAssessment = 'Assessment 1';
  int _selectedLevel = 1;
  int _activeMilestoneGraphLevel = 1;
  List<Map<String, dynamic>> _milestoneRecords = [];

  /// Milestone scores being edited: "<domain>_score|<milestone>" → ½ or 1.
  final Map<String, double> _scores = {};
  bool _saving = false;
  // The saved record for this test has only domain totals (no per-milestone
  // scores), so the milestones shown are spread from those totals.
  bool _derivedFromTotals = false;

  int get _testNumber => int.tryParse(_selectedAssessment.split(' ').last) ?? 1;

  String _scoreKey(String column, int milestone) => '$column|$milestone';

  double _scoreOf(String column, int milestone) =>
      _scores[_scoreKey(column, milestone)] ?? 0;

  /// Fills the milestone scores (and level) from the newest saved record for
  /// the selected test, or clears them when that test has not been saved yet.
  void _prefillForTest() {
    _scores.clear();
    _derivedFromTotals = false;
    final record = newestRecordForTest(_milestoneRecords, _testNumber);
    if (record == null) return;
    milestoneScoresOf(record).forEach((column, items) {
      items.forEach((n, v) => _scores[_scoreKey(column, n)] = v);
    });
    final level = int.tryParse(
            (record['level'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), ''));
    _selectedLevel = (level ?? 1).clamp(1, 3);
    _derivedFromTotals = !hasMilestoneDetail(record) && _scores.isNotEmpty;
  }

  /// Domain score = sum of that domain's milestone scores (max 5 per level).
  Map<String, double> _domainScores() => {
        for (final column in milestoneScoreColumns)
          column: [
            for (int n = 1; n <= 15; n++) _scoreOf(column, n),
          ].fold(0.0, (sum, v) => sum + v),
      };

  double get _totalScore =>
      _domainScores().values.fold(0.0, (sum, v) => sum + v);

  double _levelScore(int level) => [
        for (final c in milestoneLevelColumns[level]!)
          for (final n in milestoneNumbers(level))
            _scoreOf(milestoneScoreColumn(c)!, n),
      ].fold(0.0, (sum, v) => sum + v);

  /// Highest level with any milestone scored (the level saved on the record).
  int get _highestScoredLevel {
    for (int level = 3; level >= 1; level--) {
      if (_levelScore(level) > 0) return level;
    }
    return _selectedLevel;
  }

  String _formatScore(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Future<void> _saveMilestoneAssessment() async {
    final studentId = _selectedStudentId;
    if (studentId == null || _saving) return;
    setState(() => _saving = true);
    final milestoneScores = <String, Map<String, double>>{};
    _scores.forEach((key, v) {
      if (v <= 0) return;
      final parts = key.split('|');
      (milestoneScores[parts[0]] ??= {})[parts[1]] = v;
    });
    final ok = await MilestoneAssessmentQueries.save({
      'student_id': studentId,
      'test_number': _testNumber,
      'level': 'Level $_highestScoredLevel',
      'assessment_date': assessmentDateFor(
          newestRecordForTest(_milestoneRecords, _testNumber)),
      'total_score': _totalScore,
      'max_score': 170,
      ..._domainScores(),
      'scores_detail': {'milestone_scores': milestoneScores},
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not save the milestone assessment. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Milestone $_selectedAssessment saved (total ${_formatScore(_totalScore)} / 170).')),
    );
    await _loadMilestoneData();
    if (!mounted) return;
    setState(() {
      _activeTab = 1;
      _activeMilestoneGraphLevel = _selectedLevel;
    });
  }

  int _resolveStudentId(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('alex')) return 1;
    if (lower.contains('aarav')) return 2;
    if (lower.contains('emma')) return 3;
    if (lower.contains('matt')) return 4;
    if (lower.contains('rahul')) return 5;
    if (lower.contains('sophia')) return 6;
    return 1;
  }

  Future<void> _loadMilestoneData() async {
    if (_selectedStudentId == null) return;
    try {
      final res = await MilestoneAssessmentQueries.fetchForStudent(
          _selectedStudentId.toString());
      if (mounted) {
        setState(() {
          _milestoneRecords = res;
          _prefillForTest();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStudent == null) {
      return StudentCardGrid(
        title: 'Students VB MAPP Milestone Assessment',
        buttonLabel: 'Add',
        onStudentAction: (student, studentId) {
          setState(() {
            _selectedStudent = student;
            _selectedStudentId = studentId ?? _resolveStudentId(student);
            _activeTab = 0;
            _scores.clear();
            _milestoneRecords = [];
            _selectedAssessment = 'Assessment 1';
            _selectedLevel = 1;
            _activeMilestoneGraphLevel = 1;
            _loadMilestoneData();
          });
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row — title wraps to 2 lines; the Assessment | Graph
          // toggle drops onto its own line when the content area is narrow.
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
                      '$_selectedStudent VB MAPP Milestone Assessment',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              );
              // Assessment | Graph Tabs
              final tabs = Container(
                height: narrow ? 44 : 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopTab('Assessment', 0),
                    _buildTopTab('Graph', 1),
                  ],
                ),
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleRow, const SizedBox(height: 12), tabs],
                );
              }
              return Row(
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 16),
                  tabs,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Body Content
          if (_activeTab == 0) _buildAssessmentTab() else _buildGraphTab(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTopTab(String label, int index) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ASSESSMENT TAB (LEVELS 1 - 3)
  // ==========================================
  Widget _buildAssessmentTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Assessment Banner
        StudentAssessmentBanner(
          studentName: _selectedStudent ?? 'Student',
          records: _milestoneRecords,
        ),
        const SizedBox(height: 20),

        // Sub-controls Row: Assessment Dropdown, + Add, Level Dropdown, Total Score Badge
        // (wraps onto multiple lines when the content area is narrow)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final assessmentDropdown = _buildAssessmentDropdown();
              final addButton = _buildAddSessionButton();
              final levelDropdown = _buildLevelDropdown();
              final totalBadge = _buildTotalScoreBadge();
              if (constraints.maxWidth < 640) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    assessmentDropdown,
                    addButton,
                    levelDropdown,
                    totalBadge
                  ],
                );
              }
              return Row(
                children: [
                  assessmentDropdown,
                  const SizedBox(width: 12),
                  addButton,
                  const SizedBox(width: 20),
                  levelDropdown,
                  const Spacer(),
                  totalBadge,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Assessment Tasks for Current Selected Level
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_derivedFromTotals) ...[
                const Text(
                  'This test was saved as domain totals only, so its milestones '
                  'are shown filled in order from those totals. Check them '
                  'before saving again.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
              ],
              ..._buildLevelMilestones(),

              const SizedBox(height: 24),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _selectedStudent = null),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : _saveMilestoneAssessment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_saving ? 'Saving…' : 'Save',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAssessment,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          items: [
            'Assessment 1',
            'Assessment 2',
            'Assessment 3',
            'Assessment 4'
          ].map((a) {
            return DropdownMenuItem(
              value: a,
              child: Text(a,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary)),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _selectedAssessment = val;
              _prefillForTest();
            });
          },
        ),
      ),
    );
  }

  Widget _buildAddSessionButton() {
    return InkWell(
      onTap: () {
        final next = [1, 2, 3, 4].firstWhere(
            (t) => newestRecordForTest(_milestoneRecords, t) == null,
            orElse: () => 0);
        if (next == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'All 4 assessments are recorded; pick one to edit it.')),
          );
          return;
        }
        setState(() {
          _selectedAssessment = 'Assessment $next';
          _prefillForTest();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: AppColors.primary),
            SizedBox(width: 4),
            Text('New',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedLevel,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          items: [1, 2, 3].map((lvl) {
            return DropdownMenuItem(
              value: lvl,
              child: Text('Level $lvl',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedLevel = val);
          },
        ),
      ),
    );
  }

  // Total score of the test being edited (max 170)
  Widget _buildTotalScoreBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Total Score: ',
            style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins'),
          ),
          Text(
            _formatScore(_totalScore),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  /// The selected level's domains, each with its 5 milestones scored 0/½/1.
  List<Widget> _buildLevelMilestones() {
    final level = _selectedLevel;
    final numbers = milestoneNumbers(level);
    final columns = milestoneLevelColumns[level]!;
    return [
      Text(
        'Level $level · milestones ${numbers.first}–${numbers.last} · '
        'score each milestone 0, ½ or 1 · level subtotal '
        '${_formatScore(_levelScore(level))} / ${columns.length * 5}',
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final perRow = constraints.maxWidth >= 900
              ? 3
              : (constraints.maxWidth >= 560 ? 2 : 1);
          final width = (constraints.maxWidth - (perRow - 1) * 12) / perRow;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final domain in columns)
                SizedBox(width: width, child: _buildDomainCard(domain, level)),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildDomainCard(String domain, int level) {
    final column = milestoneScoreColumn(domain)!;
    final subtotal = milestoneNumbers(level)
        .fold(0.0, (sum, n) => sum + _scoreOf(column, n));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  domain.replaceAll('/ ', '/'),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'Poppins'),
                ),
              ),
              Text('${_formatScore(subtotal)} / 5',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          for (final n in milestoneNumbers(level))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Milestone $n',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary)),
                  ),
                  _buildScoreSelector(column, n),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 0 | ½ | 1 selector for one milestone.
  Widget _buildScoreSelector(String column, int milestone) {
    final current = _scoreOf(column, milestone);
    final compact = Breakpoints.isCompact(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in const [0.0, 0.5, 1.0])
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() {
                final key = _scoreKey(column, milestone);
                if (option == 0) {
                  _scores.remove(key);
                } else {
                  _scores[key] = option;
                }
              }),
              child: Container(
                width: compact ? 40 : 34,
                padding: EdgeInsets.symmetric(vertical: compact ? 8 : 4),
                decoration: BoxDecoration(
                  color: current == option
                      ? (option == 0 ? AppColors.textSecondary : AppColors.primary)
                      : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(option == 0 ? 15 : 0),
                    right: Radius.circular(option == 1 ? 15 : 0),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  option == 0 ? '0' : (option == 0.5 ? '½' : '1'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: current == option
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // GRAPH TAB (LEVELS 1 - 3)
  // ==========================================
  Widget _buildGraphTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Assessment Banner with Key Table
        StudentAssessmentBanner(
          studentName: _selectedStudent ?? 'Student',
          records: _milestoneRecords,
        ),
        const SizedBox(height: 20),

        // Level Selector Buttons (Level 1, Level 2, Level 3)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildLevelGraphButton('Level 1', 1),
            _buildLevelGraphButton('Level 2', 2),
            _buildLevelGraphButton('Level 3', 3),
          ],
        ),
        const SizedBox(height: 20),

        // Milestone Matrix Grid
        if (_activeMilestoneGraphLevel == 1)
          _buildMilestoneMatrixCard(
              'Level 1 Milestone Matrix', milestoneLevelColumns[1]!, 5, 1)
        else if (_activeMilestoneGraphLevel == 2)
          _buildMilestoneMatrixCard(
              'Level 2 Milestone Matrix', milestoneLevelColumns[2]!, 10, 6)
        else
          _buildMilestoneMatrixCard(
              'Level 3 Milestone Matrix', milestoneLevelColumns[3]!, 15, 11),
      ],
    );
  }

  Widget _buildLevelGraphButton(String title, int level) {
    final isSelected = _activeMilestoneGraphLevel == level;
    return ElevatedButton(
      onPressed: () => setState(() => _activeMilestoneGraphLevel = level),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.primary,
        elevation: isSelected ? 2 : 0,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'),
      ),
    );
  }

  Widget _buildMilestoneMatrixCard(
      String title, List<String> columns, int maxRow, int minRow) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 16),
          // Wide: fixed 75px columns (as before). Narrow: columns flex down to
          // a 56px readable minimum, then the matrix scrolls sideways.
          LayoutBuilder(
            builder: (context, constraints) {
              // Row numbers live in a borderless label column to the left of
              // the grid; it is excluded from the width the grid can use.
              const labelWidth = 28.0;
              const headerHeight = 40.0;
              const cellHeight = 38.0;
              final fitsFixed =
                  constraints.maxWidth - labelWidth >= columns.length * 75;
              final table = Table(
                defaultColumnWidth: fitsFixed
                    ? const FixedColumnWidth(75)
                    : const FlexColumnWidth(),
                border:
                    TableBorder.all(color: const Color(0xFFE5E7EB), width: 1),
                children: [
                  // Header row
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFEDE9FE)),
                    children: columns.map((col) {
                      return SizedBox(
                        height: headerHeight,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              col,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: AppColors.primary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Matrix Data Rows (from maxRow down to minRow)
                  for (int row = maxRow; row >= minRow; row--)
                    TableRow(
                      children: List.generate(columns.length, (colIdx) {
                        // ½ fills the bottom half, 1 the whole cell; each
                        // half is coloured by the first test that reached it.
                        final tests = milestoneCellTests(
                            _milestoneRecords, columns[colIdx], row);
                        return MilestoneMatrixCell(
                          row: row,
                          bottomTest: tests.bottom,
                          topTest: tests.top,
                          height: cellHeight,
                          showNumber: false,
                        );
                      }),
                    ),
                ],
              );

              // Same row heights and border widths as the grid (transparent
              // borders still take up space), so the numbers line up.
              final labels = Table(
                defaultColumnWidth: const FixedColumnWidth(labelWidth),
                border: TableBorder.all(color: Colors.transparent, width: 1),
                children: [
                  const TableRow(
                    children: [SizedBox(height: headerHeight)],
                  ),
                  for (int row = maxRow; row >= minRow; row--)
                    TableRow(
                      children: [
                        SizedBox(
                          height: cellHeight,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                '$row',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              );

              final grid = fitsFixed
                  ? table
                  : ScrollableMinWidth(
                      minWidth: columns.length * 56.0,
                      child: table,
                    );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  labels,
                  Flexible(child: grid),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
