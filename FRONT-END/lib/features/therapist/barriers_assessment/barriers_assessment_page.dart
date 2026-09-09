// lib/features/therapist/barriers_assessment/barriers_assessment_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BarriersAssessmentPage extends StatefulWidget {
  const BarriersAssessmentPage({super.key});

  @override
  State<BarriersAssessmentPage> createState() => _BarriersAssessmentPageState();
}

class _BarriersAssessmentPageState extends State<BarriersAssessmentPage> {
  int _viewMode = 0; // 0 = Overview (BARRIERS ASSESSMENT.png), 1 = Master Scoring Form (BARRIERS MASTER SCORING FORM.png), 2 = Add Barrier Wizard (BARRIERS ASSESSMENT ADD-1.png & ADD-2.png)
  int _wizardStep = 1;

  String _selectedStudent = 'Aarav Patel (Age: 8)';
  int _totalBarriersScore = 12;

  final Map<String, int> _barrierScores = {
    '1. Behavior Problems': 2,
    '2. Instructional Control (Escapes)': 1,
    '3. Defective Manding': 2,
    '4. Defective Tacting': 1,
    '5. Defective Motor Imitation': 0,
    '6. Defective Echoic': 1,
    '7. Defective Matching-to-Sample': 0,
    '8. Defective Listener Responding': 1,
    '9. Defective Intraverbal': 2,
    '10. Defective Social Skills': 2,
  };

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
                colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VB-MAPP Barriers Assessment & Scoring',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text('Student: $_selectedStudent', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                // Switcher Buttons
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _viewMode = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _viewMode == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Breakdown', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _viewMode == 0 ? const Color(0xFFE53935) : Colors.white)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _viewMode = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _viewMode == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Master Form', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _viewMode == 1 ? const Color(0xFFE53935) : Colors.white)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _viewMode = 2;
                          _wizardStep = 1;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _viewMode == 2 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Add Barrier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _viewMode == 2 ? const Color(0xFFE53935) : Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Render view based on frame switcher
          if (_viewMode == 0) _buildOverviewView(context),
          if (_viewMode == 1) _buildMasterFormView(context),
          if (_viewMode == 2) _buildAddWizardView(context),
        ],
      ),
    );
  }

  // Frame 1: Barriers Overview (BARRIERS ASSESSMENT.png)
  Widget _buildOverviewView(BuildContext context) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _barrierScores.length,
          itemBuilder: (ctx, i) {
            final key = _barrierScores.keys.elementAt(i);
            final score = _barrierScores[key]!;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
              child: Row(
                children: [
                  Expanded(child: Text(key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  Row(
                    children: List.generate(5, (index) {
                      final isSelected = index <= score && score > 0;
                      Color circleColor = index == 0 ? Colors.grey.shade300 : (index <= 2 ? Colors.orange : Colors.red);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: isSelected ? circleColor : Colors.grey.shade100, shape: BoxShape.circle),
                        child: Center(child: Text('$index', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textSecondary))),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Frame 2: Barriers Master Scoring Form (BARRIERS MASTER SCORING FORM.png)
  Widget _buildMasterFormView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Barriers Master Scoring Matrix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('Barrier Area')),
              DataColumn(label: Text('Current Severity Score (0-4)')),
              DataColumn(label: Text('Intervention Plan Status')),
            ],
            rows: _barrierScores.entries.map((e) {
              return DataRow(cells: [
                DataCell(Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('${e.value} / 4', style: TextStyle(fontWeight: FontWeight.bold, color: e.value > 2 ? Colors.red : Colors.orange))),
                DataCell(Text(e.value > 0 ? 'Intervention Active' : 'No Action Needed', style: TextStyle(color: e.value > 0 ? Colors.green : Colors.grey))),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Frame 3: Add Barrier Wizard Step 1 & 2 (BARRIERS ASSESSMENT ADD-1.png & ADD-2.png)
  Widget _buildAddWizardView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Add Barrier Evaluation Wizard — Step $_wizardStep of 2', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text('Step $_wizardStep / 2', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_wizardStep == 1) ...[
            const TextField(decoration: InputDecoration(labelText: 'Target Barrier Name', hintText: 'e.g. Prompt Dependency', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            const TextField(decoration: InputDecoration(labelText: 'Observed Frequency / Duration', hintText: 'e.g. 5 times per 30-min trial', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _wizardStep = 2),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
              child: const Text('Proceed to Step 2 (Scoring)'),
            ),
          ] else ...[
            const TextField(decoration: InputDecoration(labelText: 'Assessed Barrier Severity (0 to 4)', hintText: '0 = None, 4 = Severe', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            const TextField(decoration: InputDecoration(labelText: 'Recommended BCBA Intervention Strategy', hintText: 'Enter intervention notes...', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton(onPressed: () => setState(() => _wizardStep = 1), child: const Text('Back to Step 1')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _viewMode = 0);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New Barrier Entry Saved!'), backgroundColor: Colors.green));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Save & Complete Barrier'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
