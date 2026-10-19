import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/db_queries.dart';
import '../../../core/services/vbmapp_protocol_content.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';
import 'assessment_records.dart';
import 'milestone_matrix.dart';
import 'vbmapp_charts.dart';

class TransitionAssessmentPage extends StatefulWidget {
  const TransitionAssessmentPage({super.key});

  @override
  State<TransitionAssessmentPage> createState() =>
      _TransitionAssessmentPageState();
}

/// The 18 transition areas in 3 categories, scored 1–5 (max 90). Areas 1
/// and 2 are computed from the saved Milestones / Barriers totals of the same
/// test once the centre has entered the score bands in the protocol content
/// file; until then they are scored by hand.
class _TransitionAssessmentPageState extends State<TransitionAssessmentPage> {
  String? _selectedStudent;
  int? _selectedStudentId;
  int _activeTab = 0; // 0: Assessment, 1: Graph
  List<Map<String, dynamic>> _transitionRecords = [];
  List<Map<String, dynamic>> _milestoneRecords = [];
  List<Map<String, dynamic>> _barrierRecords = [];
  bool _saving = false;
  static const _testLabels = vbTestLabels;

  VbMappProtocolContent _protocol = VbMappProtocolContent.current;

  @override
  void initState() {
    super.initState();
    VbMappProtocolContent.load().then((c) {
      if (!mounted) return;
      setState(() {
        _protocol = c;
        _applyAutoAreas();
      });
    });
  }

  /// Score boxes keyed '<area number 1..18>|<test number>'.
  final Map<String, TextEditingController> _scoreControllers = {};

  /// Area scores per test number, keyed "1".."18" (records from the 7-area
  /// version use "1".."7", which are the same areas). Records are applied
  /// oldest first, so a newer save overrides the areas it scored.
  Map<int, Map<String, int>> get _scoresPerTest =>
      scoresPerTest(_transitionRecords, 'area_scores');

  /// Scores as last loaded, per test; only changed tests are saved.
  Map<int, Map<String, int>> _loadedScores = {};

  void _prefillScores() {
    _loadedScores = _scoresPerTest;
    for (final area in vbTransitionAreas) {
      for (int t = 1; t <= 4; t++) {
        final v = _loadedScores[t]?['${area.number}'];
        _scoreController(area.number, t).text = v == null ? '' : '$v';
      }
    }
    _applyAutoAreas();
  }

  // ── Areas 1 and 2: computed from Milestones / Barriers totals ──

  /// Milestones total saved for [test], or null.
  double? _milestonesTotal(int test) {
    final r = newestRecordForTest(_milestoneRecords, test);
    if (r == null) return null;
    return double.tryParse(r['total_score']?.toString() ?? '');
  }

  /// Barriers total saved for [test] (sum of its scored barriers), or null.
  double? _barriersTotal(int test) {
    final scores = scoresPerTest(_barrierRecords, 'barrier_scores')[test];
    if (scores == null || scores.isEmpty) return null;
    return scores.values.fold<int>(0, (a, b) => a + b).toDouble();
  }

  /// Source total and bands for an automatic area (1 or 2), else null.
  ({double? total, List<ScoreBand> bands, String source})? _autoSource(
      int area, int test) {
    if (area == 1 && _protocol.milestonesScoreBands != null) {
      return (
        total: _milestonesTotal(test),
        bands: _protocol.milestonesScoreBands!,
        source: 'Milestones',
      );
    }
    if (area == 2 && _protocol.barriersScoreBands != null) {
      return (
        total: _barriersTotal(test),
        bands: _protocol.barriersScoreBands!,
        source: 'Barriers',
      );
    }
    return null;
  }

  /// Whether the box for [area]/[test] is filled automatically (read-only).
  bool _isAuto(int area, int test) => _autoSource(area, test) != null;

  /// Writes the computed scores of areas 1 and 2 into their boxes.
  void _applyAutoAreas() {
    for (final area in const [1, 2]) {
      for (int t = 1; t <= 4; t++) {
        final src = _autoSource(area, t);
        if (src == null) continue;
        final score = src.total == null
            ? null
            : transitionScoreFromBands(src.bands, src.total!);
        _scoreController(area, t).text = score == null ? '' : '$score';
      }
    }
  }

