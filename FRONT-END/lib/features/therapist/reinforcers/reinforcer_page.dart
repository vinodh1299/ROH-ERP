// lib/features/therapist/reinforcers/reinforcer_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ReinforcerPage extends StatefulWidget {
  const ReinforcerPage({super.key});

  @override
  State<ReinforcerPage> createState() => _ReinforcerPageState();
}

class _ReinforcerPageState extends State<ReinforcerPage> {
  int _viewMode = 0; // 0 = Assessment & Graphs (PREFERENCE ASSESSMENT.png), 1 = Add Item Form (PREFERENCE ITEM ADD.png)
  String _selectedStudent = 'Aarav Patel (Age: 8)';

  final List<Map<String, dynamic>> _items = [
    {'item': 'Apple Juice / Gummy Bears', 'category': 'Edible', 'preference': 'High Preference', 'score': 95},
    {'item': 'Tickles & High Fives', 'category': 'Social', 'preference': 'High Preference', 'score': 90},
    {'item': 'Light-Up Spin Toy', 'category': 'Toys/Materials', 'preference': 'Moderate Preference', 'score': 70},
    {'item': 'Bubbles / Music Video', 'category': 'Sensory/Other', 'preference': 'High Preference', 'score': 85},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner with Frame Switcher
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_outline, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VB-MAPP Preference & Reinforcer Assessment',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text('Student: $_selectedStudent', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                // Frame Switcher Buttons
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _viewMode = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: _viewMode == 0 ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                          child: Text('Preference Graphs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _viewMode == 0 ? const Color(0xFFFF9800) : Colors.white)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _viewMode = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: _viewMode == 1 ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                          child: Text('Add Item Form', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _viewMode == 1 ? const Color(0xFFFF9800) : Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _viewMode == 0 ? _buildGridView(context) : _buildAddFormView(context),
        ],
      ),
    );
  }

  // Frame 1: Preference Assessment Grid & Visual Graph (PREFERENCE ASSESSMENT.png)
  Widget _buildGridView(BuildContext context) {
    return Column(
      children: [
        // Reinforcer Preference Ranking Bar Graph
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reinforcer Preference Ranking Graph', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _items.map((it) {
                    final score = it['score'] as int;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('$score%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF9800))),
                          const SizedBox(height: 4),
                          FractionallySizedBox(
                            heightFactor: score / 100,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: const BoxDecoration(color: Color(0xFFFFB74D), borderRadius: BorderRadius.vertical(top: Radius.circular(6))),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(it['category'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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

        // Items Table
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assessed Reinforcer Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Reinforcer Item')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Preference Rank')),
                ],
                rows: _items.map((it) {
                  return DataRow(cells: [
                    DataCell(Text(it['item'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(it['category'])),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Text(it['preference'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Frame 2: Add Preference Item Form (PREFERENCE ITEM ADD.png)
  Widget _buildAddFormView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Reinforcer Preference Item Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'Item Name', hintText: 'e.g. iPad Music / Fruit Snacks', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          const TextField(decoration: InputDecoration(labelText: 'Category Area', hintText: 'e.g. Edible, Social, Sensory, Toy', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          const TextField(decoration: InputDecoration(labelText: 'Preference Hierarchy Rank', hintText: 'High, Moderate, or Low', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() => _viewMode = 0);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reinforcer Item Saved!'), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800), foregroundColor: Colors.white),
            child: const Text('Save Reinforcer Item'),
          ),
        ],
      ),
    );
  }
}
