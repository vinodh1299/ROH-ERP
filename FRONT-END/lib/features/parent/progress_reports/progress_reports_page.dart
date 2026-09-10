import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';

class ProgressReportsPage extends StatelessWidget {
  const ProgressReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 3;
          double aspectRatio = 1.2;
          if (constraints.maxWidth < 650) {
            crossAxisCount = 1;
            aspectRatio = 1.4;
          } else if (constraints.maxWidth < 950) {
            crossAxisCount = 2;
            aspectRatio = 1.3;
          }

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
          final isPending = index == 0;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFEADCC6),
                    child: const Center(
                      child: Icon(
                        Icons.flag,
                        size: 60,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Date: ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Text(
                        '27-07-2029',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPending ? Colors.orange : const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isPending ? 'Pending' : 'View',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
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
    );
  }
}
