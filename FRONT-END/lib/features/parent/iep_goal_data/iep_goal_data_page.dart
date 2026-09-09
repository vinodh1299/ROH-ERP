// lib/features/parent/iep_goal_data/iep_goal_data_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class IepGoalDataPage extends StatefulWidget {
  const IepGoalDataPage({super.key});

  @override
  State<IepGoalDataPage> createState() => _IepGoalDataPageState();
}

class _IepGoalDataPageState extends State<IepGoalDataPage> {
  final List<Map<String, dynamic>> _goals = [
    {
      'domain': 'Language & Communication',
      'title': 'Mand for 10 Items using 2-Word Phrases',
      'baseline': '20%',
      'current': '78%',
      'target': '85%',
      'status': 'On Track',
      'progress': 0.78,
    },
    {
      'domain': 'Behavior Reduction',
      'title': 'Decrease Transition Disruption to < 2 / Week',
      'baseline': '8 / week',
      'current': '3 / week',
      'target': '< 2 / week',
      'status': 'On Track',
      'progress': 0.85,
    },
    {
      'domain': 'Social Interaction',
      'title': 'Peer Play Initiation for 5 Minutes',
      'baseline': '1 min',
      'current': '4 mins',
      'target': '5 mins',
      'status': 'Near Mastered',
      'progress': 0.80,
    },
    {
      'domain': 'Fine Motor Skills',
      'title': '3-Step Motor Imitation Sequences',
      'baseline': '40%',
      'current': '90%',
      'target': '90%',
      'status': 'Mastered 🎉',
      'progress': 1.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Noah\'s Active IEP Goals & Achievement Data', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Updated weekly by Primary BCBA', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Overall Goal Completion: 83%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5E35B1))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Goals List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _goals.length,
            itemBuilder: (ctx, i) {
              final g = _goals[i];
              Color statusColor = Colors.orange;
              if (g['status'].toString().contains('Mastered')) statusColor = Colors.green;
              else if (g['status'] == 'On Track') statusColor = Colors.blue;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(g['domain'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                          child: Text(g['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(g['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(value: g['progress'] as double, backgroundColor: Colors.grey.shade200, color: statusColor, minHeight: 8),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Baseline: ${g['baseline']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Current: ${g['current']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('Target: ${g['target']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
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
