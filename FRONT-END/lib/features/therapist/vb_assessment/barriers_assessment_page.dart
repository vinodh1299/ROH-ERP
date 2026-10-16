import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/db_queries.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';
import 'assessment_records.dart';

class BarriersAssessmentPage extends StatefulWidget {
  const BarriersAssessmentPage({super.key});

  @override
  State<BarriersAssessmentPage> createState() => _BarriersAssessmentPageState();
}

class _BarriersAssessmentPageState extends State<BarriersAssessmentPage> {
  String? _selectedStudent;
  int? _selectedStudentId;
  int _activeTab = 0; // 0: Assessment, 1: Graph
  List<Map<String, dynamic>> _barrierRecords = [];
  bool _saving = false;

  /// The 18 barriers; these names are the keys of barrier_scores.
  static const List<String> _barrierNames = [
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
  static const _testLabels = ['1ST', '2ND', '3RD', '4TH'];

  /// Score boxes keyed '<barrier>|<test number>'.
  final Map<String, TextEditingController> _scoreControllers = {};

  /// Scores as last loaded from the server, per test; used to save only the
  /// tests that were changed (so untouched tests keep their dates).
  Map<int, Map<String, int>> _loadedScores = {};

  /// Fills every score box from the saved scores.
  void _prefillScores() {
    _loadedScores = _scoresPerTest;
    for (final barrier in _barrierNames) {
      for (int t = 1; t <= 4; t++) {
        final v = _loadedScores[t]?[barrier];
        _scoreController(barrier, t).text = v == null ? '' : '$v';
      }
    }
  }

  bool _sameScores(Map<String, int> a, Map<String, int> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  TextEditingController _scoreController(String barrier, int testNum) =>
      _scoreControllers.putIfAbsent(
          '$barrier|$testNum', () => TextEditingController());

  @override
  void dispose() {
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveBarriersAssessment() async {
    final studentId = _selectedStudentId;
    if (studentId == null || _saving) return;

    // Collect the filled boxes per test column; every value must be 0–4.
    final byTest = <int, Map<String, int>>{};
    for (final barrier in _barrierNames) {
      for (int t = 1; t <= 4; t++) {
        final text = _scoreController(barrier, t).text.trim();
        if (text.isEmpty) continue;
        final v = int.tryParse(text);
        if (v == null || v < 0 || v > 4) {
          _showError('"$barrier" ${_testLabels[t - 1]} score must be 0 to 4.');
          return;
        }
        (byTest[t] ??= {})[barrier] = v;
      }
    }
    if (byTest.isEmpty) {
      _showError('Enter at least one barrier score before saving.');
      return;
    }
    // Each test is one record that saving updates; skip tests left unchanged.
    byTest.removeWhere(
        (t, scores) => _sameScores(scores, _loadedScores[t] ?? const {}));
    if (byTest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save.')),
      );
      return;
    }

    setState(() => _saving = true);
    var ok = true;
    for (final entry in byTest.entries) {
      ok = await BarriersAssessmentQueries.save({
        'student_id': studentId,
        'test_number': entry.key,
        'assessment_date':
            assessmentDateFor(newestRecordForTest(_barrierRecords, entry.key)),
        'barrier_scores': entry.value,
        'total_score': entry.value.values.fold<int>(0, (a, b) => a + b),
        'max_score': _barrierNames.length * 4,
      });
      if (!ok) break;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      _showError('Could not save the barriers assessment. Please try again.');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barriers Assessment Saved Successfully!')),
    );
    await _loadBarriersData();
    if (mounted) setState(() => _activeTab = 1);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Barrier scores per test number (1–4). Records are applied oldest
  /// first, so a later partial entry only overrides the barriers it scored.
  Map<int, Map<String, int>> get _scoresPerTest =>
      scoresPerTest(_barrierRecords, 'barrier_scores');

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

  Future<void> _loadBarriersData() async {
    if (_selectedStudentId == null) return;
    try {
      final res = await BarriersAssessmentQueries.fetchForStudent(
          _selectedStudentId.toString());
      if (mounted) {
        setState(() {
          _barrierRecords = res;
          _prefillScores();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStudent == null) {
      return StudentCardGrid(
        title: 'Students VB MAPP Barriers Assessment',
        buttonLabel: 'Add',
        onStudentAction: (student, studentId) {
          setState(() {
            _selectedStudent = student;
            _selectedStudentId = studentId ?? _resolveStudentId(student);
            _activeTab = 0;
            _barrierRecords = [];
            _loadedScores = {};
            for (final c in _scoreControllers.values) {
              c.clear();
            }
            _loadBarriersData();
          });
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row — title wraps to 2 lines; the legend moves below the
          // title when the content area is narrow.
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
                      '$_selectedStudent VB MAPP Barriers Assessment',
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
              // Legend table
              final legend = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendRow('0', 'No problem'),
                    _LegendRow('1', 'Occasional problem'),
                    _LegendRow('2', 'Moderate problem'),
                    _LegendRow('3', 'Persistent problem'),
                    _LegendRow('4', 'Severe problem'),
                  ],
                ),
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleRow, const SizedBox(height: 12), legend],
                );
              }
              return Row(
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 16),
                  legend,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Tabs: Assessment | Graph
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabButton('Assessment', 0),
                _buildTabButton('Graph', 1),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Content based on tab
          if (_activeTab == 0) _buildAssessmentView() else _buildGraphView(),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int tabIndex) {
    final isActive = _activeTab == tabIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _activeTab = tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentAssessmentBanner(
          studentName: _selectedStudent ?? 'Student',
          records: _barrierRecords,
        ),
        const SizedBox(height: 20),
        _buildBarriersList(),
      ],
    );
  }

  Widget _buildBarriersList() {
    return Column(
      children: [
        for (final title in _barrierNames) ...[
          _buildBarrierQuestionCard(title),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _selectedStudent = null),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _saving ? null : _saveBarriersAssessment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_saving ? 'Saving…' : 'Save',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBarrierQuestionCard(String title) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final options = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (title == 'Behaviour Problems') ...[
                _buildScoreOption('0',
                    'Does not demonstrate any significant negative behaviors'),
                _buildScoreOption('1',
                    'Engages in some minor negative behaviors weekly, but recovery is quick'),
                _buildScoreOption('2',
                    'Emits a variety of minor negative behaviors daily (e.g., crying, verbal refusal)'),
                _buildScoreOption('3',
                    'Emits more severe negative behavior daily (e.g., tantrums, throwing things)'),
                _buildScoreOption('4',
                    'Often emits severe negative behavior that is a danger to himself or others'),
              ] else ...[
                _buildScoreOption('0', 'No problem'),
                _buildScoreOption('1', 'Occasional problem'),
                _buildScoreOption('2', 'Moderate problem'),
                _buildScoreOption('3', 'Persistent problem'),
                _buildScoreOption('4', 'Severe problem'),
              ],
            ],
          );
          const scoreTitle = Text(
            'Assessment Score',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary),
          );
          // Narrow: score boxes go below the options and flow in a row.
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                options,
                const SizedBox(height: 12),
                scoreTitle,
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    for (int t = 1; t <= 4; t++)
                      _buildScoreInputRow(
                          _testLabels[t - 1], _scoreController(title, t)),
                  ],
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: options),
              const SizedBox(width: 24),
              // Assessment score boxes
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    scoreTitle,
                    const SizedBox(height: 12),
                    for (int t = 1; t <= 4; t++) ...[
                      if (t > 1) const SizedBox(height: 8),
                      _buildScoreInputRow(
                          _testLabels[t - 1], _scoreController(title, t)),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScoreOption(String score, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              score,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                text,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInputRow(String label, TextEditingController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 42,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 50,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.divider),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-4]')),
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: const InputDecoration(
                hintText: '–',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ── 2. GRAPH VIEW (18 BARRIER CHARTS) ──
  Widget _buildGraphView() {
    const chartTitles = _barrierNames;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentAssessmentBanner(
          studentName: _selectedStudent ?? 'Student',
          records: _barrierRecords,
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 6;
            if (constraints.maxWidth < 1300) crossAxisCount = 4;
            if (constraints.maxWidth < 900) crossAxisCount = 3;
            if (constraints.maxWidth < 600) crossAxisCount = 2;
            if (constraints.maxWidth < 300) crossAxisCount = 1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chartTitles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                return _buildBarrierChartCard(
                    chartTitles[index], index, chartTitles);
              },
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBarrierChartCard(
      String title, int chartIndex, List<String> chartTitles) {
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
            title,
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
            child: _buildBarrierGrid(chartIndex, chartTitles),
          ),
        ],
      ),
    );
  }

  Widget _buildBarrierGrid(int chartIndex, List<String> chartTitles) {
    final title =
        chartIndex < chartTitles.length ? chartTitles[chartIndex] : '';
    final scoresPerTest = _scoresPerTest;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 4;
        final cellHeight = constraints.maxHeight / 5;

        return Column(
          children: List.generate(5, (rowIndex) {
            // Row 0 is rating 4 (top), Row 4 is rating 0 (bottom)
            final rating = 4 - rowIndex;

            return Row(
              children: List.generate(4, (colIndex) {
                final testNum = colIndex + 1;
                Color cellColor = Colors.transparent;

                final score = scoresPerTest[testNum]?[title] ?? 0;
                if (score >= rating && rating > 0) {
                  if (testNum == 1) {
                    cellColor =
                        const Color(0xFFFBBF24); // Yellow (1st Test)
                  } else if (testNum == 2) {
                    cellColor =
                        const Color(0xFFF97316); // Orange (2nd Test)
                  } else if (testNum == 3) {
                    cellColor = const Color(0xFF10B981); // Green (3rd Test)
                  } else if (testNum == 4) {
                    cellColor = const Color(0xFF3B82F6); // Blue (4th Test)
                  }
                }

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

class _LegendRow extends StatelessWidget {
  final String score;
  final String label;
  const _LegendRow(this.score, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
