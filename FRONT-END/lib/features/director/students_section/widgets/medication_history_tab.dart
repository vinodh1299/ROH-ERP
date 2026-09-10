// lib/features/director/students_section/widgets/medication_history_tab.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../../core/services/db_queries.dart';

class MedicationHistoryTab extends StatefulWidget {
  final String? studentId;
  const MedicationHistoryTab({super.key, required this.studentId});

  @override
  State<MedicationHistoryTab> createState() => MedicationHistoryTabState();
}

class MedicationHistoryTabState extends State<MedicationHistoryTab> {
  // Medication rows: each row is {name: ctrl, usedFor: ctrl}
  final List<_MedicationRow> _medicationRows = [_MedicationRow()];

  final _surgery = TextEditingController();
  final _medicalConditions = TextEditingController();
  final _headInjury = TextEditingController();
  final _allergies = TextEditingController();
  final _eatingHabits = TextEditingController();
  final _sleepingHabits = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    for (final row in _medicationRows) {
      row.name.dispose();
      row.usedFor.dispose();
    }
    _surgery.dispose();
    _medicalConditions.dispose();
    _headInjury.dispose();
    _allergies.dispose();
    _eatingHabits.dispose();
    _sleepingHabits.dispose();
    super.dispose();
  }

  void _addRow() => setState(() => _medicationRows.add(_MedicationRow()));

  void _removeRow(int index) {
    if (_medicationRows.length <= 1) return;
    setState(() {
      _medicationRows[index].name.dispose();
      _medicationRows[index].usedFor.dispose();
      _medicationRows.removeAt(index);
    });
  }

  /// Called by the parent dialog's "Next" button on this tab.
  /// Saves medications + medical Q&A to the DB if a student_id exists yet.
  Future<bool> saveAll() async {
    final studentId = widget.studentId;
    if (studentId == null) return true; // nothing to attach to yet

    setState(() => _saving = true);
    bool ok = true;

    for (final row in _medicationRows) {
      if (row.name.text.trim().isEmpty) continue;
      final success = await StudentQueries.addMedication(
        studentId: studentId,
        medicationName: row.name.text.trim(),
        usedFor: row.usedFor.text.trim(),
      );
      if (!success) ok = false;
    }

    final infoSaved = await StudentQueries.saveMedicalInfo({
      'student_id': studentId,
      'surgery_history': _surgery.text.trim(),
      'medical_conditions': _medicalConditions.text.trim(),
      'head_injury_history': _headInjury.text.trim(),
      'allergies': _allergies.text.trim(),
      'eating_habits': _eatingHabits.text.trim(),
      'sleeping_habits': _sleepingHabits.text.trim(),
    });
    if (!infoSaved) ok = false;

    setState(() => _saving = false);
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Medication table ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 5, child: Text('Medication', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))),
                      Expanded(flex: 5, child: Text('Used For', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))),
                      SizedBox(width: 32),
                    ],
                  ),
                ),
                ...List.generate(_medicationRows.length, (i) {
                  final row = _medicationRows[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 5, child: _smallField(row.name)),
                        const SizedBox(width: 12),
                        Expanded(flex: 5, child: _smallField(row.usedFor)),
                        SizedBox(
                          width: 32,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                            onPressed: () => _removeRow(i),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, right: 14),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Q&A section ──────────────────────────────────────────────
          _qaField(_surgery, 'Has your child ever had surgery or hospitalization for psychiatric/behavioral issues?'),
          _qaField(_medicalConditions, 'Has your child been diagnosed with any medical conditions, eg: seizures, disorders, mobile pain etc?'),
          _qaField(_headInjury, 'Has your child been diagnosed with any injury?'),
          _qaField(_allergies, 'Does your child have known food or any allergies?'),
          _qaField(_eatingHabits, 'Describe your childs eating habits'),
          _qaField(_sleepingHabits, 'Describe your childs sleeping habits'),

          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _smallField(TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Widget _qaField(TextEditingController ctrl, String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: 'Value',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationRow {
  final TextEditingController name = TextEditingController();
  final TextEditingController usedFor = TextEditingController();
}
