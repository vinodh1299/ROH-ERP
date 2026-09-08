// lib/features/therapist/manding_sheet/manding_sheet_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MandingSheetPage extends StatefulWidget {
  const MandingSheetPage({super.key});

  @override
  State<MandingSheetPage> createState() => _MandingSheetPageState();
}

class _MandingSheetPageState extends State<MandingSheetPage> {
  String _selectedStudent = 'Aarav Patel (Age: 8)';

  final List<Map<String, dynamic>> _mands = [
    {'mand': 'Water', 'type': 'Verbal', 'prompt': 'Independent', 'frequency': 8},
    {'mand': 'Juice', 'type': 'Verbal', 'prompt': 'Verbal Prompt', 'frequency': 4},
    {'mand': 'Ball', 'type': 'Sign', 'prompt': 'Independent', 'frequency': 6},
    {'mand': 'Open Door', 'type': 'Verbal', 'prompt': 'Gestural Prompt', 'frequency': 3},
    {'mand': 'Break', 'type': 'PECS Card', 'prompt': 'Independent', 'frequency': 5},
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
                colors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.record_voice_over_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manding Target Sheet & Frequency Graphs',
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
                  child: const Text('Total Mands Today: 26', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF8E24AA))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Manding Bar Graph Card
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
                const Text('Daily Manding Frequency Bar Graph', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _mands.map((m) {
                      final freq = m['frequency'] as int;
                      final maxFreq = 10;
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('$freq', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8E24AA))),
                            const SizedBox(height: 4),
                            FractionallySizedBox(
                              heightFactor: freq / maxFreq,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFAB47BC),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(m['mand'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Manding Data Table
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
                const Text('Target Manding Data Log', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Mand Target')),
                    DataColumn(label: Text('Response Type')),
                    DataColumn(label: Text('Prompt Level')),
                    DataColumn(label: Text('Daily Count')),
                  ],
                  rows: _mands.map((m) {
                    return DataRow(cells: [
                      DataCell(Text(m['mand'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(m['type'])),
                      DataCell(Text(m['prompt'])),
                      DataCell(Text('${m['frequency']} times')),
                    ]);
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
