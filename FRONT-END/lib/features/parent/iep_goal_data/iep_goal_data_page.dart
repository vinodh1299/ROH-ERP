// lib/features/parent/iep_goal_data/iep_goal_data_page.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';

class IepGoalDataPage extends StatelessWidget {
  const IepGoalDataPage({super.key});

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
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IEP Goal Mastery & VB-MAPP Tracking',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Student: Alex Thomas Sam • Comprehensive Individualized Education Plan Status',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Overview KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final crossAxisCount = isNarrow ? 2 : 4;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isNarrow ? 1.4 : 1.8,
                children: [
                  _buildStatCard('Active IEP Goals', '8', 'Active Programs', AppColors.primary),
                  _buildStatCard('Targets Mastered', '42', '+4 this month', Colors.green),
                  _buildStatCard('In Maintenance', '15', 'Generalizing', Colors.blue),
                  _buildStatCard('Next Audit Due', '18 Oct', '6-Month Review', Colors.orange),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Clinical Domain Goal Breakdown Cards
          const Text(
            'Clinical Domains & Active Milestones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),

          _buildDomainProgressCard(
            domain: '1. MANDING (Spontaneous Verbal Requests)',
            level: 'VB-MAPP Level 2 • Milestones 6-10',
            masteryRatio: 0.80,
            masteredCount: 8,
            totalCount: 10,
            color: Colors.purple,
            activeGoals: [
              'Mand 7-M: Emits 5 different mands without prompt (Mastered)',
              'Mand 8-M: Emits 2-word requests with carrier phrase (e.g. "want juice") (85% Independent)',
              'Mand 9-M: Spontaneously mands for missing items needed for an activity (Acquisition)',
            ],
          ),
          const SizedBox(height: 16),

          _buildDomainProgressCard(
            domain: '2. TACTING (Expressive Labeling of Environment)',
            level: 'VB-MAPP Level 2 • Milestones 6-10',
            masteryRatio: 0.60,
            masteredCount: 6,
            totalCount: 10,
            color: Colors.teal,
            activeGoals: [
              'Tact 6-M: Labels 25 common items across 5 categories (Mastered)',
              'Tact 7-M: Generalizes labels across 3 different pictures/exemplars (Mastered)',
              'Tact 8-M: Labels 10 ongoing actions/verbs (e.g. "jumping", "cutting") (60% Independent)',
            ],
          ),
          const SizedBox(height: 16),

          _buildDomainProgressCard(
            domain: '3. INTRAVERBALS & CONVERSATIONAL PROBES',
            level: 'VB-MAPP Level 2/3 • Milestones 11-15',
            masteryRatio: 0.40,
            masteredCount: 4,
            totalCount: 10,
            color: Colors.orange,
            activeGoals: [
              'Intraverbal 6-M: Completes 10 song lyrics and playful fill-ins (Mastered)',
              'Intraverbal 7-M: Answers simple "What is your name?" and "How old are you?" (Mastered)',
              'Intraverbal 8-M: Answers "What do you do when you are thirsty/hungry?" (In Probe)',
            ],
          ),
          const SizedBox(height: 16),

          _buildDomainProgressCard(
            domain: '4. BEHAVIOR INTERVENTION & REGULATION PLAN (BIP)',
            level: 'Functional Replacement Behavior Protocol',
            masteryRatio: 0.90,
            masteredCount: 9,
            totalCount: 10,
            color: Colors.indigo,
            activeGoals: [
              'BIP Target 1: Functional communication card exchange for "Break Please" (95% Independent)',
              'BIP Target 2: Tolerates 5-minute work interval with visual timer (Mastered)',
              'BIP Target 3: Gentle hands transition between activity rooms (Consistent)',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String subtext, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 2),
          Text(subtext, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _buildDomainProgressCard({
    required String domain,
    required String level,
    required double masteryRatio,
    required int masteredCount,
    required int totalCount,
    required Color color,
    required List<String> activeGoals,
  }) {
    return Container(
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
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  domain,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$masteredCount / $totalCount Targets',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(level, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: masteryRatio,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // Active Goals List
          ...activeGoals.map((goal) {
            final isMastered = goal.contains('(Mastered)');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isMastered ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: isMastered ? Colors.green : AppColors.textHint,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      goal,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMastered ? AppColors.textPrimary : const Color(0xFF4B5563),
                        fontWeight: isMastered ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
