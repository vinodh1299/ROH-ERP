import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';

import 'package:roh_erp/core/constants/app_images.dart';

class AdminStudProgressPage extends StatelessWidget {
  const AdminStudProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Students Progress', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          Container(
            width: 460,
            height: 240,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3E8FF), Color(0xFFFCE7F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(24),
            alignment: Alignment.topLeft,
            child: AppImages.studentAvatar(
              width: 85,
              height: 95,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }
}
