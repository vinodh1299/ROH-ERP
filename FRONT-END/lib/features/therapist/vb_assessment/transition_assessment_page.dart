import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/db_queries.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';
import 'assessment_records.dart';

class TransitionAssessmentPage extends StatefulWidget {
  const TransitionAssessmentPage({super.key});

  @override
  State<TransitionAssessmentPage> createState() =>
      _TransitionAssessmentPageState();
}

class _TransitionAssessmentPageState extends State<TransitionAssessmentPage> {
  String? _selectedStudent;
  int? _selectedStudentId;
  int _activeTab = 0; // 0: Assessment, 1: Graph
  List<Map<String, dynamic>> _transitionRecords = [];
  bool _saving = false;
  static const _testLabels = ['1ST', '2ND', '3RD', '4TH'];

  /// Score boxes keyed '<area number 1..7>|<test number>'.
  final Map<String, TextEditingController> _scoreControllers = {};

  /// Area scores per test number, keyed "1".."7". Records are applied
  /// oldest first, so a newer save overrides the areas it scored.
  Map<int, Map<String, int>> get _scoresPerTest {
    final records = [..._transitionRecords]
      ..sort((a, b) => recordId(a).compareTo(recordId(b)));
    final perTest = <int, Map<String, int>>{};
    for (final r in records) {
      final scores = perTest[recordTestNumber(r)] ??= {};
      jsonColumnMap(r['area_scores']).forEach((area, v) {
        final score = int.tryParse(v.toString());
        if (score != null) scores[area] = score;
      });
    }
    return perTest;
  }

  /// Scores as last loaded, per test; only changed tests are saved.
  Map<int, Map<String, int>> _loadedScores = {};

