// lib/features/therapist/iep/iep_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TherapistIepPage extends StatefulWidget {
  const TherapistIepPage({super.key});

  @override
  State<TherapistIepPage> createState() => _TherapistIepPageState();
}

class _TherapistIepPageState extends State<TherapistIepPage> {
  String _selectedStudent = 'Aarav Patel (Age: 8)';
  String _selectedDomain = 'All Domains';

  final List<Map<String, dynamic>> _goals = [
    {
      'domain': 'Language & Communication',
      'goal': 'Student will independently mand for 10 items/activities using 2-word phrases across 3 settings.',
      'baseline': '20%',
      'target': '85%',
      'current': '72%',
      'status': 'In Progress',
      'dueDate': '2026-10-15',
    },
    {
      'domain': 'Behavioral Reduction',
      'goal': 'Decrease aggressive behavior during transitions to less than 2 incidents per week.',
      'baseline': '8/week',
      'target': '< 2/week',
      'current': '3/week',
      'status': 'In Progress',
      'dueDate': '2026-11-01',
    },
    {
      'domain': 'Social Interaction',
      'goal': 'Initiate peer interaction during structured play sessions for 5 consecutive minutes.',
      'baseline': '1 min',
      'target': '5 mins',
      'current': '4 mins',
      'status': 'Near Mastered',
      'dueDate': '2026-09-30',
    },
    {
      'domain': 'Fine & Gross Motor',
      'goal': 'Imitate 3-step gross motor action sequences upon first request.',
      'baseline': '40%',
      'target': '90%',
      'current': '90%',
      'status': 'Mastered',
      'dueDate': '2026-08-20',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredGoals = _selectedDomain == 'All Domains'
        ? _goals
        : _goals.where((g) => g['domain'] == _selectedDomain).toList();

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
                const Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Individualized Education Program (IEP) & Reports',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text('Student: $_selectedStudent', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating IEP Summary PDF Report...')),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('Export IEP Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3F51B5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Filters Row
          Row(
            children: [
              // Student selector
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
              // Domain filter
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
                      value: _selectedDomain,
                      isExpanded: true,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      items: ['All Domains', 'Language & Communication', 'Behavioral Reduction', 'Social Interaction', 'Fine & Gross Motor']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDomain = v!),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Goals Summary Cards
          Row(
            children: [
              _buildMetricTile('Total Goals', '${_goals.length}', Colors.blue),
              const SizedBox(width: 12),
              _buildMetricTile('In Progress', '2', Colors.orange),
              const SizedBox(width: 12),
              _buildMetricTile('Mastered', '1', Colors.green),
              const SizedBox(width: 12),
              _buildMetricTile('Target Completion', '82%', Colors.purple),
            ],
          ),
          const SizedBox(height: 20),

          // Goal List Section
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
                    const Text('IEP Active Target Goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => _showAddGoalDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add IEP Goal'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredGoals.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (ctx, index) {
                    final goal = filteredGoals[index];
                    Color statusColor = Colors.orange;
                    if (goal['status'] == 'Mastered') statusColor = Colors.green;
                    else if (goal['status'] == 'Near Mastered') statusColor = Colors.blue;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                goal['domain'],
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                goal['status'],
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(goal['goal'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('Baseline: ${goal['baseline']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(width: 20),
                            Text('Current: ${goal['current']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(width: 20),
                            Text('Target: ${goal['target']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const Spacer(),
                            const Icon(Icons.calendar_today, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('Due: ${goal['dueDate']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
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

  Widget _buildMetricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final goalCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New IEP Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: goalCtrl, decoration: const InputDecoration(labelText: 'Goal Description', hintText: 'Enter goal target...')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (goalCtrl.text.isNotEmpty) {
                setState(() {
                  _goals.add({
                    'domain': 'Language & Communication',
                    'goal': goalCtrl.text,
                    'baseline': '0%',
                    'target': '80%',
                    'current': '10%',
                    'status': 'In Progress',
                    'dueDate': '2026-12-31',
                  });
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Goal'),
          ),
        ],
      ),
    );
  }
}
