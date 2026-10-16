import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import '../../../core/services/db_queries.dart';
import '../widgets/student_card_grid.dart';
import 'widgets/incident_stopwatch.dart';
import 'widgets/daily_data_chart_painters.dart';

class DailyDataSheetPage extends StatefulWidget {
  const DailyDataSheetPage({super.key});

  @override
  State<DailyDataSheetPage> createState() => _DailyDataSheetPageState();
}

class _DailyDataSheetPageState extends State<DailyDataSheetPage> {
  String? _selectedStudent;
  int? _selectedStudentId;
  int _activeTab = 0; // 0: Manding, 1: Manding Graph, 2: Daily Data Sheet, 3: Skill Tracking Sheet, 4: Acquisition Graph, 5: ABC Data, 6: BRP, 7: PB Graph, 8: IEP Report

  // Manding Filters & State
  late String _mandingDate;
  late String _mandingTimeIn;
  late String _mandingTimeOut;

  // Manding Grid Counters
  final List<String> _mandingColumns = ['FP', 'PP', 'FM/FV', 'PM/PV', 'F3', 'F5', 'F6', 'F6', 'Error', 'Vocal'];
  final List<Map<String, dynamic>> _mandingRows = [];

  // Daily Data Sheet DTT Filters & State
  late String _ddsDate;
  late String _ddsTimeIn;
  late String _ddsTimeOut;
  bool _mandingGoalsExpanded = true;
  bool _listenerGoalsExpanded = true;
  bool _tactingGoalsExpanded = false;
  bool _vpGoalsExpanded = false;
  final List<Map<String, dynamic>> _dttTargets = [];

  // Manding Graph Filters & State
  late String _mgFromDate;
  late String _mgToDate;
  final List<Map<String, dynamic>> _mandingGraphData = [];

  // Skill Tracking Sheet
  String _skillDomain = 'Manding';
  String _skillGoal = 'emit 10 different mands without prompts';
  final List<Map<String, dynamic>> _skillTargets = [];

  // Acquisition Graph Filters
  late String _acqFromDate;
  late String _acqToDate;
  String _acqDomain = 'Manding';
  final List<Map<String, dynamic>> _acquisitionGraphData = [];

  // ABC Data Sheet
  final List<Map<String, dynamic>> _abcIncidents = [];

  // PB Graph State
  String _pbGraphType = 'Behavior Data';
  final List<Map<String, dynamic>> _pbDurationData = [];
  final List<Map<String, dynamic>> _pbMultiBehaviorData = [];

