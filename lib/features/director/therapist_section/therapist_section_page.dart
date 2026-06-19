// lib/features/director/therapist_section/therapist_section_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

// ── Model (swap with real DB model later) ─────────────────────────────────────
class TherapistCard {
  final String name;
  final String designation;
  final String? imageUrl;
  const TherapistCard({required this.name, required this.designation, this.imageUrl});
}

class TherapistSectionPage extends StatefulWidget {
  const TherapistSectionPage({super.key});

  @override
  State<TherapistSectionPage> createState() => _TherapistSectionPageState();
}

class _TherapistSectionPageState extends State<TherapistSectionPage> {
  // When DB is connected, replace this list with data fetched from the DB.
  final List<TherapistCard> _therapists = [];

  void _openAddDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _AddTherapistDialog(
        onSubmit: (data) {
          // TODO: insert into DB, then refresh list
          setState(() {
            _therapists.add(TherapistCard(
              name: data['name'] ?? 'New Therapist',
              designation: data['designation'] ?? '',
            ));
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              const Text(
                'Our Therapists',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openAddDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Grid ────────────────────────────────────────────────────────
          Expanded(
            child: _therapists.isEmpty
                ? _EmptyState(onAdd: _openAddDialog)
                : LayoutBuilder(builder: (ctx, constraints) {
                    // Responsive column count
                    int cols = 4;
                    if (constraints.maxWidth < 400) cols = 2;
                    else if (constraints.maxWidth < 600) cols = 2;
                    else if (constraints.maxWidth < 900) cols = 3;

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: _therapists.length,
                      itemBuilder: (ctx, i) => _TherapistTile(therapist: _therapists[i]),
                    );
                  }),
          ),
        ],
      ),
    );
  }
}

// ── Therapist Card Tile ───────────────────────────────────────────────────────
class _TherapistTile extends StatelessWidget {
  final TherapistCard therapist;
  const _TherapistTile({required this.therapist});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Photo area with purple gradient bg ──────────────────────────
          Expanded(
            flex: 7,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.35),
                    ],
                  ),
                ),
                child: therapist.imageUrl != null
                    ? Image.network(
                        therapist.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _AvatarPlaceholder(),
                      )
                    : const _AvatarPlaceholder(),
              ),
            ),
          ),
          // ── Name + Designation ──────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    therapist.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    therapist.designation,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary.withOpacity(0.8),
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
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircleAvatar(
        radius: 36,
        backgroundColor: AppColors.primary.withOpacity(0.2),
        child: const Icon(Icons.person, size: 40, color: AppColors.primary),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_services_outlined,
                size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No therapists yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Therapist records will load from the database.\nUse the Add button to add one manually.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Therapist'),
          ),
        ],
      ),
    );
  }
}

// ── Add Therapist Dialog ──────────────────────────────────────────────────────
class _AddTherapistDialog extends StatefulWidget {
  final void Function(Map<String, String> data) onSubmit;
  const _AddTherapistDialog({required this.onSubmit});

  @override
  State<_AddTherapistDialog> createState() => _AddTherapistDialogState();
}

class _AddTherapistDialogState extends State<_AddTherapistDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name        = TextEditingController();
  final _email       = TextEditingController();
  final _phone       = TextEditingController();
  final _dob         = TextEditingController();
  final _empId       = TextEditingController();
  final _designation = TextEditingController();
  final _about       = TextEditingController();

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _phone.dispose();
    _dob.dispose();  _empId.dispose(); _designation.dispose();
    _about.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit({
      'name':        _name.text.trim(),
      'email':       _email.text.trim(),
      'phone':       _phone.text.trim(),
      'dob':         _dob.text.trim(),
      'emp_id':      _empId.text.trim(),
      'designation': _designation.text.trim(),
      'about':       _about.text.trim(),
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: BoxDecoration(
            // Purple gradient matching Figma dialog
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9C4FD6), Color(0xFFBB6FEE)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Dialog header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Row(
                  children: [
                    const Text(
                      'Add Therapist',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // ── Form fields in white rounded box ───────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Row 1: Name + Email
                      Row(children: [
                        Expanded(child: _Field(ctrl: _name,  label: 'Name',     hint: 'enter therapist name',     required: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _Field(ctrl: _email, label: 'Email Id', hint: 'enter therapist email id',  required: true, keyboardType: TextInputType.emailAddress)),
                      ]),
                      const SizedBox(height: 14),
                      // Row 2: Phone + DOB
                      Row(children: [
                        Expanded(child: _Field(ctrl: _phone, label: 'Phone Number', hint: 'enter therapist Phone no.', keyboardType: TextInputType.phone)),
                        const SizedBox(width: 12),
                        Expanded(child: _Field(ctrl: _dob,   label: 'Date Of Birth', hint: 'enter therapist dob')),
                      ]),
                      const SizedBox(height: 14),
                      // Row 3: Employee ID + Designation
                      Row(children: [
                        Expanded(child: _Field(ctrl: _empId,       label: 'Employee Id',  hint: 'enter therapist Emp id')),
                        const SizedBox(width: 12),
                        Expanded(child: _Field(ctrl: _designation, label: 'Designation',  hint: 'enter therapist designation')),
                      ]),
                      const SizedBox(height: 14),
                      // About (full width, multiline)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('About',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _about,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'enter therapist about',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                            ),
                            child: const Text('Submit'),
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
}

// ── Reusable form field ───────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool required;
  final TextInputType? keyboardType;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.required = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: required
              ? (v) => v == null || v.isEmpty ? 'Required' : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
