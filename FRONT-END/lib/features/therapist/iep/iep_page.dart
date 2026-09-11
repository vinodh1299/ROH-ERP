import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import '../widgets/student_card_grid.dart';

class IepPage extends StatefulWidget {
  const IepPage({super.key});

  @override
  State<IepPage> createState() => _IepPageState();
}

class _IepPageState extends State<IepPage> {
  String? _selectedStudent;

  final List<Map<String, dynamic>> _mandingGoals = [
    {
      'label': 'A',
      'goal': 'Rithvik will mands for 20 different items missing without prompts (example: if child likes juice and drinks it with a straw, give him juice box without a straw and test if he mands for straw) as measured by 3 consecutive first trial probes within 6 months.',
      'baseline': 'Rithvik will emit or request 11 different mands without any prompts and doesn\'t emit any mands for missing different items independently.',
    },
    {
      'label': 'B',
      'goal': 'Rithvik will mands for 20 different items missing without prompts (example: if child likes juice and drinks it with a straw, give him juice box without a straw and test if he mands for straw) as measured by 3 consecutive first trial probes within 6 months.',
      'baseline': 'Rithvik will emit or request 11 different mands without any prompts and doesn\'t emit any mands for missing different items independently.',
    },
  ];

  final List<Map<String, dynamic>> _tactingGoals = [
    {
      'label': 'A',
      'goal': 'Rithvik will mands for 20 different items missing without prompts (example: if child likes juice and drinks it with a straw, give him juice box without a straw and test if he mands for straw) as measured by 3 consecutive first trial probes within 6 months.',
      'baseline': 'Rithvik will emit or request 11 different mands without any prompts and doesn\'t emit any mands for missing different items independently.',
    },
  ];

  void _showAddItemDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Item',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Item Name',
                style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: 'enter item name',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (textController.text.trim().isNotEmpty) {
                        setState(() {
                          _mandingGoals.add({
                            'label': String.fromCharCode(65 + _mandingGoals.length),
                            'goal': textController.text.trim(),
                            'baseline': 'Baseline assessment in progress.',
                          });
                        });
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B21A8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStudent == null) {
      return StudentCardGrid(
        title: 'Students Individualized Education Plan (IEP)',
        buttonLabel: 'Add',
        onStudentAction: (student) {
          setState(() {
            _selectedStudent = student;
          });
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => setState(() => _selectedStudent = null),
                tooltip: 'Back to students',
              ),
              const SizedBox(width: 8),
              const Text(
                'Students Individualized Education Plan (IEP)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Student IEP Header Banner
          _buildIepHeaderBanner(),
          const SizedBox(height: 16),

          // '+ Add' Action Link
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: _showAddItemDialog,
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 18, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. MANDING Section
          _buildGoalSection('1. MANDING', _mandingGoals),
          const SizedBox(height: 24),

          // 2. TACTING Section
          _buildGoalSection('2. TACTING', _tactingGoals),
          const SizedBox(height: 24),

          // Save & Cancel Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _selectedStudent = null),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student IEP Saved Successfully!')),
                  );
                  setState(() => _selectedStudent = null);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildIepHeaderBanner() {
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Photo
          AppImages.studentAvatar(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(width: 20),

          // Name and Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedStudent ?? 'Alex Thomas Sam',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Date of Birth : 16-02-2020',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'Age : 13',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
          const Spacer(),

          // Assessment Dates Dark Box
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1035).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(12),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'ASSESSMENT DATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Divider(color: Colors.white24, height: 12),
                _DateRow('1st Progress Report:', '23/8/2024'),
                _DateRow('2nd Progress Report:', '4/10/2024'),
                _DateRow('3rd Progress Report:', '15/11/2024'),
                _DateRow('4th Progress Report:', '27/12/2024'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSection(String title, List<Map<String, dynamic>> goals) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          for (final item in goals) ...[
            _buildGoalCard(item['label'] as String, item['goal'] as String, item['baseline'] as String),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalCard(String label, String goal, String baseline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target Goal Box
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFBA43DF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    goal,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'BASELINE',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        // Baseline Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            baseline,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  final String title;
  final String date;
  const _DateRow(this.title, this.date);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(date, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
