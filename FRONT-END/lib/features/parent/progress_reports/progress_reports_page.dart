// lib/features/parent/progress_reports/progress_reports_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ProgressReportsPage extends StatefulWidget {
  const ProgressReportsPage({super.key});

  @override
  State<ProgressReportsPage> createState() => _ProgressReportsPageState();
}

class _ProgressReportsPageState extends State<ProgressReportsPage> {
  final List<Map<String, dynamic>> _reports = [
    {
      'title': 'Q3 2026 Comprehensive ABA & VB-MAPP Progress Report',
      'date': 'September 1, 2026',
      'therapist': 'Sarah Adams (BCBA)',
      'status': 'Final Approved',
      'milestonesAchieved': 14,
      'overallGrowth': '+18%',
      'summary': 'Noah demonstrated significant growth in Manding and Tact domains. Behavior reduction targets met 90% compliance.',
    },
    {
      'title': 'Q2 2026 Mid-Year Developmental & Behavioral Evaluation',
      'date': 'June 15, 2026',
      'therapist': 'Sarah Adams (BCBA)',
      'status': 'Final Approved',
      'milestonesAchieved': 11,
      'overallGrowth': '+12%',
      'summary': 'Focus on early echoic imitation and fine motor skills. Reduced prompt dependency across classroom routines.',
    },
    {
      'title': 'Q1 2026 Baseline & Skill Acquisition Assessment',
      'date': 'March 10, 2026',
      'therapist': 'Michael Chen (RBT)',
      'status': 'Final Approved',
      'milestonesAchieved': 8,
      'overallGrowth': 'Baseline',
      'summary': 'Initial assessment established across Level 1 and Level 2 VB-MAPP milestone categories.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00ACC1), Color(0xFF26C6DA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Child Progress Reports & Evaluations',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text('Student: Noah Johnson | Center: ROH Autism Center', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Latest: Q3 2026', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00ACC1))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reports List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reports.length,
            itemBuilder: (ctx, i) {
              final report = _reports[i];
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
                        Expanded(
                          child: Text(
                            report['title'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Text(report['status'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(report['date'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(width: 20),
                        const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(report['therapist'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(report['summary'], style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatBadge('Milestones: ${report['milestonesAchieved']}', AppColors.primary),
                        const SizedBox(width: 10),
                        _buildStatBadge('Growth: ${report['overallGrowth']}', Colors.purple),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Downloading ${report['title']} PDF...')),
                            );
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Download Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
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

  Widget _buildStatBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
