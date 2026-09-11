// lib/features/director/students_section/students_section_page.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/services/db_queries.dart';
import 'widgets/add_student_dialog.dart';

class StudentsSectionPage extends StatefulWidget {
  const StudentsSectionPage({super.key});

  @override
  State<StudentsSectionPage> createState() => _StudentsSectionPageState();
}

class _StudentsSectionPageState extends State<StudentsSectionPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await StudentQueries.fetchAll();
      if (!mounted) return;
      setState(() {
        _students = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load students. Check your database connection.';
        _loading = false;
      });
    }
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => AddStudentDialog(
        onSaved: () => _loadStudents(),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text('Remove ${student['name'] ?? 'this student'} permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final id = '${student['id']}';
      final success = await StudentQueries.delete(id);
      if (!mounted) return;
      if (success) {
        _loadStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete student.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  int _selectedView = 0; // 0: Enrolled Students, 1: Admissions & Waitlist Pipeline

  // Sample Admissions pipeline data
  final List<Map<String, dynamic>> _pipeline = [
    {
      'id': 'ADM-101',
      'name': 'Liam Davis',
      'age': '5',
      'parent': 'Sarah Davis',
      'phone': '+1 (555) 342-9182',
      'hours': '25 hrs/wk (Full-time)',
      'stage': 'Inquiry',
      'concerns': 'Non-verbal, sensory sensitivities, limited eye contact',
      'date': '02-09-2026',
    },
    {
      'id': 'ADM-102',
      'name': 'Maya Lin',
      'age': '4',
      'parent': 'David Lin',
      'phone': '+1 (555) 781-4320',
      'hours': '15 hrs/wk (Part-time)',
      'stage': 'Inquiry',
      'concerns': 'Speech delay, aggressive tantrums on task transition',
      'date': '04-09-2026',
    },
    {
      'id': 'ADM-103',
      'name': 'Noah Robinson',
      'age': '6',
      'parent': 'Chloe Robinson',
      'phone': '+1 (555) 902-1845',
      'hours': '20 hrs/wk',
      'stage': 'Inquiry',
      'concerns': 'Echolalia, difficulty with peers and social play',
      'date': '06-09-2026',
    },
    {
      'id': 'ADM-104',
      'name': 'Oliver Scott',
      'age': '7',
      'parent': 'Mark Scott',
      'phone': '+1 (555) 234-8761',
      'hours': '30 hrs/wk (Intensive)',
      'stage': 'Clinical Intake',
      'concerns': 'VB-MAPP Milestone assessment scheduled with Dr. Sarah Lee',
      'date': '28-08-2026',
    },
    {
      'id': 'ADM-105',
      'name': 'Zara Khan',
      'age': '4',
      'parent': 'Fatima Khan',
      'phone': '+1 (555) 459-0123',
      'hours': '20 hrs/wk',
      'stage': 'Clinical Intake',
      'concerns': 'FBA intake completed. Medical authorization confirmed.',
      'date': '25-08-2026',
    },
    {
      'id': 'ADM-106',
      'name': 'Henry Miller',
      'age': '8',
      'parent': 'Laura Miller',
      'phone': '+1 (555) 890-4521',
      'hours': '25 hrs/wk',
      'stage': 'Therapist Matching',
      'concerns': 'Targeting pairing with RBT James Rodriguez (Afternoon slot)',
      'date': '20-08-2026',
    },
    {
      'id': 'ADM-107',
      'name': 'Sophia Patel',
      'age': '5',
      'parent': 'Anil Patel',
      'phone': '+1 (555) 678-3210',
      'hours': '15 hrs/wk',
      'stage': 'Therapist Matching',
      'concerns': 'Assigned to Senior Therapist Michael Chang. Starts Oct 1.',
      'date': '18-08-2026',
    },
  ];

  void _advancePipelineStage(Map<String, dynamic> item) {
    setState(() {
      final current = item['stage'] as String;
      if (current == 'Inquiry') {
        item['stage'] = 'Clinical Intake';
      } else if (current == 'Clinical Intake') {
        item['stage'] = 'Therapist Matching';
      } else if (current == 'Therapist Matching') {
        item['stage'] = 'Enrolled';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['name']} advanced to ${item['stage']}!'),
        backgroundColor: AppColors.statusActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with Title, Stats & Add Button ──────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final titleColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Student Caseload & Admissions Pipeline',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage enrolled students and monitor the 4-stage clinical admissions funnel.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              );

              final addButton = ElevatedButton.icon(
                onPressed: _openAddDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Student'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleColumn,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: addButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: titleColumn),
                  const SizedBox(width: 16),
                  addButton,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── View Toggle Tabs ────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildViewTab(0, 'Active Enrolled Students (${_students.isNotEmpty ? _students.length : 24})', Icons.school_outlined),
                const SizedBox(width: 10),
                _buildViewTab(1, 'Admissions & Waitlist Pipeline (${_pipeline.length})', Icons.filter_alt_outlined),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: _selectedView == 1
                ? _buildPipelineBoard()
                : _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error!, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 12),
                                ElevatedButton(onPressed: _loadStudents, child: const Text('Retry')),
                              ],
                            ),
                          )
                        : _students.isEmpty
                            ? _EmptyState(onAdd: _openAddDialog)
                            : LayoutBuilder(builder: (ctx, constraints) {
                                int cols = 4;
                                if (constraints.maxWidth < 600) {
                                  cols = 1;
                                } else if (constraints.maxWidth < 900) {
                                  cols = 2;
                                } else if (constraints.maxWidth < 1200) {
                                  cols = 3;
                                }
                                return GridView.builder(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.55,
                                  ),
                                  itemCount: _students.length,
                                  itemBuilder: (ctx, i) => _StudentCard(
                                    student: _students[i],
                                    onEdit: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Edit student details.')),
                                      );
                                    },
                                    onDelete: () => _confirmDelete(_students[i]),
                                  ),
                                );
                              }),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab(int index, String title, IconData icon) {
    final isSelected = _selectedView == index;
    return InkWell(
      onTap: () => setState(() => _selectedView = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineBoard() {
    const stages = ['Inquiry', 'Clinical Intake', 'Therapist Matching', 'Enrolled'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final board = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: stages.map((stage) {
            final stageItems = _pipeline.where((p) => p['stage'] == stage).toList();
            Color headerColor;
            if (stage == 'Inquiry') headerColor = Colors.blue;
            else if (stage == 'Clinical Intake') headerColor = Colors.purple;
            else if (stage == 'Therapist Matching') headerColor = Colors.orange;
            else headerColor = Colors.green;

            final columnWidget = Container(
              width: isNarrow ? 260 : null,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9FC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stage Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: headerColor.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(stage, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: headerColor)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: headerColor, borderRadius: BorderRadius.circular(10)),
                          child: Text('${stageItems.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  // Stage Cards
                  Expanded(
                    child: stageItems.isEmpty
                        ? Center(child: Text('No students in $stage', style: const TextStyle(fontSize: 12, color: AppColors.textHint)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: stageItems.length,
                            itemBuilder: (ctx, i) {
                              final item = stageItems[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.divider),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                        Text('Age ${item['age']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Parent: ${item['parent']} • ${item['phone']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                                      child: Text(item['hours'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(item['concerns'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                                    const SizedBox(height: 10),
                                    if (stage != 'Enrolled')
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          onPressed: () => _advancePipelineStage(item),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('Advance Stage', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                              SizedBox(width: 4),
                                              Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );

            return isNarrow ? columnWidget : Expanded(child: columnWidget);
          }).toList(),
        );

        return isNarrow
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: board,
              )
            : board;
      },
    );
  }

}

// ── Student Card (pink gradient tile, matches Figma) ──────────────────────────
class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _StudentCard({required this.student, required this.onEdit, required this.onDelete});

  int? get _age {
    final dobRaw = '${student['dob'] ?? ''}';
    if (dobRaw.isEmpty) return null;
    try {
      final dob = DateTime.parse(dobRaw);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
      return age;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = '${student['name'] ?? student['first_name'] ?? 'Unknown'}';
    final phone = '${student['phone_number'] ?? ''}';
    final email = '${student['email'] ?? ''}';
    final age = _age;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.face_outlined, size: 30, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                if (age != null)
                  Text('Age  $age', style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                Text('Phone  ${phone.isEmpty ? 'xxxxxxxxxx' : phone}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                Text('Email  ${email.isEmpty ? 'xxxxxxxxxx' : email}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.people_outline, size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No students yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Student records will load from the database.\nUse the Add button to add one manually.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Add Student')),
        ],
      ),
    );
  }
}
