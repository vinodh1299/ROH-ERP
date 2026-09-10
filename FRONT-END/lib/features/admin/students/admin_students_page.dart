import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import 'admin_student_form_page.dart';

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return AdminStudentFormPage(onBack: () => setState(() => _showForm = false));
    }
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Our Students', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => setState(() => _showForm = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(100, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 3;
                if (constraints.maxWidth < 650) {
                  crossAxisCount = 1;
                } else if (constraints.maxWidth < 1100) {
                  crossAxisCount = 2;
                }
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.9,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF3E8FF), Color(0xFFFCE7F3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AppImages.studentAvatar(
                            width: 70,
                            height: 70,
                            borderRadius: BorderRadius.circular(35),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildInfoRow('Name', 'Romeo Alex A'),
                                const SizedBox(height: 4),
                                _buildInfoRow('Age', '15'),
                                const SizedBox(height: 4),
                                _buildInfoRow('Phone', '+1 (555) 019-2834', isInteractive: true, isPhone: true),
                                const SizedBox(height: 4),
                                _buildInfoRow('Email', 'romeo.a@rohcenter.org', isInteractive: true, isPhone: false),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                    tooltip: 'Edit Student',
                                    onPressed: () {},
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                    tooltip: 'Delete Student',
                                    onPressed: () {},
                                  ),
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

  Widget _buildInfoRow(String label, String value, {bool isInteractive = false, bool isPhone = false}) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            '$label :',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Expanded(
          child: isInteractive
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
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }
}
