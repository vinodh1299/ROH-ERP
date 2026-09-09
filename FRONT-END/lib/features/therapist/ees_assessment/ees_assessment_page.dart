// lib/features/therapist/ees_assessment/ees_assessment_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class EesAssessmentPage extends StatefulWidget {
  const EesAssessmentPage({super.key});

  @override
  State<EesAssessmentPage> createState() => _EesAssessmentPageState();
}

class _EesAssessmentPageState extends State<EesAssessmentPage> {
  int _viewMode = 0; // 0 = Assessment List & Graph (EES ASSESSMENT.png), 1 = Add Evaluation Form (EES ASSESSMENT ADD.png)
  String _selectedStudent = 'Aarav Patel (Age: 8)';
  double _eesScore = 68.5;

  final List<Map<String, dynamic>> _subtests = [
    {'group': 'Group 1: Simple Vowels & Consonants', 'targets': 'ah, ee, oo, m, b, p', 'score': 12.0, 'max': 12.0, 'ratio': 1.0},
    {'group': 'Group 2: Consonant-Vowel Combinations', 'targets': 'ma, ba, pa, da, ta', 'score': 18.0, 'max': 20.0, 'ratio': 0.9},
    {'group': 'Group 3: Multisyllabic Words', 'targets': 'cookie, mommy, daddy, baby', 'score': 15.5, 'max': 20.0, 'ratio': 0.775},
    {'group': 'Group 4: Consonant Blends & Phrases', 'targets': 'play, blue, stop, go now', 'score': 23.0, 'max': 30.0, 'ratio': 0.76},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner with Frame Switcher
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
                        'Early Echoic Skills (EES) Assessment & Graphs',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text('Student: $_selectedStudent', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                // Frame Switcher Buttons
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _viewMode = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: _viewMode == 0 ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                          child: Text('EES Graphs & List', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _viewMode == 0 ? const Color(0xFF3F51B5) : Colors.white)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _viewMode = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: _viewMode == 1 ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                          child: Text('Add Vocal Entry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _viewMode == 1 ? const Color(0xFF3F51B5) : Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _viewMode == 0 ? _buildListView(context) : _buildAddFormView(context),
        ],
      ),
    );
  }

  // Frame 1: List & Visual Assessment Graph (EES ASSESSMENT.png)
  Widget _buildListView(BuildContext context) {
    return Column(
      children: [
        // EES Assessment Performance Graph
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('EES Subtest Performance Graph', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('Total EES Score: $_eesScore / 82.0', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5))),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _subtests.map((sub) {
                    final ratio = sub['ratio'] as double;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${sub['score']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5))),
                          const SizedBox(height: 4),
                          FractionallySizedBox(
                            heightFactor: ratio,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: const BoxDecoration(color: Color(0xFF5C6BC0), borderRadius: BorderRadius.vertical(top: Radius.circular(6))),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Group ${_subtests.indexOf(sub) + 1}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Subtests List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _subtests.length,
          itemBuilder: (ctx, i) {
            final sub = _subtests[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
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
    );
  }

  // Frame 2: Add Vocal Evaluation Form (EES ASSESSMENT ADD.png)
  Widget _buildAddFormView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Early Echoic Skill (EES) Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'Echoic Group', hintText: 'e.g. Group 2: Consonant-Vowel', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          const TextField(decoration: InputDecoration(labelText: 'Vocal Target (Syllables)', hintText: 'e.g. ma, ba, pa', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          const TextField(decoration: InputDecoration(labelText: 'Score Earned', hintText: 'e.g. 18.0', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() => _viewMode = 0);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('EES Vocal Entry Saved!'), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5), foregroundColor: Colors.white),
            child: const Text('Save EES Entry'),
          ),
        ],
      ),
    );
  }
}
