import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/db_queries.dart';
import '../../../core/services/vbmapp_protocol_content.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';
import 'assessment_records.dart';
import 'vbmapp_charts.dart';

/// EESA item scores of a saved record, keyed '<group>-<item>' (1-based) →
/// 1 / 0.5 / 0. Unscored items are absent. Reads the current format
/// (responses.items) and app v1 records (responses.group1/group2 keyed by
/// word, matched against the legacy word lists of the protocol content).
Map<String, double> eesaItemScoresOf(
    Map<String, dynamic> record, VbMappProtocolContent protocol) {
  final responses = jsonColumnMap(record['responses']);
  final result = <String, double>{};
  final items = jsonColumnMap(responses['items']);
  if (items.isNotEmpty) {
    items.forEach((key, v) {
      final score = double.tryParse(v.toString());
      if (score != null && (score == 0 || score == 0.5 || score == 1)) {
        result[key] = score;
      }
    });
    return result;
  }
  const legacy = {'Yes': 1.0, 'Half': 0.5, 'No': 0.0};
  final groups = protocol.eesaGroups;
  for (int g = 1; g <= 2; g++) {
    var words = protocol.eesaLegacyWords(g);
    if (words.isEmpty) words = groups[g - 1].items;
    jsonColumnMap(responses['group$g']).forEach((word, answer) {
      final index = words.indexOf(word);
      final score = legacy[answer.toString()];
      if (index >= 0 && score != null) result['$g-${index + 1}'] = score;
    });
  }
  return result;
}

/// EESA total saved for each test (null = test not saved).
double? eesaTotalOf(Map<String, dynamic>? record) => record == null
    ? null
    : double.tryParse(record['total_score']?.toString() ?? '');

class EesAssessmentPage extends StatefulWidget {
  const EesAssessmentPage({super.key});

  @override
  State<EesAssessmentPage> createState() => _EesAssessmentPageState();
}

/// Early Echoic Skills Assessment: 100 items in 5 groups (item text from the
/// protocol content file), each scored 1 (Yes), ½ (Half) or 0 (No). An item
/// left blank is "not scored", which is different from a score of 0.
class _EesAssessmentPageState extends State<EesAssessmentPage> {
  String? _selectedStudent;
  int? _selectedStudentId;
  List<Map<String, dynamic>> _eesaRecords = [];
  int _testNumber = 1; // which of the 4 assessments this probe is
  bool _saving = false;
  static const _testLabels = vbTestLabels;

  VbMappProtocolContent _protocol = VbMappProtocolContent.current;
  List<EesaGroup> get _groups => _protocol.eesaGroups;

  /// Item scores being edited: '<group>-<item>' → 1 / 0.5 / 0.
  final Map<String, double> _scores = {};

  // The saved record for this test has group scores but no item responses,
  // so the item pills can't be restored.
  bool _scoresOnly = false;

  @override
  void initState() {
    super.initState();
    VbMappProtocolContent.load().then((c) {
      if (!mounted) return;
      setState(() {
        _protocol = c;
        _prefillForTest();
      });
    });
  }

  double _groupScore(int group) {
    var total = 0.0;
    _scores.forEach((key, v) {
      if (key.startsWith('$group-')) total += v;
    });
    return total;
  }

  int _groupScoredCount(int group) =>
      _scores.keys.where((k) => k.startsWith('$group-')).length;

  double get _totalScore => [
        for (int g = 1; g <= eesaGroupCount; g++) _groupScore(g)
      ].fold(0.0, (a, b) => a + b);

  Future<void> _loadEesaData() async {
    final studentId = _selectedStudentId;
    if (studentId == null) return;
    final res = await EesaAssessmentQueries.fetchForStudent('$studentId');
    if (!mounted) return;
    setState(() {
      _eesaRecords = res;
      _prefillForTest();
    });
  }

  /// Restores the item scores from the newest saved record for the selected
  /// test, or clears them when that test has not been saved yet.
  void _prefillForTest() {
    _scores.clear();
    _scoresOnly = false;
    final record = newestRecordForTest(_eesaRecords, _testNumber);
    if (record == null) return;
    _scores.addAll(eesaItemScoresOf(record, _protocol));
    _scoresOnly = _scores.isEmpty && (eesaTotalOf(record) ?? 0) > 0;
  }

