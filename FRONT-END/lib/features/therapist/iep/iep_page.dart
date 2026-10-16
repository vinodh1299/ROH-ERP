import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/db_queries.dart';
import '../widgets/student_card_grid.dart';

class IepPage extends StatefulWidget {
  const IepPage({super.key});

  @override
  State<IepPage> createState() => _IepPageState();
}

class _IepPageState extends State<IepPage> {
  String? _selectedStudent;
  int? _selectedStudentId;
  bool _saving = false;
  String? _savedStatus; // status of the latest saved IEP, if any
  String? _savedTitle;
  // Id of the loaded IEP when saving should edit it: it is still awaiting
  // sign-off and its goals were written by this page. Otherwise a save
  // creates a new plan.
  int? _editableIepId;
  // Latest IEP's goals when they were not written by this page (free text).
  String? _previousSummary;

  final List<Map<String, dynamic>> _mandingGoals = [];
  final List<Map<String, dynamic>> _tactingGoals = [];

  static const _defaultBaseline = 'Baseline assessment in progress.';

  /// goals_summary is plain text (the director, admin and parent portals show
  /// it as-is), written in a fixed shape so it can be read back here:
  ///   MANDING
  ///   A. <goal>
  ///      Baseline: <baseline>
  String _goalsSummary() {
    String clean(Object? v) =>
        (v ?? '').toString().replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();
    final out = StringBuffer();
    for (final section in [
      ('MANDING', _mandingGoals),
      ('TACTING', _tactingGoals),
    ]) {
      if (section.$2.isEmpty) continue;
      if (out.isNotEmpty) out.writeln();
      out.writeln(section.$1);
      for (final g in section.$2) {
        out.writeln('${g['label']}. ${clean(g['goal'])}');
        out.writeln('   Baseline: ${clean(g['baseline'])}');
      }
    }
    return out.toString().trimRight();
  }

  void _restoreGoals(String summary) {
    _mandingGoals.clear();
    _tactingGoals.clear();
    List<Map<String, dynamic>>? target;
    for (final line in summary.split('\n')) {
      final trimmed = line.trim();
      if (trimmed == 'MANDING') {
        target = _mandingGoals;
      } else if (trimmed == 'TACTING') {
        target = _tactingGoals;
      } else if (target != null) {
        final goal = RegExp(r'^([A-Z])\. (.*)$').firstMatch(trimmed);
        final baseline = RegExp(r'^Baseline: (.*)$').firstMatch(trimmed);
        if (goal != null) {
          target.add({
            'label': goal.group(1)!,
            'goal': goal.group(2)!,
            'baseline': _defaultBaseline,
          });
        } else if (baseline != null && target.isNotEmpty) {
          target.last['baseline'] = baseline.group(1)!;
        }
      }
    }
  }

  /// Loads the student's most recent IEP so its goals can be reviewed/extended.
  Future<void> _loadIep() async {
    final studentId = _selectedStudentId;
    if (studentId == null) return;
    final reports = await IepQueries.fetchAll();
    Map<String, dynamic>? latest;
    for (final r in reports) {
      if (r['student_id']?.toString() != '$studentId') continue;
      final id = int.tryParse(r['id']?.toString() ?? '') ?? 0;
      if (latest == null ||
          id > (int.tryParse(latest['id']?.toString() ?? '') ?? 0)) {
        latest = r;
      }
    }
    if (!mounted) return;
    setState(() {
      _savedStatus = latest?['status']?.toString();
      _savedTitle = latest?['title']?.toString();
      final summary = (latest?['goals_summary'] ?? '').toString().trim();
      _restoreGoals(summary);
      _previousSummary =
          _mandingGoals.isEmpty && _tactingGoals.isEmpty && summary.isNotEmpty
              ? summary
              : null;
      final editable = ['Pending Approval', 'Returned for Revision']
          .contains(_savedStatus);
      _editableIepId = editable && _previousSummary == null
          ? int.tryParse(latest?['id']?.toString() ?? '')
          : null;
    });
  }

