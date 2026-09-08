// lib/features/therapist/barriers_assessment/barriers_assessment_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BarriersAssessmentPage extends StatefulWidget {
  const BarriersAssessmentPage({super.key});

  @override
  State<BarriersAssessmentPage> createState() => _BarriersAssessmentPageState();
}

class _BarriersAssessmentPageState extends State<BarriersAssessmentPage> {
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

  void _openAddBarrierDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _AddBarrierModal(
        onSaved: () {
          setState(() => _totalBarriersScore += 1);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barriers Assessment updated!'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

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
                        'VB-MAPP Barriers Assessment (0 to 4 Scale)',
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
                    'Barriers Score: $_totalBarriersScore / 96',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFE53935)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              const Text('Learning Barriers Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openAddBarrierDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Barrier Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barrier List Grid
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
                        final isSelected = index <= score && score > 0;
                        Color circleColor;
                        if (index == 0) circleColor = Colors.grey.shade300;
                        else if (index <= 2) circleColor = Colors.orange;
                        else circleColor = Colors.red;

                        return GestureDetector(
                          onTap: () => setState(() => _barrierScores[key] = index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected ? circleColor : Colors.grey.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? circleColor : Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Text(
                                '$index',
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

class _AddBarrierModal extends StatelessWidget {
  final VoidCallback onSaved;
  const _AddBarrierModal({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('Add Barrier Assessment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Barrier Category', hintText: 'e.g. Prompt Dependent', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            const TextField(decoration: InputDecoration(labelText: 'Barrier Score (0 to 4)', hintText: '0 = No barrier, 4 = Severe barrier', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                onSaved();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
              child: const Text('Save Barrier Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
