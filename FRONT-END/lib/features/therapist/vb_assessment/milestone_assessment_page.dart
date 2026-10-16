import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/services/db_queries.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';

class MilestoneAssessmentPage extends StatefulWidget {
  const MilestoneAssessmentPage({super.key});

  @override
  State<MilestoneAssessmentPage> createState() => _MilestoneAssessmentPageState();
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
      final res = await MilestoneAssessmentQueries.fetchForStudent(_selectedStudentId.toString());
      if (mounted) {
        setState(() {
          _milestoneRecords = res;
        });
      }
    } catch (_) {}
  }

  final List<String> _level1Columns = [
    'Mand', 'Tact', 'Listener', 'VP/ MTS', 'Play', 'Social', 'Imitation', 'Echoic', 'Vocal'
  ];

  final List<String> _level2Columns = [
    'Mand', 'Tact', 'Listener', 'VP/ MTS', 'Play', 'Social', 'Imitation', 'Echoic', 'LRFFC', 'Intraverbal', 'Group', 'Linguistics'
  ];

  final List<String> _level3Columns = [
    'Mand', 'Tact', 'Listener', 'VP/ MTS', 'Play', 'Social', 'Reading', 'LRFFC', 'writing', 'Intraverbal', 'Group', 'Linguistics', 'Math'
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                    onPressed: () => setState(() => _selectedStudent = null),
                    tooltip: 'Back to students',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_selectedStudent VB MAPP Milestone Assessment',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              // Assessment | Graph Tabs
              Container(
                height: 40,
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
              ),
            ],
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              // Assessment Dropdown
              Container(
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
                    items: ['Assessment 1', 'Assessment 2', 'Assessment 3', 'Assessment 4'].map((a) {
                      return DropdownMenuItem(
                        value: a,
                        child: Text(a, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedAssessment = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // + Add Button
              InkWell(
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
                      Text('+ Add', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Level Selector Dropdown
              Container(
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
                        child: Text('Level $lvl', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLevel = val);
                    },
                  ),
                ),
              ),
              const Spacer(),

              // Total Score: 5.5 Badge
              Container(
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
                  children: [
                    const Text(
                      'Total Score: ',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                    ),
                    Text(
                      _selectedLevel == 1 ? '5.5' : (_selectedLevel == 2 ? '7.0' : '9.5'),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
            ],
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Milestone Assessment Level $_selectedLevel Saved Successfully!')),
                      );
                      setState(() => _selectedStudent = null);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
        halfCriteria: 'Tact 1 nonverbal stimulus, but not if he calls everything by the same name',
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
        oneCriteria: 'Mands 20 different missing items without prompts (e.g. shoe/sock)',
        item1: 'Item 1: Shoe / Sock',
        item1Key: 'l2_mand_1',
        item2: 'Item 2: Paper / Crayon',
        item2Key: 'l2_mand_2',
      ),
      const SizedBox(height: 24),

      _buildCategoryBadge('TACT'),
      const SizedBox(height: 16),
      _buildMilestoneTaskCard(
        title: 'Tacts 20 actions when asked, for example, what am I doing? jumping',
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
        title: 'Mands for others to emit 5 different actions or directions necessary to participate in an activity',
        zeroCriteria: 'Does not mand for others\' actions',
        halfCriteria: 'Mands for 2 actions with verbal prompt',
        oneCriteria: 'Mands for others to emit 5 actions independently (e.g. open door, push me)',
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
        oneCriteria: 'Tacts 200 nouns and verbs generalized across natural settings',
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
        title: 'Answers 25 different questions containing who, what, where, or why',
        zeroCriteria: 'Answers fewer than 5 WH questions',
        halfCriteria: 'Answers 10-15 WH questions with partial prompts',
        oneCriteria: 'Answers 25 different WH questions independently',
        item1: 'Item 1: What do you wear on feet? (Shoes)',
        item1Key: 'l1_tact_1',
        item2: 'Item 2: Where do you sleep? (Bed)',
        item2Key: 'l1_tact_2',
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'Poppins'),
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
                horizontalInside: BorderSide(color: Color(0xFFE5D5F5), width: 1),
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
              const Text('List Items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item added to assessment task')),
                  );
                },
                icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                label: const Text('Add', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
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
          child: Text(score, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildItemRow(String label, String toggleKey) {
    final isYes = _toggles[toggleKey] ?? false;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          Row(
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
        Row(
          children: [
            _buildLevelGraphButton('Level 1', 1),
            const SizedBox(width: 12),
            _buildLevelGraphButton('Level 2', 2),
            const SizedBox(width: 12),
            _buildLevelGraphButton('Level 3', 3),
          ],
        ),
        const SizedBox(height: 20),

        // Milestone Matrix Grid
        if (_activeMilestoneGraphLevel == 1)
          _buildMilestoneMatrixCard('Level 1 Milestone Matrix', _level1Columns, 5, 1)
        else if (_activeMilestoneGraphLevel == 2)
          _buildMilestoneMatrixCard('Level 2 Milestone Matrix', _level2Columns, 10, 6)
        else
          _buildMilestoneMatrixCard('Level 3 Milestone Matrix', _level3Columns, 15, 11),
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
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'),
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
              Text('Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              SizedBox(width: 32),
              Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              SizedBox(width: 32),
              Text('Tester', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          SizedBox(width: 65, child: Text(date, style: const TextStyle(fontSize: 10))),
          const SizedBox(width: 8),
          SizedBox(width: 45, child: Text(tester, style: const TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  double _getScoreForColumn(Map<String, dynamic> m, String colName) {
    final lower = colName.toLowerCase();
    if (lower.contains('mand')) return double.tryParse(m['manding_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('tact')) return double.tryParse(m['tacting_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('listener')) return double.tryParse(m['listener_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('vp') || lower.contains('mts')) return double.tryParse(m['vp_mts_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('play')) return double.tryParse(m['play_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('social')) return double.tryParse(m['social_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('imitation')) return double.tryParse(m['imitation_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('echoic')) return double.tryParse(m['echoic_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('vocal')) return double.tryParse(m['vocal_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('lrffc')) return double.tryParse(m['lrffc_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('intraverbal')) return double.tryParse(m['intraverbal_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('group')) return double.tryParse(m['group_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('linguistic')) return double.tryParse(m['linguistic_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('reading')) return double.tryParse(m['reading_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('writing')) return double.tryParse(m['writing_score']?.toString() ?? '0') ?? 0.0;
    if (lower.contains('math')) return double.tryParse(m['math_score']?.toString() ?? '0') ?? 0.0;
    return 0.0;
  }

  Widget _buildMilestoneMatrixCard(String title, List<String> columns, int maxRow, int minRow) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(75),
              border: TableBorder.all(color: const Color(0xFFE5E7EB), width: 1),
              children: [
                // Header row
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFEDE9FE)),
                  children: columns.map((col) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Text(
                        col,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                      ),
                    );
                  }).toList(),
                ),
                // Matrix Data Rows (from maxRow down to minRow)
                for (int row = maxRow; row >= minRow; row--)
                  TableRow(
                    children: List.generate(columns.length, (colIdx) {
                      final colName = columns[colIdx];
                      Color cellColor = Colors.white;

                      // Colour each milestone by the first test in which it was achieved
                      int? firstTest;
                      for (final m in _milestoneRecords) {
                        final tNum = int.tryParse(m['test_number']?.toString() ?? '1') ?? 1;
                        final score = _getScoreForColumn(m, colName);
                        if (score >= row && (firstTest == null || tNum < firstTest)) {
                          firstTest = tNum;
                        }
                      }
                      if (firstTest == 1) {
                        cellColor = const Color(0xFFFBBF24); // Yellow (1st Test)
                      } else if (firstTest == 2) {
                        cellColor = const Color(0xFFF97316); // Orange (2nd Test)
                      } else if (firstTest == 3) {
                        cellColor = const Color(0xFF10B981); // Green (3rd Test)
                      } else if (firstTest == 4) {
                        cellColor = const Color(0xFF3B82F6); // Blue (4th Test)
                      }

                      return Container(
                        height: 38,
                        color: cellColor,
                        alignment: Alignment.center,
                        child: Text(
                          '$row',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cellColor == Colors.white ? AppColors.textSecondary : Colors.black87,
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