  Future<void> _saveIep() async {
    final studentId = _selectedStudentId;
    if (studentId == null || _saving) return;
    if (_mandingGoals.isEmpty && _tactingGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one goal before saving the IEP.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _saving = true);

    // Domain scores come from the student's latest VB-MAPP milestone record.
    final milestones =
        await MilestoneAssessmentQueries.fetchForStudent('$studentId');
    Map<String, dynamic>? baseline;
    for (final m in milestones) {
      final id = int.tryParse(m['id']?.toString() ?? '') ?? 0;
      if (baseline == null ||
          id > (int.tryParse(baseline['id']?.toString() ?? '') ?? 0)) {
        baseline = m;
      }
    }
    int score(String column) =>
        (double.tryParse(baseline?[column]?.toString() ?? '') ?? 0).round();

    final now = DateTime.now();
    final ok = await IepQueries.save({
      if (_editableIepId != null) 'id': _editableIepId,
      'student_id': studentId,
      'title': '${_selectedStudent ?? 'Student'} IEP Treatment Plan',
      'cycle_term': 'Q${(now.month - 1) ~/ 3 + 1} ${now.year} Treatment Plan',
      'manding_score': score('manding_score'),
      'tacting_score': score('tacting_score'),
      'listener_score': score('listener_score'),
      'echoic_score': score('echoic_score'),
      'lrffc_score': score('lrffc_score'),
      'goals_summary': _goalsSummary(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the IEP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student IEP Saved Successfully!')),
    );
    await _loadIep();
  }

  void _showAddItemDialog() {
    final textController = TextEditingController();
    final baselineController = TextEditingController();
    var domain = 'Manding';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Goal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: [
                  for (final d in const ['Manding', 'Tacting'])
                    ChoiceChip(
                      label: Text(d),
                      selected: domain == d,
                      onSelected: (_) => setDialogState(() => domain = d),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Goal',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: 'enter the target goal',
                    hintStyle:
                        TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Baseline (optional)',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: baselineController,
                  decoration: const InputDecoration(
                    hintText: 'current level of performance',
                    hintStyle:
                        TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (textController.text.trim().isNotEmpty) {
                        final goals = domain == 'Tacting'
                            ? _tactingGoals
                            : _mandingGoals;
                        final baseline = baselineController.text.trim();
                        setState(() {
                          goals.add({
                            'label': String.fromCharCode(65 + goals.length),
                            'goal': textController.text.trim(),
                            'baseline':
                                baseline.isEmpty ? _defaultBaseline : baseline,
                          });
                        });
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B21A8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                    ),
                    child: const Text('Submit',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStudent == null) {
      return StudentCardGrid(
        title: 'Students Individualized Education Plan (IEP)',
        buttonLabel: 'Add',
        onStudentAction: (student, studentId) {
          setState(() {
            _selectedStudent = student;
            _selectedStudentId = studentId;
            _savedStatus = null;
            _savedTitle = null;
            _previousSummary = null;
            _editableIepId = null;
            _mandingGoals.clear();
            _tactingGoals.clear();
          });
          _loadIep();
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => setState(() => _selectedStudent = null),
                tooltip: 'Back to students',
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Students Individualized Education Plan (IEP)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Student IEP Header Banner
          _buildIepHeaderBanner(),
          const SizedBox(height: 16),

          // '+ Add' Action Link
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_savedStatus != null) ...[
                Expanded(
                  child: Text(
                    'Last saved IEP: ${_savedTitle ?? 'IEP'} ($_savedStatus)'
                    '${_editableIepId != null ? ' · Save updates this plan' : ' · Save creates a new plan for sign-off'}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              InkWell(
                onTap: _showAddItemDialog,
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: Breakpoints.isCompact(context) ? 44 : 0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_previousSummary != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PREVIOUS PLAN GOALS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _previousSummary!,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 1. MANDING Section
          _buildGoalSection('1. MANDING', _mandingGoals),
          const SizedBox(height: 24),

          // 2. TACTING Section
          _buildGoalSection('2. TACTING', _tactingGoals),
          const SizedBox(height: 24),

          // Save & Cancel Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _selectedStudent = null),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _saving ? null : _saveIep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_saving ? 'Saving…' : 'Save',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildIepHeaderBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 16 : 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Photo
          final photo = AppImages.studentAvatar(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(16),
          );

          // Name and Info
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedStudent ?? 'Student',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Date of Birth : —',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              const Text(
                'Age : —',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          );

          // Narrow: the schedule box goes full width under the photo + info.
          final narrow = constraints.maxWidth < 700;

          // Assessment Dates Dark Box
          final schedule = Container(
            width: narrow ? double.infinity : 320,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1035).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(12),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'ASSESSMENT SCHEDULE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Divider(color: Colors.white24, height: 12),
                _DateRow('1st Progress Report:', 'Scheduled (Q1)'),
                _DateRow('2nd Progress Report:', 'Scheduled (Q2)'),
                _DateRow('3rd Progress Report:', 'Scheduled (Q3)'),
                _DateRow('4th Progress Report:', 'Scheduled (Q4)'),
              ],
            ),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    photo,
                    const SizedBox(width: 16),
                    Expanded(child: info),
                  ],
                ),
                const SizedBox(height: 16),
                schedule,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              photo,
              const SizedBox(width: 20),
              Expanded(child: info),
              const SizedBox(width: 16),
              schedule,
            ],
          );
        },
      ),
    );
  }

  Widget _buildGoalSection(String title, List<Map<String, dynamic>> goals) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (goals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No individualized goals recorded for this domain yet.\nClick "+ Add" to document a clinical target.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5),
                ),
              ),
            )
          else
            for (final item in goals) ...[
              _buildGoalCard(item['label'] as String, item['goal'] as String,
                  item['baseline'] as String),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }

  Widget _buildGoalCard(String label, String goal, String baseline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target Goal Box
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFBA43DF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    goal,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'BASELINE',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        // Baseline Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            baseline,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  final String title;
  final String date;
  const _DateRow(this.title, this.date);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(title,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Text(date,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
