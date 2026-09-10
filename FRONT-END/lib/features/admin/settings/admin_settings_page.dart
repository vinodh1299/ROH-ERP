import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';

import 'package:roh_erp/core/constants/app_images.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Application Settings', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3E8FF), Color(0xFFFCE7F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      AppImages.therapistAvatar(radius: 44),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 550;
                      if (isNarrow) {
                        return Column(
                          children: [
                            _buildTextField('Navigation Name', 'text here'),
                            const SizedBox(height: 16),
                            _buildTextField('Top Bar Name', 'text here'),
                            const SizedBox(height: 24),
                            Center(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: AppColors.welcomeGradient,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildTextField('Navigation Name', 'text here'),
                            const SizedBox(height: 16),
                            _buildTextField('Navigation Name', 'text here'),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Navigation Name', 'text here')),
                              const SizedBox(width: 24),
                              Expanded(child: _buildTextField('Top Bar Name', 'text here')),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Container(
                              width: 260,
                              decoration: BoxDecoration(
                                gradient: AppColors.welcomeGradient,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Navigation Name', 'text here')),
                              const SizedBox(width: 24),
                              Expanded(child: _buildTextField('Navigation Name', 'text here')),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