  final List<String> _tabs = [
    'Manding',
    'Manding Graph',
    'Daily Data Sheet',
    'Skill Tracking Sheet',
    'Acquisition Graph',
    'ABC Data',
    'BRP',
    'PB Graph',
    'IEP Report',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final dFormat = DateFormat('MM/dd/yyyy').format(now);
    final tFormat = DateFormat('hh:mm a').format(now);
    final tOutFormat = DateFormat('hh:mm a').format(now.add(const Duration(hours: 1)));

    _mandingDate = dFormat;
    _mandingTimeIn = tFormat;
    _mandingTimeOut = tOutFormat;

    _ddsDate = DateFormat('dd-MM-yyyy').format(now);
    _ddsTimeIn = DateFormat('HH:mm').format(now);
    _ddsTimeOut = DateFormat('HH:mm').format(now.add(const Duration(hours: 1)));

    _mgFromDate = dFormat;
    _mgToDate = dFormat;

    _acqFromDate = dFormat;
    _acqToDate = dFormat;
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

  void _onStudentSelected(String studentName, [int? id]) {
    setState(() {
      _selectedStudent = studentName;
      _selectedStudentId = id ?? _resolveStudentId(studentName);
      _activeTab = 0;
      _loadStudentData();
    });
  }

  Future<void> _loadStudentData() async {
    if (_selectedStudentId == null) return;
    try {
      final records = await DailyDataQueries.fetchForStudent(_selectedStudentId.toString());
      if (mounted) {
        setState(() {
          _mandingRows.clear();
          _dttTargets.clear();
          _mandingGraphData.clear();
          _skillTargets.clear();
          _acquisitionGraphData.clear();
          _abcIncidents.clear();
          _pbDurationData.clear();
          _pbMultiBehaviorData.clear();

          int cumulativeMastered = 0;

          for (final r in records) {
            final domain = (r['domain'] ?? '').toString();
            final domainLower = domain.toLowerCase();
            final sessionDateRaw = (r['session_date'] ?? '').toString();
            String formattedDate = sessionDateRaw;
            try {
              if (sessionDateRaw.isNotEmpty) {
                final dt = DateTime.parse(sessionDateRaw.split('T')[0]);
                formattedDate = DateFormat('dd-MMM').format(dt);
              }
            } catch (_) {}

            final completed = int.tryParse(r['trials_completed']?.toString() ?? '0') ?? 0;
            final successful = int.tryParse(r['trials_successful']?.toString() ?? '0') ?? 0;
            final targetSkill = (r['target_skill'] ?? 'Target Skill').toString();
            final prompt = (r['prompt_level'] ?? 'Independent').toString();
            final notes = (r['notes'] ?? '').toString();

            // 1. Manding Sheet & Manding Graph
            if (domainLower == 'manding') {
              final counts = List.generate(10, (idx) {
                if (idx < successful) return 1;
                if (idx < completed) return 2;
                return 0;
              });
              _mandingRows.add({
                'label': targetSkill,
                'counts': counts,
              });

              final promptedCount = (completed - successful).clamp(0, 999);
              final unpromptedCount = successful;
              _mandingGraphData.add({
                'date': formattedDate,
                'prompted': promptedCount,
                'unprompted': unpromptedCount,
              });
            }

            // 2. DTT Targets & Skill Acquisition (All instructional skill domains)
            if (!domainLower.contains('abc') && !domainLower.contains('problem behavior')) {
              _dttTargets.add({
                'domain': domain,
                'target': targetSkill,
                'prompt': prompt,
                'trials': completed,
                'success': successful,
                'pct': r['percentage_success'] ?? '0.00',
              });

              _skillTargets.add({
                'target': targetSkill,
                'introduced': formattedDate,
                'mastered': successful >= 8 ? 'Mastered' : 'In Acquisition',
              });

              if (successful > 0) {
                cumulativeMastered += successful;
                _acquisitionGraphData.add({
                  'date': formattedDate,
                  'count': cumulativeMastered,
                });
              }
            }

            // 3. ABC Incidents & Behavior Duration / Deceleration
            if (domainLower.contains('abc') || domainLower.contains('behavior')) {
              int durMins = 0;
              final durMatch = RegExp(r'Duration\s+(\d+)\s+mins', caseSensitive: false).firstMatch(notes);
              if (durMatch != null) {
                durMins = int.tryParse(durMatch.group(1) ?? '0') ?? 0;
              } else {
                durMins = completed > 0 ? completed : 2;
              }

              _abcIncidents.add({
                'timeLabel': '$formattedDate $targetSkill',
                'date': sessionDateRaw.split('T')[0],
                'time': '10:00 AM',
                'setting': 'Classroom 1A',
                'antecedent': notes.contains('Antecedent:') ? notes.split('Antecedent:')[1].split('.')[0].trim() : 'Work Demand',
                'antecedentNote': '',
                'behavior': targetSkill,
                'count': completed > 0 ? completed : 1,
                'timeMins': durMins,
                'consequence': notes.contains('Consequence:') ? notes.split('Consequence:')[1].trim() : 'Prompted redirect',
                'consequenceNote': '',
                'isExpanded': false,
              });

              _pbDurationData.add({
                'date': formattedDate,
                'duration': durMins,
              });

              final bUpper = targetSkill.toUpperCase();
              _pbMultiBehaviorData.add({
                'date': formattedDate,
                'FLOP': bUpper.contains('FLOP') ? (completed > 0 ? completed : 1) : 0,
                'HIT': bUpper.contains('HIT') ? (completed > 0 ? completed : 1) : 0,
                'KICK': bUpper.contains('KICK') ? (completed > 0 ? completed : 1) : 0,
                'BOLT': bUpper.contains('BOLT') ? (completed > 0 ? completed : 1) : 0,
                'GRAB': bUpper.contains('GRAB') ? (completed > 0 ? completed : 1) : 0,
                'CRYING': bUpper.contains('CRY') ? (completed > 0 ? completed : 1) : 0,
                'WHINE': bUpper.contains('WHINE') ? (completed > 0 ? completed : 1) : 0,
                'Throwing': bUpper.contains('THROW') ? (completed > 0 ? completed : 1) : 0,
                'Bite': bUpper.contains('BITE') ? (completed > 0 ? completed : 1) : 0,
              });
            }
          }
        });
      }
    } catch (_) {}
  }

  void _addNewIncident() {
    final now = DateTime.now();
    setState(() {
      _abcIncidents.insert(0, {
        'timeLabel': DateFormat('MM-dd-yyyy hh:mm a').format(now),
        'date': DateFormat('MM/dd/yyyy').format(now),
        'time': DateFormat('hh:mm a').format(now),
        'setting': '',
        'antecedent': 'Work Demand',
        'antecedentNote': '',
        'behavior': 'Hit',
        'count': 1,
        'timeMins': 0,
        'consequence': 'Ignored problem behaviour',
        'consequenceNote': '',
        'isExpanded': true,
      });
    });
  }

  void _addNewMandRow() {
    setState(() {
      _mandingRows.add({
        'label': 'Item ${_mandingRows.length + 1}',
        'counts': List.generate(10, (_) => 0),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStudent == null) {
      return StudentCardGrid(
        title: 'Students Daily Data Analysis',
        buttonLabel: 'View',
        onStudentAction: (student, studentId) => _onStudentSelected(student, studentId),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Back Button & Student Title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => setState(() => _selectedStudent = null),
                tooltip: 'Back to students',
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 18),
                  children: [
                    TextSpan(
                      text: '$_selectedStudent ',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    TextSpan(
                      text: _activeTab == 5
                          ? 'ABC Data Sheet'
                          : (_activeTab == 6
                              ? 'BRP'
                              : (_activeTab == 7 ? 'PBH Graph' : 'Daily Data Analysis')),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Pink/Lavender Container matching Screenshot
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 650),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tab Bar Container
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_tabs.length, (index) => _buildTabItem(_tabs[index], index)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Active Tab Content
                _buildActiveTabContent(),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
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
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? const Color(0xFF7E22CE) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildMandingTab();
      case 1:
        return _buildMandingGraphTab();
      case 2:
        return _buildDailyDataSheetDttTab();
      case 3:
        return _buildSkillTrackingTab();
      case 4:
        return _buildAcquisitionGraphTab();
      case 5:
        return _buildAbcDataTab();
      case 6:
        return _buildBrpTab();
      case 7:
        return _buildPbGraphTab();
      case 8:
        return _buildIepReportTab();
      default:
        return _buildMandingTab();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 1. MANDING TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMandingTab() {
    int totalPrompted = 0;
    int totalUnprompted = 0;
    for (final r in _mandingRows) {
      final counts = r['counts'] as List<int>;
      for (int i = 0; i < counts.length; i++) {
        if (i < 8) {
          totalPrompted += counts[i];
        } else {
          totalUnprompted += counts[i];
        }
      }
    }
    final int grandTotal = totalPrompted + totalUnprompted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Filter Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC084FC), Color(0xFFD8B4FE)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildFilterPill('Date:', _mandingDate, 140),
              const SizedBox(width: 16),
              _buildFilterPill('Time In:', _mandingTimeIn, 130),
              const SizedBox(width: 16),
              _buildFilterPill('Time Out:', _mandingTimeOut, 130),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addNewMandRow,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Row'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_mandingRows.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: const Center(
              child: Text(
                'No manding trial records logged for this session.\nClick "+ Add Row" above to begin recording.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
          )
        else ...[
          // Grid Table Header
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD8B4FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC084FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Mands', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                ),
                Expanded(
                  child: Row(
                    children: _mandingColumns.map((col) {
                      return Expanded(
                        child: Center(
                          child: Text(col, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Container(
                  width: 70,
                  alignment: Alignment.center,
                  child: const Text('Vocal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Manding Rows
          ..._mandingRows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            final counts = row['counts'] as List<int>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 120,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC084FC),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                          ),
                          child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(row['label'] ?? 'Mand', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Row(
                      children: List.generate(counts.length, (colIdx) {
                        return Expanded(
                          child: Container(
                            height: 38,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(color: const Color(0xFFE9D5FF)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (counts[colIdx] > 0) {
                                      setState(() => counts[colIdx]--);
                                    }
                                  },
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(color: Color(0xFFE9D5FF), shape: BoxShape.circle),
                                    child: const Center(child: Text('-', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE)))),
                                  ),
                                ),
                                Text('${counts[colIdx]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => counts[colIdx]++);
                                  },
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(color: Color(0xFFE9D5FF), shape: BoxShape.circle),
                                    child: const Center(child: Text('+', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE)))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Container(
                    width: 70,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: Text(row['label'] ?? 'Vocal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 20),

        // Dynamic Summary Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryBox('Prompted', '$totalPrompted'),
            _buildSummaryBox('Unprompted', '$totalUnprompted'),
            _buildSummaryBox('Total', '$grandTotal'),
          ],
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFE9D5FF),
                foregroundColor: const Color(0xFF7E22CE),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session data saved successfully.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 2. MANDING GRAPH TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMandingGraphTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC084FC), Color(0xFFD8B4FE)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildFilterPill('From Date:', _mgFromDate, 140),
              const SizedBox(width: 16),
              _buildFilterPill('To Date:', _mgToDate, 140),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Search'),
              ),
              const Spacer(),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC084FC)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: Color(0xFF9333EA)),
                    SizedBox(width: 6),
                    Text('Line Graph', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          height: 340,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: MandingLineChart(data: _mandingGraphData),
        ),
        const SizedBox(height: 24),

        if (_mandingGraphData.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC084FC)),
            ),
            child: const Center(
              child: Text(
                'No recorded session data found for this date range.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontFamily: 'Poppins'),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC084FC)),
            ),
            child: Table(
              border: TableBorder.all(color: const Color(0xFFE9D5FF)),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFFAF5FF)),
                  children: [
                    const Padding(padding: EdgeInsets.all(8), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ..._mandingGraphData.map((d) => Padding(padding: const EdgeInsets.all(8), child: Text(d['date'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)))),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(padding: EdgeInsets.all(8), child: Text('Prompted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ..._mandingGraphData.map((d) => Padding(padding: const EdgeInsets.all(8), child: Text('${d['prompted'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)))),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(padding: EdgeInsets.all(8), child: Text('Unprompted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ..._mandingGraphData.map((d) => Padding(padding: const EdgeInsets.all(8), child: Text('${d['unprompted'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)))),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 3. DAILY DATA SHEET DTT TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildDailyDataSheetDttTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC084FC), Color(0xFFD8B4FE)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildFilterPill('Date:', _ddsDate, 130),
              const SizedBox(width: 16),
              _buildFilterPill('Time In:', _ddsTimeIn, 110),
              const SizedBox(width: 16),
              _buildFilterPill('Time Out:', _ddsTimeOut, 110),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFED7AA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Date Introduced: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Container(width: 40, height: 10, color: const Color(0xFFB91C1C)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Date Mastered:   ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Container(width: 40, height: 10, color: const Color(0xFF15803D)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildAccordionSection(
          title: 'MANDING GOALS',
          isExpanded: _mandingGoalsExpanded,
          onToggle: () => setState(() => _mandingGoalsExpanded = !_mandingGoalsExpanded),
          child: _buildDttDomainTargets('mand', 'No active manding targets logged for this student.'),
        ),
        const SizedBox(height: 12),

        _buildAccordionSection(
          title: 'LISTENER RESPONDING GOALS',
          isExpanded: _listenerGoalsExpanded,
          onToggle: () => setState(() => _listenerGoalsExpanded = !_listenerGoalsExpanded),
          child: _buildDttDomainTargets('listener', 'No active listener responding targets logged for this student.'),
        ),
        const SizedBox(height: 12),

        _buildAccordionSection(
          title: 'TACTING GOALS',
          isExpanded: _tactingGoalsExpanded,
          onToggle: () => setState(() => _tactingGoalsExpanded = !_tactingGoalsExpanded),
          child: _buildDttDomainTargets('tact', 'No active tacting targets logged for this student.'),
        ),
        const SizedBox(height: 12),

        _buildAccordionSection(
          title: 'VISUAL PERCEPTUAL SKILLS AND MATCHING-TO-SAMPLE',
          isExpanded: _vpGoalsExpanded,
          onToggle: () => setState(() => _vpGoalsExpanded = !_vpGoalsExpanded),
          child: _buildDttDomainTargets('vp', 'No active VP/MTS targets logged for this student.'),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 4. SKILL TRACKING SHEET TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildSkillTrackingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC084FC), Color(0xFFD8B4FE)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _skillDomain,
                    items: ['Manding', 'Tacting', 'Listener', 'Echoic'].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))).toList(),
                    onChanged: (val) => setState(() => _skillDomain = val!),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const Text('ITP GOAL: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
              const SizedBox(width: 8),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _skillGoal,
                    items: [
                      'emit 10 different mands without prompts',
                      'label 20 common household objects',
                    ].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))).toList(),
                    onChanged: (val) => setState(() => _skillGoal = val!),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _skillTargets.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No cumulative mastered targets logged for this student in this goal.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Target', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 3, child: Text('Date Introduced', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 3, child: Text('Date Mastered', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._skillTargets.map((t) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(t['target'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                            Expanded(flex: 3, child: Text(t['introduced'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                            Expanded(flex: 3, child: Text(t['mastered'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 5. ACQUISITION GRAPH TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildAcquisitionGraphTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC084FC), Color(0xFFD8B4FE)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildFilterPill('From Date:', _acqFromDate, 140),
              const SizedBox(width: 16),
              _buildFilterPill('To Date:', _acqToDate, 140),
              const Spacer(),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _acqDomain,
                    items: ['Manding', 'Tacting', 'Listener', 'Echoic'].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))).toList(),
                    onChanged: (val) => setState(() => _acqDomain = val!),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          height: 340,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: AcquisitionLineChart(data: _acquisitionGraphData),
        ),
        const SizedBox(height: 24),

        if (_acquisitionGraphData.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC084FC)),
            ),
            child: const Center(
              child: Text(
                'No target acquisition count records found for this student.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontFamily: 'Poppins'),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC084FC)),
            ),
            child: Table(
              border: TableBorder.all(color: const Color(0xFFE9D5FF)),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFFAF5FF)),
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(8), child: Text('Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                ..._acquisitionGraphData.map((d) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(8), child: Text(d['date'] ?? '', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${d['count'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF7E22CE)))),
                  ],
                )),
              ],
            ),
          ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 6. ABC DATA TAB (Live Incident Stopwatch & Dynamic Form)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildAbcDataTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: _addNewIncident,
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16, color: Color(0xFF7E22CE)),
                  SizedBox(width: 4),
                  Text('+ Add Incident', style: TextStyle(color: Color(0xFF7E22CE), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_abcIncidents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: const Center(
              child: Text(
                'No antecedent-behavior-consequence (ABC) incidents logged for this student.\nClick "+ Add Incident" above to record a live behavior event with stopwatch tracking.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
          )
        else
          ..._abcIncidents.map((incident) {
            final isExpanded = incident['isExpanded'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC084FC), Color(0xFFD8B4FE)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => incident['isExpanded'] = !isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            incident['timeLabel'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                          ),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isExpanded)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildFilterPill('Date:', incident['date'], 130),
                              const SizedBox(width: 20),
                              _buildFilterPill('Time:', incident['time'], 130),
                            ],
                          ),
                          const SizedBox(height: 14),

                          const Text('Setting Events:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            height: 38,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE9D5FF))),
                            child: TextField(
                              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), hintText: 'Enter setting events or environmental triggers'),
                              onChanged: (val) => incident['setting'] = val,
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text('Antecedent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                height: 38,
                                width: 200,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE9D5FF))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: incident['antecedent'],
                                    items: ['Work Demand', 'Denied Access', 'Transition', 'Attention'].map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 12)))).toList(),
                                    onChanged: (val) => setState(() => incident['antecedent'] = val!),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('Note:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE9D5FF))),
                                  child: TextField(
                                    decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                    onChanged: (val) => incident['antecedentNote'] = val,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          const Text('Behaviors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                height: 38,
                                width: 200,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE9D5FF))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: incident['behavior'],
                                    items: ['Hit', 'Scream', 'Elopement', 'Bite', 'Throwing'].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))).toList(),
                                    onChanged: (val) => setState(() => incident['behavior'] = val!),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('Count: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 6),
                              _buildMiniCounter(incident['count'], (val) => setState(() => incident['count'] = val)),
                              const SizedBox(width: 16),
                              const Text('Time(mint): ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 6),
                              _buildMiniCounter(incident['timeMins'], (val) => setState(() => incident['timeMins'] = val)),
                              const SizedBox(width: 16),

                              // Real Interactive Digital Stopwatch with Start/Stop/Reset
                              IncidentStopwatch(
                                onMinutesUpdated: (mins) {
                                  setState(() {
                                    incident['timeMins'] = mins;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          const Text('Consequences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                height: 38,
                                width: 200,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE9D5FF))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: incident['consequence'],
                                    items: ['Ignored problem behaviour', 'Redirected to task', 'Given break', 'Response block'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                                    onChanged: (val) => setState(() => incident['consequence'] = val!),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('Note:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE9D5FF))),
                                  child: TextField(
                                    decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                    onChanged: (val) => incident['consequenceNote'] = val,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 7. BRP TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildBrpTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_selectedStudent',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        const Text(
          'BEHAVIOUR REDUCTION PLAN (BRP)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          alignment: Alignment.topLeft,
          child: Text(_selectedStudent ?? 'Student Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 16),

        const Text('What is the form of the problem behaviors?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE9D5FF))),
          child: const TextField(
            maxLines: 2,
            decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12), hintText: 'Describe physical topography of observed behaviors...'),
          ),
        ),
        const SizedBox(height: 16),

        const Text('DESCRIPTION OF PROBLEM BEHAVIOURS FUNCTION OF PROBLEM BEHAVIOURS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),

        const Text('Which variables have reinforced and continue to maintain the problem behaviours?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE9D5FF))),
          child: const TextField(
            maxLines: 2,
            decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12), hintText: 'Identify maintaining variables and functions...'),
          ),
        ),
        const SizedBox(height: 16),

        const Text('MEASUREMENT OF PROBLEM BEHAVIOURS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE9D5FF))),
          child: const TextField(
            maxLines: 2,
            decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12), hintText: 'Specify measurement metric (Frequency, Duration, Latency, PIR)...'),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFE9D5FF),
                foregroundColor: const Color(0xFF7E22CE),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Save'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Print'),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 8. PB GRAPH TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildPbGraphTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _pbGraphType,
                  items: [
                    'Behavior Data',
                    'Problem Behaviour Duration',
                    'Problem Behaviour Duration Graph',
                    'Behavior Data Graph',
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (val) => setState(() => _pbGraphType = val!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (_pbGraphType == 'Problem Behaviour Duration')
          _buildPbDurationTable()
        else if (_pbGraphType == 'Problem Behaviour Duration Graph')
          _buildPbDurationGraph()
        else if (_pbGraphType == 'Behavior Data Graph')
          _buildPbMultiBehaviorGraph()
        else
          Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: const Center(
              child: Text(
                'Problem Behavior Trend Analysis\n(Select Graph or Table view from dropdown)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPbDurationTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC084FC)),
      ),
      child: _pbDurationData.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No problem behavior duration records logged for this student.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              ),
            )
          : Table(
              border: TableBorder.all(color: const Color(0xFFE9D5FF)),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFFAF5FF)),
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(8), child: Text('DURATION (MINS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                ..._pbDurationData.map((d) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(8), child: Text(d['date'] ?? '', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${d['duration'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF7E22CE)))),
                  ],
                )),
              ],
            ),
    );
  }

  Widget _buildPbDurationGraph() {
    return Container(
      height: 330,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        children: [
          const Text('DURATION (MINS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 12),
          Expanded(
            child: PbDurationLineChart(data: _pbDurationData),
          ),
        ],
      ),
    );
  }

  Widget _buildPbMultiBehaviorGraph() {
    return Container(
      height: 330,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildLegendItem('FLOP', const Color(0xFF2563EB)),
              _buildLegendItem('HIT', const Color(0xFFDC2626)),
              _buildLegendItem('KICK', const Color(0xFF16A34A)),
              _buildLegendItem('BOLT', const Color(0xFF7C3AED)),
              _buildLegendItem('GRAB', const Color(0xFF0891B2)),
              _buildLegendItem('CRYING', const Color(0xFFEA580C)),
              _buildLegendItem('WHINE', const Color(0xFF0284C7)),
              _buildLegendItem('Throwing', const Color(0xFF991B1B)),
              _buildLegendItem('Bite', const Color(0xFF4D7C0F)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PbMultiBehaviorLineChart(data: _pbMultiBehaviorData),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 9. IEP REPORT TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildIepReportTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IEP Daily Session Takeaways & Objectives', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('Session summary notes and clinical objectives tracked for parent and supervisor review.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildFilterPill(String label, String value, double width) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 8),
        Container(
          width: width,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF7E22CE)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBox(String label, String count) {
    return Container(
      width: 180,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCounter(int count, ValueChanged<int> onChanged) {
    return Container(
      height: 28,
      decoration: BoxDecoration(color: const Color(0xFFE9D5FF), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (count > 0) onChanged(count - 1);
            },
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7E22CE)))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          InkWell(
            onTap: () => onChanged(count + 1),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('+', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7E22CE)))),
          ),
        ],
      ),
    );
  }

  Widget _buildDttDomainTargets(String domainKey, String emptyMessage) {
    final targets = _dttTargets.where((t) {
      final d = (t['domain'] ?? '').toString().toLowerCase();
      if (domainKey == 'mand') return d.contains('mand');
      if (domainKey == 'listener') return d.contains('listener');
      if (domainKey == 'tact') return d.contains('tact');
      if (domainKey == 'vp') return d.contains('vp') || d.contains('visual') || d.contains('matching');
      return false;
    }).toList();

    if (targets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            emptyMessage,
            style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: targets.map((t) {
        final target = (t['target'] ?? '').toString();
        final prompt = (t['prompt'] ?? '').toString();
        final trials = t['trials'] ?? 0;
        final success = t['success'] ?? 0;
        final pct = (t['pct'] ?? '0.00').toString();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3B0764)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Prompt Level: $prompt',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Text(
                  'Trials: $success / $trials',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B21A8)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccordionSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black87),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}
