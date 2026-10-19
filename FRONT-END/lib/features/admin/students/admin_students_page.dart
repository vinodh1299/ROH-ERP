import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/widgets/edit_record_dialogs.dart';
import '../../director/students_section/widgets/add_student_dialog.dart';

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService().get('get_students');
      if (!mounted) return;
      if (res is List) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      } else if (res is Map && res['error'] != null) {
        setState(() {
          _error = res['error'].toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _students = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => AddStudentDialog(onSaved: _loadStudents),
    );
  }

  Future<void> _editStudent(Map<String, dynamic> student) async {
    if (await EditStudentDialog.show(context, student)) _loadStudents();
  }

  int _calculateAge(dynamic dob) {
    if (dob == null) return 10;
    try {
      final birthDate = DateTime.parse(dob.toString());
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age > 0 ? age : 1;
    } catch (_) {
      return 10;
    }
  }

  Future<void> _deleteStudent(int studentId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to remove $name from active center enrollment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusDeactivated),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ApiService().post('delete_student', {'id': studentId});
    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$name removed successfully'),
              backgroundColor: AppColors.primary),
        );
      }
      _loadStudents();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: ${res['error']}'),
              backgroundColor: AppColors.statusDeactivated),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = Breakpoints.isCompact(context);
    return Padding(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Our Students',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const Spacer(),
              ElevatedButton(
                onPressed: _openAddDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(100, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Add',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.statusDeactivated, size: 40),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: _loadStudents,
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _students.isEmpty
                        ? const Center(
                            child: Text(
                                'No students currently enrolled in database.',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = 3;
                              if (constraints.maxWidth < 650) {
                                crossAxisCount = 1;
                              } else if (constraints.maxWidth < 1100) {
                                crossAxisCount = 2;
                              }
                              return GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio:
                                      crossAxisCount == 1 ? 2.5 : 1.9,
                                ),
                                itemCount: _students.length,
                                itemBuilder: (context, index) {
                                  final student = _students[index];
                                  final name = student['name'] ??
                                      '${student['first_name']} ${student['last_name']}';
                                  final age = _calculateAge(student['dob']);
                                  final studentId = student['id'] is int
                                      ? student['id']
                                      : int.tryParse(
                                              student['id'].toString()) ??
                                          0;
                                  final phone =
                                      student['phone']?.toString().isNotEmpty ==
                                              true
                                          ? student['phone'].toString()
                                          : 'Not provided';
                                  final email =
                                      student['email']?.toString().isNotEmpty ==
                                              true
                                          ? student['email'].toString()
                                          : 'Not provided';

                                  final editBtn = IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: AppColors.primary, size: 20),
                                    constraints: const BoxConstraints(
                                        minWidth: 44, minHeight: 44),
                                    tooltip: 'Edit Student',
                                    onPressed: () => _editStudent(student),
                                  );
                                  final deleteBtn = IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red, size: 20),
                                    constraints: const BoxConstraints(
                                        minWidth: 44, minHeight: 44),
                                    tooltip: 'Delete Student',
                                    onPressed: () =>
                                        _deleteStudent(studentId, name),
                                  );

                                  return Container(
                                    padding: EdgeInsets.all(isPhone ? 12 : 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: AppColors.border),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x0A000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          // Smaller avatar on phones so the details column keeps room.
                                          radius: isPhone ? 26 : 35,
                                          backgroundColor: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          child: Icon(Icons.person,
                                              size: isPhone ? 28 : 36,
                                              color: AppColors.primary),
                                        ),
                                        SizedBox(width: isPhone ? 12 : 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              _buildInfoRow('Name', name),
                                              const SizedBox(height: 4),
                                              _buildInfoRow('Age', '$age'),
                                              const SizedBox(height: 4),
                                              _buildInfoRow('Phone', phone,
                                                  isInteractive: true,
                                                  isPhone: true),
                                              const SizedBox(height: 4),
                                              _buildInfoRow('Email', email,
                                                  isInteractive: true,
                                                  isPhone: false),
                                            ],
                                          ),
                                        ),
                                        // Phone: stack the actions vertically to save width.
                                        isPhone
                                            ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [editBtn, deleteBtn],
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      editBtn,
                                                      const SizedBox(width: 4),
                                                      deleteBtn
                                                    ],
                                                  ),
                                                ],
                                              ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isInteractive = false, bool isPhone = false}) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            '$label :',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ),
        Expanded(
          child: isInteractive && value != 'Not provided'
              ? InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied $label to clipboard: $value'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isPhone ? Icons.call : Icons.email_outlined,
                        size: 13,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }
}