  /// Saved score of [group] (1–5) for [testNum], or null.
  double? _savedGroupScore(int testNum, int group) {
    final latest = newestRecordForTest(_eesaRecords, testNum);
    if (latest == null) return null;
    return double.tryParse(latest['group${group}_score']?.toString() ?? '');
  }

  Future<void> _saveEesaAssessment() async {
    final studentId = _selectedStudentId;
    if (studentId == null || _saving) return;
    if (_scores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Score at least one item before saving.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final error = await EesaAssessmentQueries.trySave({
      'student_id': studentId,
      'test_number': _testNumber,
      'assessment_date':
          assessmentDateFor(newestRecordForTest(_eesaRecords, _testNumber)),
      for (int g = 1; g <= eesaGroupCount; g++)
        'group${g}_score': _groupScore(g),
      'total_score': _totalScore,
      'responses': {'items': Map<String, double>.from(_scores)},
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save the EES assessment: $error'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('EES Assessment Saved Successfully!')),
    );
    await _loadEesaData();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStudent == null) {
      return StudentCardGrid(
        title: 'Students VB MAPP Early Echoic Skill Assessment (EESA)',
        buttonLabel: 'Add',
        onStudentAction: (student, studentId) {
          setState(() {
            _selectedStudent = student;
            _selectedStudentId = studentId;
            _eesaRecords = [];
            _scores.clear();
            _testNumber = 1;
          });
          _loadEesaData();
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Student Name & Back Button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => setState(() => _selectedStudent = null),
                tooltip: 'Back to students',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_selectedStudent VB MAPP EES Assessment',
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
          ),
          const SizedBox(height: 16),

          // Student Assessment Banner
          StudentAssessmentBanner(
            studentName: _selectedStudent ?? 'Student',
            records: _eesaRecords,
            scoreLabel: (r) => '${formatVbScore(eesaTotalOf(r) ?? 0)} / 100',
          ),
          const SizedBox(height: 20),

          // Purple Instruction Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF), // Light purple bg
              borderRadius: BorderRadius.circular(10),
            ),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins'),
                children: [
                  TextSpan(
                      text: 'Yes',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' = 1 point    '),
                  TextSpan(
                      text: 'Half',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' = ½ point    '),
                  TextSpan(
                      text: 'No',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' = 0 points\n'),
                  TextSpan(
                      text: 'Items left blank are not scored (not the same '
                          'as 0). Tap a selected answer again to clear it. '
                          'Use the scoring criteria of the licensed protocol.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildSummaryCard(),
          const SizedBox(height: 16),

          if (_scoresOnly) ...[
            const Text(
              'This test was saved as group scores only, so its item responses '
              'can\'t be shown. Saving it again replaces those scores with the '
              'responses marked below.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
          ],
          for (final group in _groups) ...[
            _buildGroupCard(group),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),

          // Buttons Row
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildTestSelector(),
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
                ElevatedButton(
                  onPressed: _saving ? null : _saveEesaAssessment,
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
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Group scores of every test: the live scores for the test being
  /// administered (once scoring has started), otherwise the saved ones.
  Widget _buildSummaryCard() {
    String cell(int test, int? group) {
      final isCurrent = test == _testNumber && _scores.isNotEmpty;
      if (group == null) {
        if (isCurrent) return formatVbScore(_totalScore);
        final total = eesaTotalOf(newestRecordForTest(_eesaRecords, test));
        return total == null ? '–' : formatVbScore(total);
      }
      if (isCurrent) return formatVbScore(_groupScore(group));
      final saved = _savedGroupScore(test, group);
      return saved == null ? '–' : formatVbScore(saved);
    }

    String echoic(int test) {
      final isCurrent = test == _testNumber && _scores.isNotEmpty;
      final total = isCurrent
          ? _totalScore
          : eesaTotalOf(newestRecordForTest(_eesaRecords, test));
      if (total == null) return '–';
      final e = _protocol.echoicScoreForEesaTotal(total);
      return e == null ? 'n/a' : formatVbScore(e);
    }

    const headerStyle = TextStyle(
        fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary);
    const cellStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary);
    Widget pad(Widget w) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Center(child: w));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assessment Score',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            _protocol.hasEchoicMapping
                ? 'Echoic = the Echoic milestone score this EESA total gives '
                    '(shown read-only on the Milestones page).'
                : 'Echoic milestone mapping not entered in the protocol '
                    'content file yet: Echoic is scored by hand on the '
                    'Milestones page.',
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ScrollableMinWidth(
            minWidth: 520,
            child: Table(
              border: TableBorder.all(color: AppColors.divider),
              columnWidths: const {0: FixedColumnWidth(64)},
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFEDE9FE)),
                  children: [
                    pad(const Text('Test', style: headerStyle)),
                    for (final g in _groups)
                      pad(Text('G${g.number} /${g.items.length}',
                          style: headerStyle)),
                    pad(const Text('Total /100', style: headerStyle)),
                    pad(const Text('Echoic', style: headerStyle)),
                  ],
                ),
                for (int t = 1; t <= 4; t++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: t == _testNumber
                          ? AppColors.primary.withValues(alpha: 0.06)
                          : null,
                    ),
                    children: [
                      pad(Text(_testLabels[t - 1], style: cellStyle)),
                      for (final g in _groups)
                        pad(Text(cell(t, g.number), style: cellStyle)),
                      pad(Text(cell(t, null), style: cellStyle)),
                      pad(Text(echoic(t), style: cellStyle)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(EesaGroup group) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupHeader(group.title, group.description),
          const SizedBox(height: 16),
          _buildSyllableGrid([
            for (int i = 1; i <= group.items.length; i++)
              _buildSyllableItem('${group.number}-$i', i, group.items[i - 1]),
          ]),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Sub Total Group ${group.number}: '
              '${formatVbScore(_groupScore(group.number))} / '
              '${group.items.length}  ·  scored '
              '${_groupScoredCount(group.number)} of ${group.items.length}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title, String targets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleWidget = Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
          ),
        );
        final targetsWidget = Text(
          targets,
          textAlign:
              constraints.maxWidth < 600 ? TextAlign.left : TextAlign.right,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        );
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleWidget, const SizedBox(height: 4), targetsWidget],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: titleWidget),
            const SizedBox(width: 16),
            Flexible(child: targetsWidget),
          ],
        );
      },
    );
  }

  /// Lays items out in as many columns as fit (max 4). Each item keeps a
  /// readable minimum width; if even one column is too narrow the grid
  /// scrolls sideways instead of squeezing the pills.
  Widget _buildSyllableGrid(List<Widget> items) {
    const spacing = 16.0;
    const minItemWidth = 230.0;
    return ScrollableMinWidth(
      minWidth: minItemWidth,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols =
              ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                  .floor()
                  .clamp(1, 4);
          final itemWidth =
              (constraints.maxWidth - spacing * (cols - 1)) / cols;
          return Wrap(
            spacing: spacing,
            runSpacing: 12,
            children: [
              for (final item in items) SizedBox(width: itemWidth, child: item),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSyllableItem(String key, int number, String text) {
    final current = _scores[key]; // null = not scored
    final placeholder = !isProtocolText(text);
    void choose(double v) => setState(() {
          if (current == v) {
            _scores.remove(key); // tap again → back to "not scored"
          } else {
            _scores[key] = v;
          }
        });

    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: text,
            child: Text(
              placeholder ? 'Item $number' : text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontStyle: placeholder ? FontStyle.italic : FontStyle.normal,
                  color: placeholder
                      ? AppColors.textSecondary
                      : AppColors.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Pill toggle: No | Half | Yes
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPillSegment(
                label: 'No',
                isSelected: current == 0,
                onTap: () => choose(0),
                isFirst: true,
              ),
              _buildPillSegment(
                label: 'Half',
                isSelected: current == 0.5,
                onTap: () => choose(0.5),
              ),
              _buildPillSegment(
                label: 'Yes',
                isSelected: current == 1,
                onTap: () => choose(1),
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPillSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final compact = Breakpoints.isCompact(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 8, vertical: compact ? 8 : 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(15) : Radius.zero,
            right: isLast ? const Radius.circular(15) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTestSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _testNumber,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          items: [
            for (int t = 1; t <= 4; t++)
              DropdownMenuItem(
                value: t,
                child: Text('${_testLabels[t - 1]} Assessment',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
              ),
          ],
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _testNumber = val;
              _prefillForTest();
            });
          },
        ),
      ),
    );
  }
}