  void _prefillScores() {
    _loadedScores = _scoresPerTest;
    for (int area = 1; area <= _transitionAreas.length; area++) {
      for (int t = 1; t <= 4; t++) {
        final v = _loadedScores[t]?['$area'];
        _scoreController(area, t).text = v == null ? '' : '$v';
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

    // area_scores is keyed "1".."7"; each filled value must be 1–5.
    final byTest = <int, Map<String, int>>{};
    for (int area = 1; area <= _transitionAreas.length; area++) {
      for (int t = 1; t <= 4; t++) {
        final text = _scoreController(area, t).text.trim();
        if (text.isEmpty) continue;
        final v = int.tryParse(text);
        if (v == null || v < 1 || v > 5) {
          _showError(
              '"${_transitionAreas[area - 1]['title']}" ${_testLabels[t - 1]} score must be 1 to 5.');
          return;
        }
        (byTest[t] ??= {})['$area'] = v;
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
    var ok = true;
    for (final entry in byTest.entries) {
      ok = await TransitionAssessmentQueries.save({
        'student_id': studentId,
        'test_number': entry.key,
        'assessment_date': assessmentDateFor(
            newestRecordForTest(_transitionRecords, entry.key)),
        'area_scores': entry.value,
        'total_score': entry.value.values.fold<int>(0, (a, b) => a + b),
        'max_score': _transitionAreas.length * 5,
      });
      if (!ok) break;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      _showError('Could not save the transition assessment. Please try again.');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transition Assessment Saved Successfully!')),
    );
    await _loadTransitionData();
    if (mounted) setState(() => _activeTab = 1);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Latest saved score for each area ("1".."7"). Records are applied
  /// oldest first, so a later partial entry only overrides the areas it scored.
  Map<String, int> get _latestAreaScores {
    final records = [..._transitionRecords]
      ..sort((a, b) => recordId(a).compareTo(recordId(b)));
    final scores = <String, int>{};
    for (final r in records) {
      jsonColumnMap(r['area_scores']).forEach((area, v) {
        final score = int.tryParse(v.toString());
        if (score != null) scores[area] = score;
      });
    }
    return scores;
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
    if (_selectedStudentId == null) return;
    try {
      final res = await TransitionAssessmentQueries.fetchForStudent(
          _selectedStudentId.toString());
      if (mounted) {
        setState(() {
          _transitionRecords = res;
          _prefillScores();
        });
      }
    } catch (_) {}
  }

  final List<Map<String, dynamic>> _transitionAreas = [
    {
      'title': 'VB-MAPP Milestones Assessment Score',
      'options': [
        'Scores 0 to 25 on the Milestone Assessment',
        'Scores 26 to 50 on the Milestones Assessment',
        'Scores 51 to 100 on the Milestones Assessment',
        'Scores 101 to 135 on the Milestones Assessment',
        'Scores 136 to 170 on the Milestones Assessment',
      ],
    },
    {
      'title': 'VB-MAPP Barriers Assessment Score',
      'options': [
        'Scores 56 to 96 on the Barriers Assessment (Severe barriers)',
        'Scores 30 to 55 on the Barriers Assessment (Moderate barriers)',
        'Scores 20 to 29 on the Barriers Assessment (Mild barriers)',
        'Scores 10 to 19 on the Barriers Assessment (Very few barriers)',
        'Scores 0 to 9 on the Barriers Assessment (No significant barriers)',
      ],
    },
    {
      'title': 'Negative Behaviors and Instructional Control',
      'options': [
        'Severe behavior problems, requires 1:1 supervision at all times',
        'Moderate behavior problems, requires frequent intervention',
        'Occasional minor behaviors, easily redirected by staff',
        'Rare minor behaviors, responds promptly to typical instructions',
        'No significant behavior problems, follows classroom routines independently',
      ],
    },
    {
      'title': 'Classroom Routines and Group Skills',
      'options': [
        'Does not participate in any group activities or follow routines',
        'Participates in 1-2 small group activities with intensive prompts',
        'Follows 3-4 daily routines with gestural or verbal prompts',
        'Participates in small groups (2-3 peers) for 10 minutes with minimal prompts',
        'Participates in whole group activities (5+ peers) for 15+ minutes independently',
      ],
    },
    {
      'title': 'Social Behavior and Social Play',
      'options': [
        'Does not interact with peers, engages only in solitary or self-stimulatory play',
        'Parallel play near peers without disruption for 5 minutes',
        'Initiates 2-3 interactions or shares items with peers with prompts',
        'Spontaneously plays interactive games with peers for 10 minutes',
        'Has reciprocal friendships, engages in cooperative pretend play and conversation',
      ],
    },
    {
      'title': 'Independent Work on Academic Tasks',
      'options': [
        'Cannot work independently for any duration on structured tasks',
        'Completes 1 simple previously mastered task with 1:1 adult nearby',
        'Works independently for 2 minutes completing 2 mastered tasks',
        'Works independently for 5 minutes completing a work-task bin system',
        'Works independently for 15 minutes completing new instructional tasks',
      ],
    },
    {
      'title': 'Generalization Across Time, Settings, Behaviors, and People',
      'options': [
        'Skills do not generalize beyond specific therapist and training setting',
        'Generalizes to 1 other person or setting with high reinforcement',
        'Generalizes skills to 2-3 novel persons and novel stimulus materials',
        'Consistently generalizes across multiple settings, instructors, and materials',
        'Rapidly generalizes newly acquired skills across natural environmental contexts',
      ],
    },
  ];

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
                  'Rate the Child on a Scale of 1 to 5 for Each Area',
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
            ),
            const SizedBox(height: 20),

            // Transition assessment cards
            for (int i = 0; i < _transitionAreas.length; i++) ...[
              _buildTransitionCard(
                  i + 1,
                  _transitionAreas[i]['title'] as String,
                  _transitionAreas[i]['options'] as List<String>),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),

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

  Widget _buildGraphView() {
    final latestAreaScores = _latestAreaScores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentAssessmentBanner(
          studentName: _selectedStudent ?? 'Student',
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
                'Transition Assessment Scoring Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              for (int i = 0; i < _transitionAreas.length; i++) ...[
                Builder(
                  builder: (context) {
                    final activeScore = latestAreaScores['${i + 1}'] ?? 0;

                    final label = Text(
                      _transitionAreas[i]['title'] as String,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    );
                    final bar = Row(
                      children: List.generate(5, (scoreIdx) {
                        final score = scoreIdx + 1;
                        final isAchieved = activeScore >= score;
                        return Expanded(
                          child: Container(
                            height: 28,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isAchieved
                                  ? AppColors.primary
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isAchieved
                                    ? AppColors.primary
                                    : AppColors.divider,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAchieved
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: LayoutBuilder(
                        builder: (context, rowConstraints) {
                          // Narrow: label above the full-width 1–5 score bar.
                          if (rowConstraints.maxWidth < 520) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [label, const SizedBox(height: 6), bar],
                            );
                          }
                          return Row(
                            children: [
                              SizedBox(width: 280, child: label),
                              const SizedBox(width: 16),
                              Expanded(child: bar),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransitionCard(
      int areaNumber, String title, List<String> options) {
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
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < options.length; i++) ...[
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
                        child: const Text(
                          '',
                          style: TextStyle(
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
                            options[i],
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
                      _buildScoreInputRow(_testLabels[t - 1],
                          _scoreController(areaNumber, t)),
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
                      _buildScoreInputRow(_testLabels[t - 1],
                          _scoreController(areaNumber, t)),
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
