import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';

class AdminTherapistAddDialog extends StatelessWidget {
  const AdminTherapistAddDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          gradient: AppColors.welcomeGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Therapist', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                width: 100,
                height: 2,
                color: Colors.white,
                margin: const EdgeInsets.only(top: 4, bottom: 24),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 420;
                  if (isNarrow) {
                    return Column(
                      children: [
                        _buildField('Name'),
                        const SizedBox(height: 16),
                        _buildField('Email Id'),
                        const SizedBox(height: 16),
                        _buildField('Phone Number'),
                        const SizedBox(height: 16),
                        _buildField('Date Of Birth'),
                        const SizedBox(height: 16),
                        _buildField('Employee Id'),
                        const SizedBox(height: 16),
                        _buildField('Designation'),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildField('Name')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildField('Email Id')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildField('Phone Number')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildField('Date Of Birth')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildField('Employee Id')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildField('Designation')),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildField('About', maxLines: 4),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
