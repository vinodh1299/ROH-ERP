// lib/features/parent/graphs/graphs_page.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';

class GraphsPage extends StatelessWidget {
  const GraphsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.welcomeGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinical Performance & Skill Acquisition Graphs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Cumulative learning trends, prompt fading progression, and behavior deceleration curves',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Monthly Target Acquisition Bar Chart Card
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
                    const Icon(Icons.show_chart, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Cumulative Targets Mastered (Last 6 Months)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '+24% Velocity',
                        style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Verified under BACB mastery criteria (80% accuracy over 3 consecutive sessions across 2 therapists)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Stylized Visual Bar Chart
                LayoutBuilder(
                  builder: (context, constraints) {
                    final months = [
                      {'m': 'Apr', 'v': 14, 'pct': 0.35},
                      {'m': 'May', 'v': 20, 'pct': 0.50},
                      {'m': 'Jun', 'v': 26, 'pct': 0.65},
                      {'m': 'Jul', 'v': 31, 'pct': 0.77},
                      {'m': 'Aug', 'v': 38, 'pct': 0.90},
                      {'m': 'Sep (Current)', 'v': 42, 'pct': 1.0},
                    ];

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: months.map((data) {
                        final val = data['v'] as int;
                        final pct = data['pct'] as double;
                        final monthName = data['m'] as String;
                        final isCurrent = monthName.contains('Sep');

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '$val',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: constraints.maxWidth > 500 ? 44 : 28,
                              height: 160 * pct,
                              decoration: BoxDecoration(
                                gradient: isCurrent
                                    ? AppColors.welcomeGradient
                                    : LinearGradient(
                                        colors: [AppColors.primaryLight, AppColors.primary.withValues(alpha: 0.4)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              monthName,
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 500 ? 12 : 10,
                                color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Prompt Level Breakdown Card
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
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_motion, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Prompt Fading Hierarchy & Independence Level',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Distribution of prompting needed across all daily trials during September sessions',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                _buildPromptLevelRow('Independent (Unprompted)', 0.62, '62% of trials', Colors.green),
                const SizedBox(height: 12),
                _buildPromptLevelRow('Gestural / Point Prompt', 0.22, '22% of trials', Colors.blue),
                const SizedBox(height: 12),
                _buildPromptLevelRow('Verbal / Phonemic Prompt', 0.11, '11% of trials', Colors.orange),
                const SizedBox(height: 12),
                _buildPromptLevelRow('Physical Guidance Prompt', 0.05, '5% of trials', Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptLevelRow(String label, double ratio, String percentageText, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(percentageText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}
