import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/db_queries.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';

class EesAssessmentPage extends StatefulWidget {
  const EesAssessmentPage({super.key});

  @override
  State<EesAssessmentPage> createState() => _EesAssessmentPageState();
}

class _EesAssessmentPageState extends State<EesAssessmentPage> {
  String? _selectedStudent;
  int? _selectedStudentId;
  List<Map<String, dynamic>> _eesaRecords = [];
  int _testNumber = 1; // which of the 4 assessments this probe is
  bool _saving = false;
  static const _testLabels = ['1ST', '2ND', '3RD', '4TH'];

  // Track response state: 0 = None, 1 = No, 2 = Yes, 3 = Half
  final Map<String, int> _responses = {};
  static const _responseNames = {1: 'No', 2: 'Yes', 3: 'Half'};

  /// Yes = 1 point, Half = 1/2 point, No / unscored = 0.
  double _groupScore(String prefix) {
    var total = 0.0;
    _responses.forEach((key, v) {
      if (!key.startsWith('${prefix}_')) return;
      if (v == 2) total += 1;
      if (v == 3) total += 0.5;
    });
    return total;
  }

  String _formatScore(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Future<void> _loadEesaData() async {
    final studentId = _selectedStudentId;
    if (studentId == null) return;
    final res = await EesaAssessmentQueries.fetchForStudent('$studentId');
    if (mounted) setState(() => _eesaRecords = res);
  }

  /// Group 1 score of the latest saved record for [testNum], if any.
  double? _savedGroup1Score(int testNum) {
    Map<String, dynamic>? latest;
    for (final r in _eesaRecords) {
      if ((int.tryParse(r['test_number']?.toString() ?? '') ?? 1) != testNum) {
        continue;
      }
      final id = int.tryParse(r['id']?.toString() ?? '') ?? 0;
      if (latest == null ||
          id > (int.tryParse(latest['id']?.toString() ?? '') ?? 0)) {
        latest = r;
      }
    }
    if (latest == null) return null;
    return double.tryParse(latest['group1_score']?.toString() ?? '');
  }

  Map<String, String> _groupResponses(String prefix, List<String> items) => {
        for (int i = 0; i < items.length; i++)
          if (_responseNames.containsKey(_responses['${prefix}_$i']))
            items[i]: _responseNames[_responses['${prefix}_$i']]!,
      };

  Future<void> _saveEesaAssessment() async {
    final studentId = _selectedStudentId;
    if (studentId == null || _saving) return;
    if (_responses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Score at least one item before saving.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final g1 = _groupScore('g1');
    final g2 = _groupScore('g2');
    final ok = await EesaAssessmentQueries.save({
      'student_id': studentId,
      'test_number': _testNumber,
      'assessment_date': DateTime.now().toIso8601String().substring(0, 10),
      'group1_score': g1,
      'group2_score': g2,
      'total_score': g1 + g2,
      'responses': {
        'group1': _groupResponses('g1', _group1Items),
        'group2': _groupResponses('g2', _group2Items),
      },
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the EES assessment. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('EES Assessment Saved Successfully!')),
    );
    setState(() => _responses.clear());
    await _loadEesaData();
  }

  final List<String> _group1Items = [
    'ah',
    'ee',
    'oo',
    'oh',
    'ay',
    'm',
    'b',
    'p',
    'w',
    'h',
    'mama',
    'bye',
    'uh-oh',
    'baby',
    'pup',
    'moo',
    'neigh',
    'night',
    'hi',
    'me',
    'cookie',
    'bubble',
    'open',
    'bottle',
    'happy',
  ];

  final List<String> _group2Items = [
    'no-no',
    'dada',
    'kitty',
    'ball',
    'go',
    'eat',
    'shoe',
    'car',
    'up',
    'hot',
    'two',
    'key',
    'see',
    'light',
    'cup',
    'boat',
  ];

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
            _responses.clear();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scoring Group 1 - 3 For each item, score the best response upto 3 trials',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins'),
                    children: [
                      TextSpan(
                          text: 'Yes',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              ' - Correct sounds and correct number of syllables - 1 point    '),
                      TextSpan(
                          text: 'No',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              ' - No response, incorrect vowels, or missing syllables - 0 point\n'),
                      TextSpan(
                          text: 'Half',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              ' - Recognizable response, but incorrect or missing consonants or extra syllables - 1/2 point'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Group 1 Card
          _buildGroup1Card(),
          const SizedBox(height: 16),

          // Group 2 Card
          _buildGroup2Card(),
          const SizedBox(height: 24),

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: _saving ? null : _saveEesaAssessment,
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
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGroup1Card() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + target description
          _buildGroupHeader(
            'Group - 1 Simple and reduplicated syllables',
            'Targets: vowels, diphthongs, consonants p, b, m, n, h, w\nProbe: 1',
          ),
          const SizedBox(height: 16),

          // First 20 items in 4 columns
          _buildSyllableGrid([
            for (int i = 0; i < 20; i++)
              _buildSyllableItem('g1_$i', _group1Items[i]),
          ]),
          const SizedBox(height: 16),

          // Bottom section: 5 items on left + Subtotal & Assessment Score on right.
          // Narrow: items flow in the grid, the score column stacks below.
          LayoutBuilder(
            builder: (context, constraints) {
              const subTotal = Column(
                children: [
                  Text(
                    'Sub Total',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    'Group - 1',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                ],
              );
              // Assessment score table
              final scoreTable = Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Assessment Score',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  for (int t = 1; t <= 4; t++) ...[
                    if (t > 1) const SizedBox(height: 6),
                    _buildScoreRow(t),
                  ],
                ],
              );
              if (constraints.maxWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSyllableGrid([
                      for (int i = 20; i < 25; i++)
                        _buildSyllableItem('g1_$i', _group1Items[i]),
                    ]),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [subTotal, scoreTable],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 5 vertical items
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 20; i < 25; i++) ...[
                        SizedBox(
                          width: 200,
                          child: _buildSyllableItem('g1_$i', _group1Items[i]),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                  const Spacer(),
                  // Sub total text
                  const Padding(
                    padding: EdgeInsets.only(top: 24, right: 32),
                    child: subTotal,
                  ),
                  scoreTable,
                ],
              );
            },
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
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: 4),
              Text(
                targets,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: titleWidget),
            const SizedBox(width: 16),
            Text(
              targets,
              textAlign: TextAlign.right,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        );
      },
    );
  }

  /// Lays syllable items out in as many columns as fit (max 4, as on desktop).
  /// Each item keeps a readable minimum width; if even one column is too
  /// narrow the grid scrolls sideways instead of squeezing the pills.
  Widget _buildSyllableGrid(List<Widget> items) {
    const spacing = 16.0;
    const minItemWidth = 170.0;
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

  Widget _buildGroup2Card() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupHeader(
            'Group - 2 Simple and reduplicated syllables',
            'Targets: vowels, diphthongs, consonants p, b, m, n, h, w\nProbe: 2',
          ),
          const SizedBox(height: 16),
          _buildSyllableGrid([
            for (int i = 0; i < _group2Items.length; i++)
              _buildSyllableItem('g2_$i', _group2Items[i]),
          ]),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Sub Total Group - 2: ${_formatScore(_groupScore('g2'))}',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyllableItem(String key, String word) {
    final currentVal = _responses[key] ??
        0; // Starts unselected (0) until therapist administers probe

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            word,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 6),
        // Pill toggle: No | Yes | Half
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
                isSelected: currentVal == 1,
                onTap: () => setState(() => _responses[key] = 1),
                isFirst: true,
              ),
              _buildPillSegment(
                label: 'Yes',
                isSelected: currentVal == 2,
                onTap: () => setState(() => _responses[key] = 2),
              ),
              _buildPillSegment(
                label: 'Half',
                isSelected: currentVal == 3,
                onTap: () => setState(() => _responses[key] = 3),
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
            if (val != null) setState(() => _testNumber = val);
          },
        ),
      ),
    );
  }

  /// Group 1 score for test [testNum]: the live score for the test being
  /// administered (once scoring has started), otherwise the latest saved one.
  Widget _buildScoreRow(int testNum) {
    final label = _testLabels[testNum - 1];
    final isCurrent = testNum == _testNumber && _responses.isNotEmpty;
    final saved = _savedGroup1Score(testNum);
    final value = isCurrent
        ? _formatScore(_groupScore('g1'))
        : (saved == null ? '–' : _formatScore(saved));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
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
          width: 54,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.divider),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color:
                    isCurrent ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
