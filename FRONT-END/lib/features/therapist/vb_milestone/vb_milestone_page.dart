// lib/features/therapist/vb_milestone/vb_milestone_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class VbMilestonePage extends StatefulWidget {
  const VbMilestonePage({super.key});

  @override
  State<VbMilestonePage> createState() => _VbMilestonePageState();
}

class _VbMilestonePageState extends State<VbMilestonePage> {
  int _selectedLevelIndex = 0;
  String _selectedStudent = 'Aarav Patel (Age: 8)';

  final List<String> _levels = ['Level 1 (0-18m)', 'Level 2 (18-30m)', 'Level 3 (30-48m)'];
  final List<String> _domains = ['MAND', 'TACT', 'LISTENER', 'VP/MTS', 'PLAY', 'SOCIAL', 'MOTOR', 'ECHOIC', 'VOCAL'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C4FD6), Color(0xFFBB6FEE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VB-MAPP Milestone Progress Grid',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text('Student: $_selectedStudent', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStudent,
                      dropdownColor: const Color(0xFF9C4FD6),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: ['Aarav Patel (Age: 8)', 'Emma Watson (Age: 7)', 'Rahul Sharma (Age: 9)']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedStudent = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Level Switcher Tabs
          Row(
            children: List.generate(_levels.length, (index) {
              final isSelected = index == _selectedLevelIndex;
              Color activeColor;
              if (index == 0) activeColor = const Color(0xFF16DBAA);
              else if (index == 1) activeColor = const Color(0xFFFF9800);
              else activeColor = const Color(0xFF2196F3);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLevelIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? activeColor : AppColors.divider),
                      boxShadow: isSelected
                          ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Text(
                      _levels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Milestone Matrix Grid Container (NEW UI Bar Chart)
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
                    Text(
                      '${_levels[_selectedLevelIndex]} Milestone Score Matrix',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    const Text('Total Milestones Mastered: 14 / 45', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 20),

                // Domain Headers
                Row(
                  children: _domains.map((d) {
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Bar Chart Visual Grid
                SizedBox(
                  height: 380,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade50),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _MilestoneBar(levelIndex: _selectedLevelIndex, heightFactor: 0.8, score: '4/5'),
                        _MilestoneBar(levelIndex: _selectedLevelIndex, heightFactor: 1.0, score: '5/5'),
                        _MilestoneBar(levelIndex: _selectedLevelIndex, heightFactor: 0.6, score: '3/5'),
                        _MilestoneBar(levelIndex: _selectedLevelIndex, heightFactor: 0.4, score: '2/5'),
                        _MilestoneBar(levelIndex: _selectedLevelIndex, heightFactor: 0.8, score: '4/5'),
                        _MilestoneBar(levelIndex: _selectedLevelIndex, heightFactor: 0.5, score: '2.5/5'),
                        _MilestoneBar(levelIndex: _selectedLevelIndex, heightFactor: 0.7, score: '3.5/5'),
                        _MilestoneBar(levelIndex: _selectedLevelIndex, heightFactor: 0.9, score: '4.5/5'),
                        _MilestoneBar(levelIndex: _selectedLevelIndex, heightFactor: 0.6, score: '3/5'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneBar extends StatelessWidget {
  final int levelIndex;
  final double heightFactor;
  final String score;

  const _MilestoneBar({required this.levelIndex, required this.heightFactor, required this.score});

  @override
  Widget build(BuildContext context) {
    Color barColor;
    if (levelIndex == 0) barColor = const Color(0xFF16DBAA);
    else if (levelIndex == 1) barColor = const Color(0xFFFF9800);
    else barColor = const Color(0xFF2196F3);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(score, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: barColor)),
          const SizedBox(height: 4),
          FractionallySizedBox(
            heightFactor: heightFactor,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
