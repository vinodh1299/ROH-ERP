import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';

class TransitionAssessmentPage extends StatefulWidget {
  const TransitionAssessmentPage({super.key});

  @override
  State<TransitionAssessmentPage> createState() => _TransitionAssessmentPageState();
}

class _TransitionAssessmentPageState extends State<TransitionAssessmentPage> {
  String? _selectedStudent = 'Alex Thomas Sam';
  int _activeTab = 0; // 0: Assessment, 1: Graph

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
        onStudentAction: (student) {
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
          // Header Row with Student Name & Back Button + Tabs + Yellow instruction badge
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
                    '$_selectedStudent VB MAPP Transition Assessment',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
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
                  const SizedBox(width: 16),
                  // Yellow Instruction Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_activeTab == 0) ...[
            // Student Assessment Banner
            StudentAssessmentBanner(
              studentName: _selectedStudent ?? 'Alex Thomas Sam',
            ),
            const SizedBox(height: 20),

            // Transition assessment cards
            for (final area in _transitionAreas) ...[
              _buildTransitionCard(area['title'] as String, area['options'] as List<String>),
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
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transition Assessment Saved Successfully!')),
                    );
                    setState(() => _selectedStudent = null);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentAssessmentBanner(
          studentName: _selectedStudent ?? 'Alex Thomas Sam',
        ),
        const SizedBox(height: 24),
        Container(
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 280,
                        child: Text(
                          _transitionAreas[i]['title'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: List.generate(5, (scoreIdx) {
                            final score = scoreIdx + 1;
                            final isAchieved = score <= 3; // sample score rating
                            return Expanded(
                              child: Container(
                                height: 28,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: isAchieved ? AppColors.primary : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$score',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAchieved ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransitionCard(String title, List<String> options) {
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
          // Left Options Column
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
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                              options[i],
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Right Assessment Score Column
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
}
