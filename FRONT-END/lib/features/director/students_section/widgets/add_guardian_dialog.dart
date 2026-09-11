// lib/features/director/students_section/widgets/add_guardian_dialog.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';

class AddGuardianDialog extends StatefulWidget {
  final void Function(Map<String, String> data) onSubmit;
  const AddGuardianDialog({super.key, required this.onSubmit});

  @override
  State<AddGuardianDialog> createState() => _AddGuardianDialogState();
}

class _AddGuardianDialogState extends State<AddGuardianDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _relationship = TextEditingController();
  final _about = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _relationship.dispose();
    _about.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit({
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone_number': _phone.text.trim(),
      'relationship': _relationship.text.trim(),
      'about': _about.text.trim(),
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 4),
                child: Row(
                  children: [
                    const Text('Add Guardian',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(child: _field(_name, 'Name', 'enter therapist name', required: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _field(_email, 'Email Id', 'enter therapist email id')),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _field(_phone, 'Phone Number', 'enter therapist Phone no.')),
                        const SizedBox(width: 10),
                        Expanded(child: _field(_relationship, 'Relationship', 'enter relation')),
                      ]),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('About', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _about,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'enter therapist about',
                          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            ),
                            child: const Text('Submit', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
