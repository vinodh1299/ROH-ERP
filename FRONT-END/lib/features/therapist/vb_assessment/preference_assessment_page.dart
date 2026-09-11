import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../widgets/student_card_grid.dart';
import '../widgets/student_assessment_banner.dart';

class PreferenceAssessmentPage extends StatefulWidget {
  const PreferenceAssessmentPage({super.key});

  @override
  State<PreferenceAssessmentPage> createState() => _PreferenceAssessmentPageState();
}

class _PreferenceAssessmentPageState extends State<PreferenceAssessmentPage> {
  String? _selectedStudent;

  final Map<String, List<String>> _reinforcers = {
    'EDIBLE REINFORCERS': [
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
    ],
    'TOYS MATERIAL REINFORCERS': [
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
    ],
    'SOCIAL REINFORCERS': [
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
    ],
    'OTHER REINFORCERS': [
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
      'Apple', 'Apple', 'Apple', 'Apple', 'Apple', 'Apple',
    ],
  };

  // Checked state for items
  final Set<String> _checkedItems = {};

  @override
  void initState() {
    super.initState();
    // Pre-check all to match Figma visual
    _reinforcers.forEach((cat, list) {
      for (int i = 0; i < list.length; i++) {
        _checkedItems.add('${cat}_$i');
      }
    });
  }

  void _showAddItemDialog(String category) {
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
                          _reinforcers[category]?.add(textController.text.trim());
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
        title: 'Students VB MAPP Preference Assessment',
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
          // Header Row with Student Name & Back Button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => setState(() => _selectedStudent = null),
                tooltip: 'Back to students',
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedStudent ?? "Alex Thomas Sam"} VB MAPP Preference Assessment',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Student Assessment Banner
          StudentAssessmentBanner(
            studentName: _selectedStudent ?? 'Alex Thomas Sam',
          ),
          const SizedBox(height: 20),

          // 4 Category sections
          for (final entry in _reinforcers.entries) ...[
            _buildCategoryCard(entry.key, entry.value),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),

          // Cancel & Save Buttons
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
                    const SnackBar(content: Text('Preference Assessment Saved Successfully!')),
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

  Widget _buildCategoryCard(String category, List<String> items) {
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
          // Section Title + '+ Add' Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () => _showAddItemDialog(category),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkbox Grid (6 columns on desktop)
          LayoutBuilder(
            builder: (context, constraints) {
              int cols = 6;
              if (constraints.maxWidth < 1100) cols = 4;
              if (constraints.maxWidth < 700) cols = 3;

              final itemWidth = (constraints.maxWidth - ((cols - 1) * 12)) / cols;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (int i = 0; i < items.length; i++)
                    SizedBox(
                      width: itemWidth,
                      child: _buildCheckboxItem('${category}_$i', items[i]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxItem(String id, String label) {
    final isChecked = _checkedItems.contains(id);

    return InkWell(
      onTap: () {
        setState(() {
          if (isChecked) {
            _checkedItems.remove(id);
          } else {
            _checkedItems.add(id);
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isChecked ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isChecked ? AppColors.primary : const Color(0xFFD1D5DB),
                width: 1.5,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
