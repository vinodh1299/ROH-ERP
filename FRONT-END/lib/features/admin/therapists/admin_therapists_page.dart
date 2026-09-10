import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import 'admin_therapist_add_dialog.dart';

class AdminTherapistsPage extends StatelessWidget {
  const AdminTherapistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Our Therapists', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AdminTherapistAddDialog(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 4;
                if (constraints.maxWidth < 500) {
                  crossAxisCount = 1;
                } else if (constraints.maxWidth < 800) {
                  crossAxisCount = 2;
                } else if (constraints.maxWidth < 1100) {
                  crossAxisCount = 3;
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: constraints.maxWidth < 500 ? 1.3 : 0.88,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF3E8FF), Color(0xFFFCE7F3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      if (index == 0)
                        const Positioned(
                          top: 12,
                          right: 12,
                          child: Icon(Icons.more_horiz, color: AppColors.textPrimary),
                        ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppImages.therapistImage(
                              width: 80,
                              height: 80,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Therapist Name',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Designation',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
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
}
