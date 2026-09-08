// lib/features/therapist/reinforcers/reinforcer_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/db_queries.dart';

class ReinforcerPage extends StatefulWidget {
  const ReinforcerPage({super.key});

  @override
  State<ReinforcerPage> createState() => _ReinforcerPageState();
}

class _ReinforcerPageState extends State<ReinforcerPage> {
  List<Map<String, dynamic>> _reinforcers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReinforcers();
  }

  Future<void> _fetchReinforcers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final list = await ReinforcerQueries.fetchAll();

    if (!mounted) return;

    setState(() {
      _reinforcers = list;
      _isLoading = false;
    });
  }

  void _openAddReinforcerDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _AddReinforcerDialog(
        onSaved: () => _fetchReinforcers(),
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
                    'Reinforcer Preference Assessments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Log and track edible, social, toy, and material reinforcers',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openAddReinforcerDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Reinforcer'),
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
                : _reinforcers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_outline, size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            const Text('No reinforcers logged yet', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _openAddReinforcerDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Reinforcer'),
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
                            childAspectRatio: 1.6,
                          ),
                          itemCount: _reinforcers.length,
                          itemBuilder: (ctx, i) => _ReinforcerTile(data: _reinforcers[i]),
                        );
                      }),
          ),
        ],
      ),
    );
  }
}

class _ReinforcerTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReinforcerTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final category = data['category'] ?? 'Edible';
    final itemName = data['item_name'] ?? '';
    final rating = int.tryParse('${data['rating']}') ?? 5;
    final notes = data['notes'] ?? '';

    Color iconBg;
    IconData icon;

    switch (category) {
      case 'Edible':
        iconBg = const Color(0xFFFFEBEE);
        icon = Icons.fastfood_outlined;
        break;
      case 'Social':
        iconBg = const Color(0xFFE8EAF6);
        icon = Icons.thumb_up_alt_outlined;
        break;
      case 'Toys/Materials':
        iconBg = const Color(0xFFE0F2F1);
        icon = Icons.toys_outlined;
        break;
      default:
        iconBg = const Color(0xFFFFF3E0);
        icon = Icons.star_outline;
        break;
    }

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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Category: $category',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                size: 16,
                color: Colors.amber,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            notes.isNotEmpty ? notes : 'No notes added.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _AddReinforcerDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddReinforcerDialog({required this.onSaved});

  @override
  State<_AddReinforcerDialog> createState() => _AddReinforcerDialogState();
}

class _AddReinforcerDialogState extends State<_AddReinforcerDialog> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'Edible';
  final _itemName = TextEditingController();
  int _rating = 5;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _itemName.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ReinforcerQueries.save({
      'student_id': 1,
      'category': _category,
      'item_name': _itemName.text.trim(),
      'rating': _rating,
      'notes': _notes.text.trim(),
    });

    if (mounted) {
      if (success) {
        widget.onSaved();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reinforcer preference saved!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('Add Reinforcer Assessment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: ['Edible', 'Social', 'Toys/Materials', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _itemName,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  decoration: const InputDecoration(labelText: 'Item / Activity Name', hintText: 'e.g. Apple / Light Ball', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Preference Rating: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _rating,
                      items: [1, 2, 3, 4, 5]
                          .map((r) => DropdownMenuItem(value: r, child: Text('$r Stars')))
                          .toList(),
                      onChanged: (v) => setState(() => _rating = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes / Observations', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Save Reinforcer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
