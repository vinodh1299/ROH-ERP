// lib/features/therapist/brp/brp_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BrpPage extends StatefulWidget {
  const BrpPage({super.key});

  @override
  State<BrpPage> createState() => _BrpPageState();
}

class _BrpPageState extends State<BrpPage> {
  String _selectedStudent = 'Aarav Patel (Age: 8)';

  final List<Map<String, dynamic>> _plans = [
    {
      'target_behavior': 'Screaming / Tantrums (Escape Function)',
      'function': 'Escape / Demand Avoidance',
      'antecedent_strategy': 'Provide 5-sec warning before task transitions & use visual timer.',
      'replacement_behavior': 'Teach student to hand "I need break" card independently.',
      'consequence_strategy': 'Withhold escape until replacement behavior is performed with prompt.',
    },
    {
      'target_behavior': 'Aggression / Pushing Peers (Attention Function)',
      'function': 'Attention Seeking',
      'antecedent_strategy': 'Provide high density of proactive praise & attention every 3 minutes.',
      'replacement_behavior': 'Teach student to tap peer on shoulder & say "Look".',
      'consequence_strategy': 'Neutral physical redirection & block attention immediately.',
    },
  ];

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
                colors: [Color(0xFFC2185B), Color(0xFFE91E63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Behavior Reduction Plan (BRP) Interventions',
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
                  child: const Text('Active BRP Plans: 2', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFC2185B))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Plan Cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _plans.length,
            itemBuilder: (ctx, i) {
              final plan = _plans[i];
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
                        Text(plan['target_behavior'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC2185B))),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(6)),
                          child: Text(plan['function'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC2185B))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _BrpSection(title: 'Antecedent Strategy', detail: plan['antecedent_strategy'], color: Colors.blue),
                    const SizedBox(height: 10),
                    _BrpSection(title: 'Replacement Behavior', detail: plan['replacement_behavior'], color: Colors.green),
                    const SizedBox(height: 10),
                    _BrpSection(title: 'Consequence Strategy', detail: plan['consequence_strategy'], color: Colors.orange),
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

class _BrpSection extends StatelessWidget {
  final String title;
  final String detail;
  final Color color;

  const _BrpSection({required this.title, required this.detail, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(detail, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
      ],
    );
  }
}
