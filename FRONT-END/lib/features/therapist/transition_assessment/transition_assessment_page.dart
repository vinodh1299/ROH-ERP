// lib/features/therapist/transition_assessment/transition_assessment_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TransitionAssessmentPage extends StatefulWidget {
  const TransitionAssessmentPage({super.key});

  @override
  State<TransitionAssessmentPage> createState() => _TransitionAssessmentPageState();
}

class _TransitionAssessmentPageState extends State<TransitionAssessmentPage> {
  int _viewMode = 0; // 0 = Overview (TRANSITION ASSESSMENT.png), 1 = Add Evaluation Wizard (TRANSITION ASSESSMENT ADD-1.png)
  String _selectedStudent = 'Aarav Patel (Age: 8)';

  final List<Map<String, dynamic>> _categories = [
    {'category': '1. VB-MAPP Milestone Score Summary', 'score': '4 / 5', 'status': 'High Readiness'},
    {'category': '2. VB-MAPP Barriers Score Summary', 'score': '4 / 5', 'status': 'Low Barrier'},
    {'category': '3. VB-MAPP Fluent & Retention Score', 'score': '3 / 5', 'status': 'Moderate'},
    {'category': '4. Learning in a Group Context', 'score': '3 / 5', 'status': 'Moderate'},
    {'category': '5. Self-Help & Independence Skills', 'score': '5 / 5', 'status': 'Mastered'},
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
                colors: [Color(0xFF0288D1), Color(0xFF039BE5)],
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
                        'VB-MAPP Educational Transition Assessment',
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
                          child: Text('Overview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _viewMode == 0 ? const Color(0xFF0288D1) : Colors.white)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _viewMode = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: _viewMode == 1 ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                          child: Text('Add Transition Entry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _viewMode == 1 ? const Color(0xFF0288D1) : Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _viewMode == 0 ? _buildOverviewView(context) : _buildAddWizardView(context),
        ],
      ),
    );
  }

  // Frame 1: Overview View (TRANSITION ASSESSMENT.png)
  Widget _buildOverviewView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('School Transition Readiness Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Spacer(),
              Text('Overall Transition Score: 19 / 25 (76%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0288D1))),
            ],
          ),
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('Transition Area')),
              DataColumn(label: Text('Score (1-5)')),
              DataColumn(label: Text('Readiness Status')),
            ],
            rows: _categories.map((c) {
              return DataRow(cells: [
                DataCell(Text(c['category'], style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(c['score'])),
                DataCell(Text(c['status'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Frame 2: Add Transition Entry Wizard (TRANSITION ASSESSMENT ADD-1.png)
  Widget _buildAddWizardView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New School Transition Assessment Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'Transition Category Area', hintText: 'e.g. Group Learning Context', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          const TextField(decoration: InputDecoration(labelText: 'Assessed Score (1 to 5)', hintText: '1 = Low readiness, 5 = High readiness', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          const TextField(decoration: InputDecoration(labelText: 'Therapist Placement Notes', hintText: 'Enter school readiness notes...', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() => _viewMode = 0);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transition Assessment Saved!'), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1), foregroundColor: Colors.white),
            child: const Text('Save Transition Entry'),
          ),
        ],
      ),
    );
  }
}
