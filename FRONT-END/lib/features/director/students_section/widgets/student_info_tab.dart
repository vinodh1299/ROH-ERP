// lib/features/director/students_section/widgets/student_info_tab.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class StudentInfoTab extends StatefulWidget {
  const StudentInfoTab({super.key});

  @override
  State<StudentInfoTab> createState() => StudentInfoTabState();
}

class StudentInfoTabState extends State<StudentInfoTab> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _middleName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _gender = 'Male';
  final _dob = TextEditingController();
  final _bloodGroup = TextEditingController();
  final _dateOfApplication = TextEditingController();
  final _address = TextEditingController();
  final _primaryDx = TextEditingController();
  final _secondaryDx = TextEditingController();

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _middleName.dispose();
    _phone.dispose();
    _email.dispose();
    _dob.dispose();
    _bloodGroup.dispose();
    _dateOfApplication.dispose();
    _address.dispose();
    _primaryDx.dispose();
    _secondaryDx.dispose();
    super.dispose();
  }

  /// Validates the form and returns the field map for the API, or null if invalid.
  Map<String, dynamic>? collect() {
    if (!_formKey.currentState!.validate()) return null;
    return {
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'middle_name': _middleName.text.trim(),
      'phone_number': _phone.text.trim(),
      'email': _email.text.trim(),
      'gender': _gender,
      'dob': _dob.text.trim(),
      'blood_group': _bloodGroup.text.trim(),
      'date_of_application': _dateOfApplication.text.trim(),
      'address': _address.text.trim(),
      'primary_diagnoses': _primaryDx.text.trim(),
      'secondary_diagnoses': _secondaryDx.text.trim(),
    };
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2015, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row3(
              _Field(ctrl: _firstName, label: 'First Name', hint: 'Value', required: true),
              _Field(ctrl: _lastName, label: 'Last Name', hint: 'Value'),
              _Field(ctrl: _middleName, label: 'Middle Name', hint: 'Value'),
            ),
            const SizedBox(height: 14),
            _row3(
              _Field(ctrl: _phone, label: 'Phone Number', hint: 'Value', keyboardType: TextInputType.phone),
              _Field(ctrl: _email, label: 'Email Id', hint: 'Value', keyboardType: TextInputType.emailAddress),
              _GenderField(value: _gender, onChanged: (v) => setState(() => _gender = v)),
            ),
            const SizedBox(height: 14),
            _row3(
              _Field(ctrl: _dob, label: 'Date Of Birth', hint: 'Value', required: true, readOnly: true, onTap: () => _pickDate(_dob)),
              _Field(ctrl: _bloodGroup, label: 'Blood Group', hint: 'Value'),
              _Field(ctrl: _dateOfApplication, label: 'Date of Application', hint: 'Value', readOnly: true, onTap: () => _pickDate(_dateOfApplication)),
            ),
            const SizedBox(height: 14),
            _Field(ctrl: _address, label: 'Address', hint: 'Value', maxLines: 2),
            const SizedBox(height: 14),
            _Field(ctrl: _primaryDx, label: 'Primary Diagnoses', hint: 'Value', maxLines: 2),
            const SizedBox(height: 14),
            _Field(ctrl: _secondaryDx, label: 'Secondary Diagnoses', hint: 'Value', maxLines: 2),
            const SizedBox(height: 14),
            _row3(
              const _ReadOnlyNote(label: 'Medical Documents (multiple)', hint: 'Value'),
              const _ReadOnlyNote(label: 'Aadhar Card', hint: 'Value'),
              const _ReadOnlyNote(label: 'Birth Certificate', hint: 'Value'),
            ),
            const SizedBox(height: 8),
            Text(
              'File uploads will be enabled once document storage is connected.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _row3(Widget a, Widget b, Widget c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
        const SizedBox(width: 12),
        Expanded(child: c),
      ],
    );
  }
}

// ── Reusable field ─────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool required;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.required = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
      ],
    );
  }
}

// ── Gender dropdown ───────────────────────────────────────────────────────────
class _GenderField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _GenderField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: 'Female', child: Text('Female', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: 'Other', child: Text('Other', style: TextStyle(fontSize: 13))),
              ],
              onChanged: (v) => onChanged(v ?? 'Male'),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Read-only placeholder (file upload — disabled until storage is wired) ────
class _ReadOnlyNote extends StatelessWidget {
  final String label;
  final String hint;
  const _ReadOnlyNote({required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.upload_file_outlined, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(hint, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ],
          ),
        ),
      ],
    );
  }
}
