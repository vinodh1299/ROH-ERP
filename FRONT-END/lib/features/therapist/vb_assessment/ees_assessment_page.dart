import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/layout/responsive.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';

class EesAssessmentPage extends StatefulWidget {
  const EesAssessmentPage({super.key});

  @override
  State<EesAssessmentPage> createState() => _EesAssessmentPageState();
}

class _EesAssessmentPageState extends State<EesAssessmentPage> {
  String? _selectedStudent;

  // Track response state: 0 = None, 1 = No, 2 = Yes, 3 = Half
  final Map<String, int> _responses = {};

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
          });
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('EES Assessment Saved Successfully!')),
                  );
                  setState(() => _selectedStudent = null);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
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
                  _buildScoreRow('1ST'),
                  const SizedBox(height: 6),
                  _buildScoreRow('2ND'),
                  const SizedBox(height: 6),
                  _buildScoreRow('3RD'),
                  const SizedBox(height: 6),
                  _buildScoreRow('4TH'),
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

  Widget _buildScoreRow(String label) {
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
          child: const TextField(
            textAlign: TextAlign.center,
            decoration: InputDecoration(
                border: InputBorder.none, contentPadding: EdgeInsets.zero),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
