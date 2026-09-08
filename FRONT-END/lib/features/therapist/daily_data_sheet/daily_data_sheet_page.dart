// lib/features/therapist/daily_data_sheet/daily_data_sheet_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DailyDataSheetPage extends StatefulWidget {
  const DailyDataSheetPage({super.key});

  @override
  State<DailyDataSheetPage> createState() => _DailyDataSheetPageState();
}

class _DailyDataSheetPageState extends State<DailyDataSheetPage> {
  String _selectedStudent = 'Aarav Patel (Age: 8)';
  String _selectedDate = '2026-09-08';

  final List<Map<String, dynamic>> _targets = [
    {
      'target': 'Eye Contact on Name Call',
      'domain': 'Attending',
      'prompt': 'Independent',
      'trials': 10,
      'correct': 8,
    },
    {
      'target': 'Mand for Preferred Snack',
      'domain': 'Verbal Behavior',
      'prompt': 'Verbal Prompt',
      'trials': 8,
      'correct': 6,
    },
    {
      'target': '3-Step Motor Imitation',
      'domain': 'Imitation',
      'prompt': 'Gestural Prompt',
      'trials': 5,
      'correct': 3,
    },
    {
      'target': 'Tact 5 Common Objects',
      'domain': 'Tact',
      'prompt': 'Independent',
      'trials': 10,
      'correct': 9,
    },
    {
      'target': 'Wait Patiently for 2 mins',
      'domain': 'Tolerance',
      'prompt': 'Full Physical',
      'trials': 4,
      'correct': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    int totalTrials = 0;
    int totalCorrect = 0;
    for (var t in _targets) {
      totalTrials += t['trials'] as int;
      totalCorrect += t['correct'] as int;
    }
    double overallPercentage = totalTrials > 0 ? (totalCorrect / totalTrials * 100) : 0;

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
                colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Discrete Trial & Skill Acquisition Data Sheet',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text('Date: $_selectedDate | Student: $_selectedStudent',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Overall Accuracy: ${overallPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF00897B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Student & Date Selection Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStudent,
                      isExpanded: true,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      items: ['Aarav Patel (Age: 8)', 'Emma Watson (Age: 7)', 'Rahul Sharma (Age: 9)']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedStudent = v!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Daily Data Sheet saved successfully!')),
                  );
                },
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save Data Sheet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Target Tracking Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Target Skill Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => _showAddTargetDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Target'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _targets.length,
                  separatorBuilder: (_, __) => const Divider(height: 20),
                  itemBuilder: (ctx, index) {
                    final target = _targets[index];
                    final trials = target['trials'] as int;
                    final correct = target['correct'] as int;
                    final percent = trials > 0 ? (correct / trials * 100).toStringAsFixed(0) : '0';

                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(target['target'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text('Domain: ${target['domain']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        // Prompt Selector
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: target['prompt'],
                                isExpanded: true,
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                items: ['Independent', 'Verbal Prompt', 'Gestural Prompt', 'Full Physical']
                                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                    .toList(),
                                onChanged: (v) => setState(() => target['prompt'] = v!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Counter controls
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                              onPressed: () {
                                if (target['correct'] > 0) {
                                  setState(() {
                                    target['correct'] = (target['correct'] as int) - 1;
                                  });
                                }
                              },
                            ),
                            Text('$correct / $trials', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                              onPressed: () {
                                setState(() {
                                  target['correct'] = (target['correct'] as int) + 1;
                                  if (target['correct'] > target['trials']) {
                                    target['trials'] = target['correct'];
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Percentage Pill
                        Container(
                          width: 55,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$percent%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTargetDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final domainCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Target Skill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Target Skill Name')),
            const SizedBox(height: 12),
            TextField(controller: domainCtrl, decoration: const InputDecoration(labelText: 'Domain (e.g. Tact, Mand)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _targets.add({
                    'target': nameCtrl.text,
                    'domain': domainCtrl.text.isEmpty ? 'General' : domainCtrl.text,
                    'prompt': 'Independent',
                    'trials': 10,
                    'correct': 0,
                  });
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Target'),
          ),
        ],
      ),
    );
  }
}
