// lib/features/therapist/ees_assessment/ees_assessment_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class EesAssessmentPage extends StatefulWidget {
  const EesAssessmentPage({super.key});

  @override
  State<EesAssessmentPage> createState() => _EesAssessmentPageState();
}

class _EesAssessmentPageState extends State<EesAssessmentPage> {
  String _selectedStudent = 'Aarav Patel (Age: 8)';
  double _eesScore = 68.5;

  final List<Map<String, dynamic>> _subtests = [
    {'group': 'Group 1: Simple Vowels & Consonants', 'targets': 'ah, ee, oo, m, b, p', 'score': 12.0, 'max': 12.0},
    {'group': 'Group 2: Consonant-Vowel Combinations', 'targets': 'ma, ba, pa, da, ta', 'score': 18.0, 'max': 20.0},
    {'group': 'Group 3: Multisyllabic Words', 'targets': 'cookie, mommy, daddy, baby', 'score': 15.5, 'max': 20.0},
    {'group': 'Group 4: Consonant Blends & Phrases', 'targets': 'play, blue, stop, go now', 'score': 23.0, 'max': 30.0},
  ];

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
                colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.record_voice_over_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Early Echoic Skills (EES) Assessment',
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
                    'EES Score: $_eesScore / 82.0',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF3F51B5)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subtests
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _subtests.length,
            itemBuilder: (ctx, i) {
              final sub = _subtests[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(sub['group'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const Spacer(),
                        Text('Score: ${sub['score']} / ${sub['max']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Vocal Targets: ${sub['targets']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
