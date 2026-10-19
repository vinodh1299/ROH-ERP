// lib/core/widgets/edit_record_dialogs.dart
// Edit dialogs shared by the admin and director portals.
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/services/api_service.dart';

/// Shows [message] as a red snackbar when [res] is an API error, otherwise
/// [success] in green. Returns whether the call succeeded.
bool showApiResult(BuildContext context, dynamic res, String success) {
  final ok = res is Map && res['success'] == true;
  final error = res is Map ? res['error']?.toString() : null;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(ok ? success : (error ?? 'Something went wrong. Try again.')),
    backgroundColor: ok ? AppColors.statusActive : AppColors.statusDeactivated,
  ));
  return ok;
}

class _EditDialogFrame extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final bool saving;
  final VoidCallback onSave;

  const _EditDialogFrame({
    required this.title,
    required this.fields,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in fields) ...[f, const SizedBox(height: 14)],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: saving ? null : onSave,
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

InputDecoration _decoration(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    );

/// Edits a student's name, program and status (`update_student`).
/// Resolves to true when saved.
class EditStudentDialog extends StatefulWidget {
  final int studentId;
  final String name;
  final String program;
  final String status;

  const EditStudentDialog({
    super.key,
    required this.studentId,
    required this.name,
    this.program = '',
    this.status = 'Active',
  });

  static Future<bool> show(BuildContext context, Map<String, dynamic> s) async {
    final id = int.tryParse(s['id']?.toString() ?? '');
    if (id == null) return false;
    final name =
        (s['name'] ?? '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}')
            .toString()
            .trim();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => EditStudentDialog(
        studentId: id,
        name: name,
        program: (s['program'] ?? '').toString(),
        status: (s['status'] ?? 'Active').toString(),
      ),
    );
    return saved == true;
  }

  @override
  State<EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<EditStudentDialog> {
  static const _statuses = ['Active', 'De-Activated', 'Graduated', 'On Leave'];
  late final _name = TextEditingController(text: widget.name);
  late final _program = TextEditingController(text: widget.program);
  late String _status =
      _statuses.contains(widget.status) ? widget.status : 'Active';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _program.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the student\'s name.')));
      return;
    }
    setState(() => _saving = true);
    final res = await ApiService().post('update_student', {
      'id': widget.studentId,
      'name': name,
      if (_program.text.trim().isNotEmpty) 'program': _program.text.trim(),
      'status': _status,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (showApiResult(context, res, 'Student updated.')) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditDialogFrame(
      title: 'Edit Student',
      saving: _saving,
      onSave: _save,
      fields: [
        TextField(controller: _name, decoration: _decoration('Full name')),
        TextField(controller: _program, decoration: _decoration('Program')),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: _decoration('Status'),
          items: [
            for (final s in _statuses)
              DropdownMenuItem(value: s, child: Text(s)),
          ],
          onChanged: (v) => setState(() => _status = v ?? _status),
        ),
      ],
    );
  }
}

/// Edits a therapist's name, email and phone (`update_therapist`).
/// Resolves to true when saved.
class EditTherapistDialog extends StatefulWidget {
  final int therapistId;
  final String name;
  final String email;
  final String phone;

  const EditTherapistDialog({
    super.key,
    required this.therapistId,
    required this.name,
    this.email = '',
    this.phone = '',
  });

  static Future<bool> show(BuildContext context, Map<String, dynamic> t) async {
    final id = int.tryParse((t['id'] ?? t['user_id'])?.toString() ?? '');
    if (id == null) return false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => EditTherapistDialog(
        therapistId: id,
        name: (t['name'] ?? '').toString(),
        email: (t['email'] ?? '').toString(),
        phone: (t['phone'] ?? '').toString(),
      ),
    );
    return saved == true;
  }

  @override
  State<EditTherapistDialog> createState() => _EditTherapistDialogState();
}

class _EditTherapistDialogState extends State<EditTherapistDialog> {
  late final _name = TextEditingController(text: widget.name);
  late final _email = TextEditingController(text: widget.email);
  late final _phone = TextEditingController(text: widget.phone);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = _email.text.trim();
    if (_name.text.trim().isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a name and a valid email address.')));
      return;
    }
    setState(() => _saving = true);
    final res = await ApiService().post('update_therapist', {
      'id': widget.therapistId,
      'name': _name.text.trim(),
      'email': email,
      'phone': _phone.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (showApiResult(context, res, 'Therapist updated.')) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditDialogFrame(
      title: 'Edit Therapist',
      saving: _saving,
      onSave: _save,
      fields: [
        TextField(controller: _name, decoration: _decoration('Full name')),
        TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: _decoration('Email')),
        TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: _decoration('Phone')),
      ],
    );
  }
}

/// Activates or de-activates a therapist after confirming.
/// Resolves to true when the status changed.
Future<bool> toggleTherapistStatus(
    BuildContext context, Map<String, dynamic> t) async {
  final id = int.tryParse((t['id'] ?? t['user_id'])?.toString() ?? '');
  if (id == null) return false;
  final active = (t['status'] ?? 'Active').toString() == 'Active';
  final name = (t['name'] ?? 'this therapist').toString();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(active ? 'De-activate $name?' : 'Re-activate $name?'),
      content: Text(active
          ? '$name will no longer be able to sign in.'
          : '$name will be able to sign in again.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                active ? AppColors.statusDeactivated : AppColors.statusActive,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(active ? 'De-activate' : 'Re-activate'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  final res = await ApiService().post('toggle_therapist_status',
      {'id': id, 'status': active ? 'De-Activated' : 'Active'});
  if (!context.mounted) return false;
  return showApiResult(
      context, res, active ? '$name de-activated.' : '$name re-activated.');
}