  bool _sameScores(Map<String, int> a, Map<String, int> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  TextEditingController _scoreController(int area, int testNum) =>
      _scoreControllers.putIfAbsent(
          '$area|$testNum', () => TextEditingController());

  @override
  void dispose() {
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveTransitionAssessment() async {
    final studentId = _selectedStudentId;
    if (studentId == null || _saving) return;

    // area_scores is keyed "1".."18"; each filled value must be 1–5.
    final byTest = <int, Map<String, int>>{};
    for (final area in vbTransitionAreas) {
      for (int t = 1; t <= 4; t++) {
        final text = _scoreController(area.number, t).text.trim();
        if (text.isEmpty) continue;
        final v = int.tryParse(text);
        if (v == null || v < 1 || v > 5) {
          _showError('"${area.label}" ${_testLabels[t - 1]} score must be '
              '1 to 5.');
          return;
        }
        (byTest[t] ??= {})['${area.number}'] = v;
      }
    }
    if (byTest.isEmpty) {
      _showError('Enter at least one area score before saving.');
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
    String? error;
    for (final entry in byTest.entries) {
      error = await TransitionAssessmentQueries.trySave({
        'student_id': studentId,
        'test_number': entry.key,
        'assessment_date': assessmentDateFor(
            newestRecordForTest(_transitionRecords, entry.key)),
        'area_scores': entry.value,
        'total_score': entry.value.values.fold<int>(0, (a, b) => a + b),
        'max_score': vbTransitionMaxScore,
      });
      if (error != null) break;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      _showError('Could not save the transition assessment: $error');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Transition Assessment Saved Successfully!')),
    );
    await _loadTransitionData();
    if (mounted) setState(() => _activeTab = 1);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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

  Future<void> _loadTransitionData() async {
    final studentId = _selectedStudentId;
    if (studentId == null) return;
    try {
      final results = await Future.wait([
        TransitionAssessmentQueries.fetchForStudent('$studentId'),
        MilestoneAssessmentQueries.fetchForStudent('$studentId'),
        BarriersAssessmentQueries.fetchForStudent('$studentId'),
      ]);
      if (mounted) {
        setState(() {
          _transitionRecords = results[0];
          _milestoneRecords = results[1];
          _barrierRecords = results[2];
          _prefillScores();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStudent == null) {
      return StudentCardGrid(
        title: 'Students VB MAPP Transition Assessment',
        buttonLabel: 'Add',
        onStudentAction: (student, studentId) {
          setState(() {
            _selectedStudent = student;
            _selectedStudentId = studentId ?? _resolveStudentId(student);
            _activeTab = 0;
            _transitionRecords = [];
            _milestoneRecords = [];
            _barrierRecords = [];
            _loadedScores = {};
            for (final c in _scoreControllers.values) {
              c.clear();
            }
            _loadTransitionData();
          });
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Student Name & Back Button + Tabs + Yellow instruction badge.
          // Title wraps to 2 lines; tabs + badge move to their own line when narrow.
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 900;
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
                      '$_selectedStudent VB MAPP Transition Assessment',
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
              // Yellow Instruction Pill
              final pill = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A), // Light warm yellow
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Rate the Child 1 to 5 in Each of the 18 Areas (max 90)',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF78350F),
                  ),
                ),
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [tabs, pill],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 16),
                  tabs,
                  const SizedBox(width: 16),
                  pill,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          if (_activeTab == 0) ...[
            // Student Assessment Banner
            StudentAssessmentBanner(
              studentName: _selectedStudent ?? 'Student',
              records: _transitionRecords,
            ),
            const SizedBox(height: 20),

            // Transition assessment cards, grouped by category
            for (int c = 0; c < vbTransitionCategories.length; c++) ...[
              _buildCategoryHeader(c),
              const SizedBox(height: 12),
              for (final area
                  in vbTransitionAreas.where((a) => a.category == c)) ...[
                _buildTransitionCard(area),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),

            // Cancel & Save Buttons
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _saveTransitionAssessment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _saving ? 'Saving…' : 'Save',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildGraphView(),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(int category) {
    final areas = vbTransitionAreas.where((a) => a.category == category);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${vbTransitionCategories[category]} · areas '
        '${areas.first.number}–${areas.last.number}',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTopTab(String label, int index) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

  /// Total of the saved area scores of each test (null = test not saved).
  Map<int, double?> get _testTotals {
    final perTest = _scoresPerTest;
    return {
      for (int t = 1; t <= 4; t++)
        t: (perTest[t]?.isNotEmpty ?? false)
            ? perTest[t]!.values.fold<int>(0, (a, b) => a + b).toDouble()
            : null,
    };
  }

  /// Graph: total per test, then every area with one bar per test (1–5).
  Widget _buildGraphView() {
    final perTest = _scoresPerTest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentAssessmentBanner(
          studentName: _selectedStudent ?? 'Student',
          records: _transitionRecords,
        ),
        const SizedBox(height: 24),
        TestTotalsChart(
          title: 'Transition total score per test',
          subtitle: 'Sum of the scored areas (higher is better).',
          totals: _testTotals,
          maxScore: vbTransitionMaxScore.toDouble(),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transition Assessment: all tests by area',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              const TestColorKey(),
              const SizedBox(height: 20),
              for (int c = 0; c < vbTransitionCategories.length; c++) ...[
                Text(
                  '${vbTransitionCategories[c]} · '
                  '${_categorySubtotalText(perTest, c)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                for (final area
                    in vbTransitionAreas.where((a) => a.category == c))
                  _buildAreaComparisonRow(area, perTest),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// "1ST 12/35 · 2ND 15/35" for the tests that scored this category.
  String _categorySubtotalText(Map<int, Map<String, int>> perTest, int c) {
    final areas = vbTransitionAreas.where((a) => a.category == c).toList();
    final parts = <String>[];
    for (int t = 1; t <= 4; t++) {
      final scores = perTest[t];
      if (scores == null || scores.isEmpty) continue;
      final sum =
          areas.fold<int>(0, (s, a) => s + (scores['${a.number}'] ?? 0));
      parts.add('${_testLabels[t - 1]} $sum/${areas.length * 5}');
    }
    return parts.isEmpty ? 'not scored yet' : parts.join(' · ');
  }

  Widget _buildAreaComparisonRow(
      VbTransitionArea area, Map<int, Map<String, int>> perTest) {
    final label = Text(
      '${area.number}. ${area.label}',
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
    final bars = Column(
      children: [
        for (int t = 1; t <= 4; t++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: LayoutBuilder(builder: (context, c) {
              final score = perTest[t]?['${area.number}'];
              return Row(
                children: [
                  Container(
                    height: 10,
                    width: score == null ? 0 : c.maxWidth * 0.85 * score / 5,
                    decoration: BoxDecoration(
                      color: milestoneTestColors[t],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    score == null ? '–' : '$score',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary),
                  ),
                ],
              );
            }),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: LayoutBuilder(
        builder: (context, rowConstraints) {
          if (rowConstraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, const SizedBox(height: 6), bars],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 280, child: label),
              const SizedBox(width: 16),
              Expanded(child: bars),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransitionCard(VbTransitionArea area) {
    final areaNumber = area.number;
    final autoNote = _autoNote(areaNumber);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Left Options Column
          final optionsColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$areaNumber. ${area.label}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: AppColors.textPrimary,
                ),
              ),
              if (autoNote != null) ...[
                const SizedBox(height: 4),
                Text(
                  autoNote,
                  style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              for (int score = 1; score <= 5; score++) ...[
                Padding(
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
                          '$score',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            _protocol.transitionCriterion(area, score),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                optionsColumn,
                const SizedBox(height: 12),
                scoreTitle,
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    for (int t = 1; t <= 4; t++)
                      _buildScoreInputRow(
                          _testLabels[t - 1], _scoreController(areaNumber, t),
                          readOnly: _isAuto(areaNumber, t)),
                  ],
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: optionsColumn),
              const SizedBox(width: 24),

              // Right Assessment Score Column
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
                          _testLabels[t - 1], _scoreController(areaNumber, t),
                          readOnly: _isAuto(areaNumber, t)),
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

  /// Explains how areas 1 and 2 are scored (auto from totals, or by hand).
  String? _autoNote(int area) {
    if (area != 1 && area != 2) return null;
    final source = area == 1 ? 'Milestones' : 'Barriers';
    if (!_isAuto(area, 1)) {
      return 'Score by hand: the $source score bands have not been entered '
          'in the protocol content file yet.';
    }
    final parts = <String>[];
    for (int t = 1; t <= 4; t++) {
      final total = _autoSource(area, t)!.total;
      parts.add('${_testLabels[t - 1]} '
          '${total == null ? 'not saved' : formatVbScore(total)}');
    }
    return 'Computed from the saved $source total of the same test '
        '(${parts.join(' · ')}).';
  }

  Widget _buildScoreInputRow(String label, TextEditingController controller,
      {bool readOnly = false}) {
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
            color: readOnly ? const Color(0xFFF3F4F6) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.divider),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[1-5]')),
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
}
