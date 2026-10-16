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

  final Map<String, bool> _toggles = {};
  bool _saving = false;
  // The saved record for this test has domain scores but no per-item answers
  // (e.g. entered before item answers were stored), so toggles can't be shown.
  bool _scoresOnly = false;

  int get _testNumber => int.tryParse(_selectedAssessment.split(' ').last) ?? 1;

  /// Fills the toggles (and level) from the newest saved record for the
  /// selected test, or clears them when that test has not been saved yet.
  void _prefillForTest() {
    _toggles.clear();
    _scoresOnly = false;
    final record = newestRecordForTest(_milestoneRecords, _testNumber);
    if (record == null) return;
    final items = jsonColumnMap(jsonColumnMap(record['scores_detail'])['items']);
    items.forEach((key, value) => _toggles[key] = value == true);
    final level = (record['level'] ?? '').toString();
    _selectedLevel = level == 'Comprehensive'
        ? 4
        : (int.tryParse(level.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1);
    _scoresOnly = items.isEmpty &&
        record.entries.any((e) =>
            e.key.endsWith('_score') &&
            e.key != 'max_score' &&
            (double.tryParse(e.value?.toString() ?? '') ?? 0) > 0);
  }

  // Each task card is one milestone; its toggle-key prefix says which domain
  // score column it counts towards.
  static const Map<String, String> _milestoneDomains = {
    'l1_tact': 'tacting_score',
    'l1_lr': 'listener_score',
    'l2_mand': 'manding_score',
    'l2_tact': 'tacting_score',
    'l3_mand': 'manding_score',
    'l3_tact': 'tacting_score',
    'l4_iv': 'intraverbal_score',
  };

  /// A milestone scores 1 when both list items are achieved, 1/2 for one.
  double _milestoneScore(String prefix) {
    final yes = [1, 2].where((i) => _toggles['${prefix}_$i'] ?? false).length;
    return yes / 2;
  }

  /// Domain score = number of milestones achieved in that domain, which is
  /// what the milestone matrix graph plots (cells 1..score are filled).
  Map<String, double> _domainScores() {
    final scores = <String, double>{};
    _milestoneDomains.forEach((prefix, column) {
      scores[column] = (scores[column] ?? 0) + _milestoneScore(prefix);
    });
    return scores;
  }

  double get _totalScore =>
      _domainScores().values.fold(0.0, (sum, v) => sum + v);

  String _formatScore(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Future<void> _saveMilestoneAssessment() async {
    final studentId = _selectedStudentId;
    if (studentId == null || _saving) return;
    setState(() => _saving = true);
    final scores = _domainScores();
    final ok = await MilestoneAssessmentQueries.save({
      'student_id': studentId,
      'test_number': _testNumber,
      'level': _selectedLevel <= 3 ? 'Level $_selectedLevel' : 'Comprehensive',
      'assessment_date': assessmentDateFor(
          newestRecordForTest(_milestoneRecords, _testNumber)),
      'total_score': _totalScore,
      ...scores,
      'scores_detail': {
        'items': Map<String, bool>.from(_toggles),
        'milestones': {
          for (final prefix in _milestoneDomains.keys)
            prefix: _milestoneScore(prefix),
        },
      },
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
          content:
              Text('Milestone Assessment Level $_selectedLevel Saved Successfully!')),
    );
    await _loadMilestoneData();
    if (!mounted) return;
    setState(() {
      _activeTab = 1;
      if (_selectedLevel <= 3) _activeMilestoneGraphLevel = _selectedLevel;
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
            _toggles.clear();
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
  // ASSESSMENT TAB (LEVEL 1 - 4)
  // ==========================================
  Widget _buildAssessmentTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Assessment Banner
        StudentAssessmentBanner(
          studentName: _selectedStudent ?? 'Student',
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
              if (_scoresOnly) ...[
                const Text(
                  'This test was saved as domain scores only, so its item answers '
                  'can\'t be shown. Saving it again replaces those scores with the '
                  'items marked below.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
              ],
              if (_selectedLevel == 1) ..._buildLevel1Tasks(),
              if (_selectedLevel == 2) ..._buildLevel2Tasks(),
              if (_selectedLevel == 3) ..._buildLevel3Tasks(),
              if (_selectedLevel >= 4) ..._buildLevel4Tasks(),

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New assessment session added')),
        );
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
            Text('+ Add',
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
          items: List.generate(7, (index) => index + 1).map((lvl) {
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

  // Total Score: 5.5 Badge
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

  // Level 1 Tasks (TACT + LISTENER RESPONDING)
  List<Widget> _buildLevel1Tasks() {
    return [
      _buildCategoryBadge('TACT'),
      const SizedBox(height: 16),
      _buildMilestoneTaskCard(
        title: 'Tacts people, pets, characters, or favorite objects',
        zeroCriteria: 'Does not tact',
        halfCriteria:
            'Tact 1 nonverbal stimulus, but not if he calls everything by the same name',
        oneCriteria: 'Tacts any 2 items 1',
        item1: 'Item 1: Mom / Dad',
        item1Key: 'l1_tact_1',
        item2: 'Item 2: Ball / Car',
        item2Key: 'l1_tact_2',
      ),
      const SizedBox(height: 24),
      _buildCategoryBadge('LISTENER RESPONDING'),
      const SizedBox(height: 16),
      _buildMilestoneTaskCard(
        title: 'Attends to a speaker\'s voice by orienting toward the speaker',
        zeroCriteria: 'Does not attend to speaker',
        halfCriteria: 'Attends occasionally when name is called',
        oneCriteria: 'Consistently orients toward speaker in 5 trials',
        item1: 'Item 1: Turn to speaker voice',
        item1Key: 'l1_lr_1',
        item2: 'Item 2: Turn to own name',
        item2Key: 'l1_lr_2',
      ),
    ];
  }

  // Level 2 Tasks (MAND + TACT)
  List<Widget> _buildLevel2Tasks() {
    return [
      _buildCategoryBadge('MAND'),
      const SizedBox(height: 16),
      _buildMilestoneTaskCard(
        title: 'Mands 20 different missing items without prompts',
        zeroCriteria: 'Does not mand for missing items',
        halfCriteria: 'Mands for 10 missing items with minimal prompts',
        oneCriteria:
            'Mands 20 different missing items without prompts (e.g. shoe/sock)',
        item1: 'Item 1: Shoe / Sock',
        item1Key: 'l2_mand_1',
        item2: 'Item 2: Paper / Crayon',
        item2Key: 'l2_mand_2',
      ),
      const SizedBox(height: 24),
      _buildCategoryBadge('TACT'),
      const SizedBox(height: 16),
      _buildMilestoneTaskCard(
        title:
            'Tacts 20 actions when asked, for example, what am I doing? jumping',
        zeroCriteria: 'Does not tact actions',
        halfCriteria: 'Tacts 10 actions with prompt',
        oneCriteria: 'Tacts 20 actions independently',
        item1: 'Item 1: Jumping / Clapping',
        item1Key: 'l2_tact_1',
        item2: 'Item 2: Running / Sleeping',
        item2Key: 'l2_tact_2',
      ),
    ];
  }

  // Level 3 Tasks (MAND + TACT)
  List<Widget> _buildLevel3Tasks() {
    return [
      _buildCategoryBadge('MAND'),
      const SizedBox(height: 16),
      _buildMilestoneTaskCard(
        title:
            'Mands for others to emit 5 different actions or directions necessary to participate in an activity',
        zeroCriteria: 'Does not mand for others\' actions',
        halfCriteria: 'Mands for 2 actions with verbal prompt',
        oneCriteria:
            'Mands for others to emit 5 actions independently (e.g. open door, push me)',
        item1: 'Item 1: Open door / Push swing',
        item1Key: 'l3_mand_1',
        item2: 'Item 2: Spin wheel / Help carry',
        item2Key: 'l3_mand_2',
      ),
      const SizedBox(height: 24),
      _buildCategoryBadge('TACT'),
      const SizedBox(height: 16),
      _buildMilestoneTaskCard(
        title: 'Tacts 200 nouns and verbs across multiple exemplars',
        zeroCriteria: 'Tacts fewer than 50 nouns/verbs',
        halfCriteria: 'Tacts 100 nouns/verbs across pictures and objects',
        oneCriteria:
            'Tacts 200 nouns and verbs generalized across natural settings',
        item1: 'Item 1: Ball / Bouncing / Rolling',
        item1Key: 'l3_tact_1',
        item2: 'Item 2: Car / Driving / Washing',
        item2Key: 'l3_tact_2',
      ),
    ];
  }

  // Level 4+ Tasks
  List<Widget> _buildLevel4Tasks() {
    return [
      _buildCategoryBadge('INTRAVERBAL'),
      const SizedBox(height: 16),
      _buildMilestoneTaskCard(
        title:
            'Answers 25 different questions containing who, what, where, or why',
        zeroCriteria: 'Answers fewer than 5 WH questions',
        halfCriteria: 'Answers 10-15 WH questions with partial prompts',
        oneCriteria: 'Answers 25 different WH questions independently',
        item1: 'Item 1: What do you wear on feet? (Shoes)',
        item1Key: 'l4_iv_1',
        item2: 'Item 2: Where do you sleep? (Bed)',
        item2Key: 'l4_iv_2',
      ),
    ];
  }

  Widget _buildCategoryBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildMilestoneTaskCard({
    required String title,
    required String zeroCriteria,
    required String halfCriteria,
    required String oneCriteria,
    required String item1,
    required String item1Key,
    required String item2,
    required String item2Key,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 12),
          // Scoring criteria table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5D5F5)),
            ),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(60),
                1: FlexColumnWidth(),
              },
              border: const TableBorder(
                horizontalInside:
                    BorderSide(color: Color(0xFFE5D5F5), width: 1),
                verticalInside: BorderSide(color: Color(0xFFE5D5F5), width: 1),
              ),
              children: [
                _buildCriteriaRow('0', zeroCriteria),
                _buildCriteriaRow('1/2', halfCriteria),
                _buildCriteriaRow('1', oneCriteria),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List Items header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('List Items',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary)),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Item added to assessment task')),
                  );
                },
                icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                label: const Text('Add',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Interactive items with switches
          _buildItemRow(item1, item1Key),
          const SizedBox(height: 8),
          _buildItemRow(item2, item2Key),
        ],
      ),
    );
  }

  TableRow _buildCriteriaRow(String score, String desc) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(score,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(desc,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildItemRow(String label, String toggleKey) {
    final isYes = _toggles[toggleKey] ?? false;
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isYes ? 'Yes' : 'No',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isYes ? const Color(0xFF10B981) : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: isYes,
                activeThumbColor: const Color(0xFF10B981),
                inactiveThumbColor: Colors.red,
                inactiveTrackColor: Colors.red.shade100,
                onChanged: (val) {
                  setState(() => _toggles[toggleKey] = val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GRAPH TAB (LEVEL 5, LEVEL 6, LEVEL 7)
  // ==========================================
  Widget _buildGraphTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Assessment Banner with Key Table
        StudentAssessmentBanner(
          studentName: _selectedStudent ?? 'Student',
          rightContent: _buildBannerKeyTable(),
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
              'Level 1 Milestone Matrix', _level1Columns, 5, 1)
        else if (_activeMilestoneGraphLevel == 2)
          _buildMilestoneMatrixCard(
              'Level 2 Milestone Matrix', _level2Columns, 10, 6)
        else
          _buildMilestoneMatrixCard(
              'Level 3 Milestone Matrix', _level3Columns, 15, 11),
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

  Widget _buildBannerKeyTable() {
    String t1Date = '—', t1Tester = '—';
    String t2Date = '—', t2Tester = '—';
    String t3Date = '—', t3Tester = '—';
    String t4Date = '—', t4Tester = '—';

    for (final m in _milestoneRecords) {
      final tNum = int.tryParse(m['test_number']?.toString() ?? '1') ?? 1;
      final d = (m['assessment_date'] ?? '').toString().split('T')[0];
      const tName = 'Ms. Priya';
      if (tNum == 1) {
        t1Date = d;
        t1Tester = tName;
      } else if (tNum == 2) {
        t2Date = d;
        t2Tester = tName;
      } else if (tNum == 3) {
        t3Date = d;
        t3Tester = tName;
      } else if (tNum == 4) {
        t4Date = d;
        t4Tester = tName;
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Text('Key',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              SizedBox(width: 32),
              Text('Date',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              SizedBox(width: 32),
              Text('Tester',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          _buildKeyRow('1st Test', const Color(0xFFFBBF24), t1Date, t1Tester),
          _buildKeyRow('2nd Test', const Color(0xFFF97316), t2Date, t2Tester),
          _buildKeyRow('3rd Test', const Color(0xFF10B981), t3Date, t3Tester),
          _buildKeyRow('4th Test', const Color(0xFF3B82F6), t4Date, t4Tester),
        ],
      ),
    );
  }

  Widget _buildKeyRow(String label, Color color, String date, String tester) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          SizedBox(
              width: 50,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          SizedBox(
              width: 65,
              child: Text(date, style: const TextStyle(fontSize: 10))),
          const SizedBox(width: 8),
          SizedBox(
              width: 45,
              child: Text(tester, style: const TextStyle(fontSize: 10))),
        ],
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
              final fitsFixed = constraints.maxWidth >= columns.length * 75;
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        child: Text(
                          col,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: AppColors.primary),
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
                        );
                      }),
                    ),
                ],
              );
              if (fitsFixed) return table;
              return ScrollableMinWidth(
                minWidth: columns.length * 56.0,
                child: table,
              );
            },
          ),
        ],
      ),
    );
  }
}
