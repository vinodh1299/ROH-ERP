// lib/features/therapist/transition_assessment/transition_assessment_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TransitionAssessmentPage extends StatefulWidget {
  const TransitionAssessmentPage({super.key});

  @override
  State<TransitionAssessmentPage> createState() => _TransitionAssessmentPageState();
}

class _TransitionAssessmentPageState extends State<TransitionAssessmentPage> {
  String _selectedStudent = 'Aarav Patel (Age: 8)';
  int _totalTransitionScore = 64;

  final Map<String, int> _transitionScores = {
    '1. Overall VB-MAPP Milestone Score': 4,
    '2. Overall VB-MAPP Barriers Score': 3,
    '3. Negative Behaviors': 4,
    '4. Classroom Routines & Group Skills': 3,
    '5. Social Interaction Skills': 3,
    '6. Independence in Task Completion': 4,
    '7. Generalization of Skills': 4,
    '8. Reinforcer Dependency': 3,
    '9. Self-Care Skills': 4,
    '10. Adaptability to Change': 3,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF009688), Color(0xFF26A69A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.transfer_within_a_station, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VB-MAPP Transition Assessment (18 Categories)',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text('Student: $_selectedStudent', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    'Transition Readiness: $_totalTransitionScore / 90',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF009688)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Category Readiness List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transitionScores.length,
            itemBuilder: (ctx, i) {
              final key = _transitionScores.keys.elementAt(i);
              final score = _transitionScores[key]!;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        final val = index + 1;
                        final isSelected = val <= score;

                        return GestureDetector(
                          onTap: () => setState(() => _transitionScores[key] = val),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF009688) : Colors.grey.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? const Color(0xFF009688) : Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Text(
                                '$val',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
