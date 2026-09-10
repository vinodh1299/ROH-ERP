import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';

class BarriersAssessmentPage extends StatefulWidget {
  const BarriersAssessmentPage({super.key});

  @override
  State<BarriersAssessmentPage> createState() => _BarriersAssessmentPageState();
}

class _BarriersAssessmentPageState extends State<BarriersAssessmentPage> {
  String? _selectedStudent = 'Alex Thomas Sam';
  int _activeTab = 0; // 0: Assessment, 1: Graph

  @override
  Widget build(BuildContext context) {
    if (_selectedStudent == null) {
      return StudentCardGrid(
        title: 'Students VB MAPP Barriers Assessment',
        buttonLabel: 'Add',
        onStudentAction: (student) {
          setState(() {
            _selectedStudent = student;
            _activeTab = 0;
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
                    '$_selectedStudent VB MAPP Barriers Assessment',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              // Legend table
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendRow('0', 'No problem'),
                    _LegendRow('1', 'Occasional problem'),
                    _LegendRow('2', 'Moderate problem'),
                    _LegendRow('3', 'Persistent problem'),
                    _LegendRow('4', 'Severe problem'),
                  ],
                ),
              ),
            ],
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
        StudentAssessmentBanner(studentName: _selectedStudent ?? 'Alex Thomas Sam'),
        const SizedBox(height: 20),
        _buildBarriersList(),
      ],
    );
  }

  Widget _buildBarriersList() {
    final barriers = [
      'Negative Behaviors',
      'Instructional Control',
      'Impaired Mand',
      'Impaired Tact',
      'Impaired Motor Imitation',
      'Impaired Echoic',
    ];

    return Column(
      children: [
        for (final title in barriers) ...[
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
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Barriers Assessment Saved Successfully!')),
                );
                setState(() => _activeTab = 1);
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
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
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
                _buildScoreOption('0', 'Does not demonstrate any significant negative behaviors'),
                _buildScoreOption('1', 'Engages in some minor negative behaviors weekly, but recovery is quick'),
                _buildScoreOption('2', 'Emits a variety of minor negative behaviors daily (e.g., crying, verbal refusal)'),
                _buildScoreOption('3', 'Emits more severe negative behavior daily (e.g., tantrums, throwing things)'),
                _buildScoreOption('4', 'Often emits severe negative behavior that is a danger to himself or others'),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Assessment score boxes
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Assessment Score',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                _buildScoreInputRow('1ST'),
                const SizedBox(height: 8),
                _buildScoreInputRow('2ND'),
                const SizedBox(height: 8),
                _buildScoreInputRow('3RD'),
                const SizedBox(height: 8),
                _buildScoreInputRow('4TH'),
              ],
            ),
          ),
        ],
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInputRow(String label) {
    return Row(
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
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
          child: const TextField(
            textAlign: TextAlign.center,
            decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ── 2. GRAPH VIEW (18 BARRIER CHARTS) ──
  Widget _buildGraphView() {
    final chartTitles = [
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentAssessmentBanner(studentName: _selectedStudent ?? 'Alex Thomas Sam'),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 6;
            if (constraints.maxWidth < 1300) crossAxisCount = 4;
            if (constraints.maxWidth < 900) crossAxisCount = 3;
            if (constraints.maxWidth < 600) crossAxisCount = 2;

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
                return _buildBarrierChartCard(chartTitles[index], index);
              },
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBarrierChartCard(String title, int chartIndex) {
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
            child: _buildBarrierGrid(chartIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildBarrierGrid(int chartIndex) {
    // 5 rows (0 to 4), 4 columns (1st to 4th test)
    // Row 4 is top, Row 0 is bottom
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 4;
        final cellHeight = constraints.maxHeight / 5;

        return Column(
          children: List.generate(5, (rowIndex) {
            // rowIndex 0 is level 4, rowIndex 4 is level 0
            final level = 4 - rowIndex;
            return Row(
              children: List.generate(4, (colIndex) {
                // colIndex 0 = 1st test (Green), 1 = 2nd test (Orange), 2 = 3rd (Red), 3 = 4th (Blue)
                Color cellColor = Colors.transparent;

                // Color simulation based on Figma
                if (colIndex == 0 && level <= 1) {
                  cellColor = const Color(0xFF10B981); // Green
                } else if (colIndex == 1 && level == 0) {
                  cellColor = const Color(0xFFF59E0B); // Orange
                }

                return Container(
                  width: cellWidth,
                  height: cellHeight,
                  decoration: BoxDecoration(
                    color: cellColor,
                    border: Border.all(color: const Color(0xFFE5D5F5), width: 0.8),
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
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
