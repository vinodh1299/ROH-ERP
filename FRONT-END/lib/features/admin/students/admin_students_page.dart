// lib/features/admin/students/admin_students_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/db_queries.dart';
import '../../director/students_section/widgets/add_student_dialog.dart';

class StudentCardItem {
  final String id;
  final String name;
  final String dob;
  final String phone;
  final String email;
  final String parentName;

  const StudentCardItem({
    required this.id,
    required this.name,
    required this.dob,
    required this.phone,
    required this.email,
    required this.parentName,
  });

  int get calculatedAge {
    if (dob.isEmpty) return 0;
    try {
      final birth = DateTime.parse(dob);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) age--;
      return age < 0 ? 0 : age;
    } catch (_) {
      return 0;
    }
  }

  factory StudentCardItem.fromMap(Map<String, dynamic> map) {
    return StudentCardItem(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      dob: map['dob'] ?? '',
      phone: map['phone_number'] ?? map['phone'] ?? '',
      email: map['email'] ?? '',
      parentName: map['parent_name'] ?? '',
    );
  }
}

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  List<StudentCardItem> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final list = await StudentQueries.fetchAll();

    if (!mounted) return;

    setState(() {
      _students = list.map((json) => StudentCardItem.fromMap(json)).toList();
      _isLoading = false;
    });
  }

  Future<void> _deleteStudent(String id) async {
    final success = await StudentQueries.delete(id);
    if (success) {
      _fetchStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student profile deleted.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _openAddStudentDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AddStudentDialog(
        onSaved: () => _fetchStudents(),
      ),
    );
  }

  void _confirmDelete(StudentCardItem student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student Profile'),
        content: Text('Are you sure you want to delete profile for "${student.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteStudent(student.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
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
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Student Profile Intake & Records',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create comprehensive 3-tab student profiles and medical records',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openAddStudentDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Student Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school_outlined, size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            const Text('No student profiles found', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _openAddStudentDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Student Profile'),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(builder: (ctx, constraints) {
                        int cols = 4;
                        if (constraints.maxWidth < 400) {
                          cols = 1;
                        } else if (constraints.maxWidth < 650) {
                          cols = 2;
                        } else if (constraints.maxWidth < 950) {
                          cols = 3;
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: _students.length,
                          itemBuilder: (ctx, i) => _AdminStudentCard(
                            student: _students[i],
                            onDelete: () => _confirmDelete(_students[i]),
                          ),
                        );
                      }),
          ),
        ],
      ),
    );
  }
}

class _AdminStudentCard extends StatelessWidget {
  final StudentCardItem student;
  final VoidCallback onDelete;

  const _AdminStudentCard({required this.student, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF3C6E8), Color(0xFFE9A8DC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    student.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Age: ${student.calculatedAge > 0 ? '${student.calculatedAge} yrs' : 'N/A'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        onPressed: onDelete,
                        tooltip: 'Delete Profile',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
