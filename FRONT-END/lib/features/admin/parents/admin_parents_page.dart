// lib/features/admin/parents/admin_parents_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/db_queries.dart';

class ParentCardItem {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String childName;
  final String status;

  const ParentCardItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.childName,
    required this.status,
  });

  factory ParentCardItem.fromMap(Map<String, dynamic> map) {
    return ParentCardItem(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? 'Unknown Parent',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      childName: map['child_name'] ?? 'N/A',
      status: map['status'] ?? 'Active',
    );
  }
}

class AdminParentsPage extends StatefulWidget {
  const AdminParentsPage({super.key});

  @override
  State<AdminParentsPage> createState() => _AdminParentsPageState();
}

class _AdminParentsPageState extends State<AdminParentsPage> {
  List<ParentCardItem> _parents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParents();
  }

  Future<void> _fetchParents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final list = await ParentQueries.fetchAll();

    if (!mounted) return;

    setState(() {
      _parents = list.map((json) => ParentCardItem.fromMap(json)).toList();
      _isLoading = false;
    });
  }

  Future<void> _addParentAccount(Map<String, String> data) async {
    final success = await ParentQueries.add(
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      childName: data['childName'] ?? '',
      password: data['password'] ?? 'parent123',
    );

    if (!mounted) return;

    if (success) {
      _fetchParents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parent account created successfully!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create parent account.'), backgroundColor: Colors.red),
      );
    }
  }

  void _openAddParentDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _AddParentDialog(
        onSubmit: (data) => _addParentAccount(data),
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
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Parent Accounts Management',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create parent login accounts and link them to student profiles',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openAddParentDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Parent Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _parents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.family_restroom_outlined, size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            const Text('No parent accounts registered yet', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _openAddParentDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Parent Account'),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(builder: (ctx, constraints) {
                        int cols = 3;
                        if (constraints.maxWidth < 600) {
                          cols = 1;
                        } else if (constraints.maxWidth < 900) {
                          cols = 2;
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.4,
                          ),
                          itemCount: _parents.length,
                          itemBuilder: (ctx, i) => _ParentTile(parent: _parents[i]),
                        );
                      }),
          ),
        ],
      ),
    );
  }
}

class _ParentTile extends StatelessWidget {
  final ParentCardItem parent;
  const _ParentTile({required this.parent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFFFF3E0),
                child: const Icon(Icons.family_restroom, color: Color(0xFFFF9800), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      parent.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.child_care, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Associated Child: ${parent.childName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                parent.phone.isNotEmpty ? parent.phone : 'No phone listed',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddParentDialog extends StatefulWidget {
  final void Function(Map<String, String> data) onSubmit;
  const _AddParentDialog({required this.onSubmit});

  @override
  State<_AddParentDialog> createState() => _AddParentDialogState();
}

class _AddParentDialogState extends State<_AddParentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _childName = TextEditingController();
  final _password = TextEditingController(text: 'parent123');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _childName.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit({
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'childName': _childName.text.trim(),
      'password': _password.text.trim(),
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Row(
                  children: [
                    const Text(
                      'Create Parent Account',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
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
                      _Field(ctrl: _name, label: 'Parent Name', hint: 'e.g. Suresh Patel', required: true),
                      const SizedBox(height: 12),
                      _Field(
                        ctrl: _email,
                        label: 'Parent Email Id',
                        hint: 'parent email for logging in',
                        required: true,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(ctrl: _phone, label: 'Phone Number', hint: '+1 (555) 019-2831'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Field(ctrl: _childName, label: 'Associated Student Name', hint: 'e.g. Aarav Patel', required: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        ctrl: _password,
                        label: 'Password',
                        hint: 'parent login password',
                        required: true,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Default password is parent123 — parent can update it later.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF9800),
                              side: const BorderSide(color: Color(0xFFFF9800)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9800),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFF9800))),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
