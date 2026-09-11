import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/services/db_queries.dart';

class StudentCardGrid extends StatefulWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback? onStudentTap;
  final void Function(String studentName)? onStudentAction;
  final Widget? extraTopRightWidget;
  final List<Map<String, dynamic>>? students;

  const StudentCardGrid({
    super.key,
    required this.title,
    required this.buttonLabel,
    this.onStudentTap,
    this.onStudentAction,
    this.extraTopRightWidget,
    this.students,
  });

  @override
  State<StudentCardGrid> createState() => _StudentCardGridState();
}

class _StudentCardGridState extends State<StudentCardGrid> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.students != null) {
      _students = List.from(widget.students!);
      _isLoading = false;
    } else {
      _fetchStudents();
    }
  }

  @override
  void didUpdateWidget(covariant StudentCardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.students != null) {
      _students = List.from(widget.students!);
      _isLoading = false;
    }
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService().get('get_students');
      if (res is List && res.isNotEmpty) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('ApiService get_students error: $e');
    }

    try {
      final fallback = await StudentQueries.fetchAll();
      if (fallback.isNotEmpty) {
        setState(() {
          _students = fallback;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('StudentQueries.fetchAll fallback error: $e');
    }

    if (MockData.students.isNotEmpty) {
      setState(() {
        _students = List<Map<String, dynamic>>.from(MockData.students);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Unable to load students. Please check your network connection.';
        _isLoading = false;
      });
    }
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

  List<Map<String, dynamic>> get _filteredStudents {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _students;
    return _students.where((s) {
      final name = (s['name'] ?? '${s['first_name']} ${s['last_name']}').toString().toLowerCase();
      final prog = (s['program'] ?? '').toString().toLowerCase();
      final diag = (s['primary_diagnosis'] ?? '').toString().toLowerCase();
      return name.contains(q) || prog.contains(q) || diag.contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            final titleWidget = Text(
              widget.title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            );

            final searchAndExtraWidget = Row(
              mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (widget.extraTopRightWidget != null) ...[
                  widget.extraTopRightWidget!,
                  const SizedBox(width: 16),
                ],
                Expanded(
                  flex: isNarrow ? 1 : 0,
                  child: Container(
                    width: isNarrow ? double.infinity : 250,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search students...',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.search, color: AppColors.textHint, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  const SizedBox(height: 12),
                  searchAndExtraWidget,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleWidget),
                const SizedBox(width: 16),
                searchAndExtraWidget,
              ],
            );
          },
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
                          Icon(Icons.error_outline, color: AppColors.statusDeactivated, size: 40),
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchStudents,
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    )
                  : _filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search, size: 50, color: AppColors.textHint.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              const Text('No students found', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 6;
                            double aspectRatio = 0.85;
                            if (constraints.maxWidth < 1200) crossAxisCount = 4;
                            if (constraints.maxWidth < 800) crossAxisCount = 3;
                            if (constraints.maxWidth < 600) crossAxisCount = 2;
                            if (constraints.maxWidth < 450) {
                              crossAxisCount = 1;
                              aspectRatio = 1.6;
                            }

                            final displayed = _filteredStudents;

                            return GridView.builder(
                              itemCount: displayed.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: aspectRatio,
                              ),
                              itemBuilder: (context, index) {
                                final student = displayed[index];
                                final name = student['name'] ?? '${student['first_name']} ${student['last_name']}';
                                final age = _calculateAge(student['dob']);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      if (widget.onStudentAction != null) {
                                        widget.onStudentAction!(name);
                                      } else if (widget.onStudentTap != null) {
                                        widget.onStudentTap!();
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x0A000000),
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          AppImages.studentAvatar(
                                            width: 64,
                                            height: 64,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            name,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Age : $age',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            width: 72,
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              widget.buttonLabel,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
