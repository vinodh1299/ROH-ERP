// lib/features/therapist/abc_data_sheet/abc_data_sheet_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AbcDataSheetPage extends StatefulWidget {
  const AbcDataSheetPage({super.key});

  @override
  State<AbcDataSheetPage> createState() => _AbcDataSheetPageState();
}

class _AbcDataSheetPageState extends State<AbcDataSheetPage> {
  String _selectedStudent = 'Aarav Patel (Age: 8)';

  final List<Map<String, dynamic>> _abcLogs = [
    {
      'time': '10:15 AM',
      'antecedent': 'Demand presented (math worksheet)',
      'behavior': 'Flopping to floor & screaming',
      'consequence': 'Task paused for 30s & redirected using visual schedule',
    },
    {
      'time': '11:30 AM',
      'antecedent': 'Peer took toy car during free play',
      'behavior': 'Pushing peer',
      'consequence': 'Verbal correction & block taught to ask "My turn please"',
    },
  ];

  void _openAddAbcDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _AddAbcModal(
        onSaved: (log) {
          setState(() => _abcLogs.insert(0, log));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ABC Log entry saved!'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD81B60), Color(0xFFEC407A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ABC Data Sheet (Antecedent - Behavior - Consequence)',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text('Student: $_selectedStudent', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openAddAbcDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add ABC Log'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFD81B60)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Log Entries List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _abcLogs.length,
            itemBuilder: (ctx, i) {
              final log = _abcLogs[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(6)),
                          child: Text(log['time'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD81B60))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AbcBullet(label: 'Antecedent (A):', content: log['antecedent'], color: Colors.blue),
                    const SizedBox(height: 6),
                    _AbcBullet(label: 'Behavior (B):', content: log['behavior'], color: Colors.red),
                    const SizedBox(height: 6),
                    _AbcBullet(label: 'Consequence (C):', content: log['consequence'], color: Colors.green),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AbcBullet extends StatelessWidget {
  final String label;
  final String content;
  final Color color;

  const _AbcBullet({required this.label, required this.content, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 8),
        Expanded(child: Text(content, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
      ],
    );
  }
}

class _AddAbcModal extends StatefulWidget {
  final void Function(Map<String, dynamic> log) onSaved;
  const _AddAbcModal({required this.onSaved});

  @override
  State<_AddAbcModal> createState() => _AddAbcModalState();
}

class _AddAbcModalState extends State<_AddAbcModal> {
  final _antecedent = TextEditingController();
  final _behavior = TextEditingController();
  final _consequence = TextEditingController();

  @override
  void dispose() {
    _antecedent.dispose();
    _behavior.dispose();
    _consequence.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSaved({
      'time': '12:00 PM',
      'antecedent': _antecedent.text,
      'behavior': _behavior.text,
      'consequence': _consequence.text,
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('Add ABC Log Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _antecedent, decoration: const InputDecoration(labelText: 'Antecedent (What happened before?)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _behavior, decoration: const InputDecoration(labelText: 'Behavior (Observed behavior)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _consequence, decoration: const InputDecoration(labelText: 'Consequence (What happened after?)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60), foregroundColor: Colors.white),
              child: const Text('Save ABC Log'),
            ),
          ],
        ),
      ),
    );
  }
}
