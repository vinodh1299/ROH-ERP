// lib/features/therapist/vb_assessment/vb_assessment_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/db_queries.dart';

class VbAssessmentPage extends StatefulWidget {
  const VbAssessmentPage({super.key});

  @override
  State<VbAssessmentPage> createState() => _VbAssessmentPageState();
}

class _VbAssessmentPageState extends State<VbAssessmentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _selectedStudent = 'Aarav Patel (Age: 8)';
  String _selectedLevel = 'Level 1';
  String _assessmentDate = '2026-09-08';
  double _totalScore = 5.5;

  // Domain scores
  double _tactScore = 5.5;
  double _mandScore = 4.0;
  double _listenerScore = 5.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddAssessmentDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _AddAssessmentModal(
        onSaved: (date, score) {
          setState(() {
            _assessmentDate = date;
            _totalScore = score;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('VB Assessment saved!'), backgroundColor: Colors.green),
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
          // ── Top Header Banner (NEW UI Style) ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C4FD6), Color(0xFFBB6FEE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9C4FD6).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Therapist VB-MAPP Assessment & Milestones',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Student: $_selectedStudent  •  Date: $_assessmentDate',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('Total Score: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          Text(
                            _totalScore.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF9C4FD6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Student Selector
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStudent,
                            dropdownColor: const Color(0xFF9C4FD6),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                            items: ['Aarav Patel (Age: 8)', 'Emma Watson (Age: 7)', 'Rahul Sharma (Age: 9)']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedStudent = v!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Level Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLevel,
                          dropdownColor: const Color(0xFF9C4FD6),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          items: ['Level 1', 'Level 2', 'Level 3']
                              .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedLevel = v!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _openAddAssessmentDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Assessment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF9C4FD6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Tabs Switcher (Assessment / Grid) ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF9C4FD6),
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: const Color(0xFF9C4FD6),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Assessment'),
                Tab(text: 'Grid / Milestones'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Tab Views ──────────────────────────────────────────────────────
          SizedBox(
            height: 650,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssessmentTab(),
                _buildGridTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Assessment Tab Content ───────────────────────────────────────────────
  Widget _buildAssessmentTab() {
    return ListView(
      children: [
        // TACT Domain Card
        _DomainCard(
          domainTitle: 'TACT',
          subScore: _tactScore,
          items: [
            _CriterionItem(
              title: 'Tacts people, pets, characters, or favorite objects',
              description: 'Emits tact responses for familiar targets when presented visually.',
              score: 3.0,
              onScoreChanged: (v) => setState(() => _tactScore = v),
            ),
            _CriterionItem(
              title: 'Tacts any 2 items independently',
              description: 'Consistently tacts at least 2 items without echoic or physical prompts.',
              score: 2.5,
              onScoreChanged: (v) {},
            ),
          ],
        ),
        const SizedBox(height: 16),

        // MAND Domain Card
        _DomainCard(
          domainTitle: 'MAND',
          subScore: _mandScore,
          items: [
            _CriterionItem(
              title: 'Emits 11 different mands without prompts',
              description: 'Requests desired items independently using verbal words or sign language.',
              score: 2.0,
              onScoreChanged: (v) {},
            ),
            _CriterionItem(
              title: 'Mands for missing items needed for an activity',
              description: 'Asks for missing parts during structured play tasks.',
              score: 2.0,
              onScoreChanged: (v) {},
            ),
          ],
        ),
        const SizedBox(height: 16),

        // LISTENER RESPONDING Domain Card
        _DomainCard(
          domainTitle: 'LISTENER RESPONDING',
          subScore: _listenerScore,
          items: [
            _CriterionItem(
              title: 'Attends to speaker voice by orienting toward speaker',
              description: 'Turns head and looks at instructor when name is called.',
              score: 2.5,
              onScoreChanged: (v) {},
            ),
            _CriterionItem(
              title: 'Responds to 5 simple motor instructions',
              description: 'Follows sit down, stand up, come here, hands quiet, clap hands.',
              score: 2.5,
              onScoreChanged: (v) {},
            ),
          ],
        ),
      ],
    );
  }

  // ── 2. Grid / Milestones Tab Content (NEW UI Color Bar Matrix) ──────────────
  Widget _buildGridTab() {
    final domains = ['MAND', 'TACT', 'LISTENER', 'VP/MTS', 'PLAY', 'SOCIAL', 'MOTOR', 'ECHOIC', 'VOCAL'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('VB-MAPP Milestone Score Matrix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEBF9F1), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: const [
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFF16DBAA)),
                    SizedBox(width: 6),
                    Text('Level 1 (0-18m)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1F9254))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: const [
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFFFF9800)),
                    SizedBox(width: 6),
                    Text('Level 2 (18-30m)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: const [
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFF2196F3)),
                    SizedBox(width: 6),
                    Text('Level 3 (30-48m)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Milestone Bar Matrix Headers
          Row(
            children: domains.map((d) {
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Bar Chart Matrix Grid Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _BarColumn(heightFactor: 0.7, color: const Color(0xFF16DBAA), scoreLabel: '3.5'),
                  _BarColumn(heightFactor: 0.9, color: const Color(0xFF16DBAA), scoreLabel: '4.5'),
                  _BarColumn(heightFactor: 0.6, color: const Color(0xFFFF9800), scoreLabel: '3.0'),
                  _BarColumn(heightFactor: 0.4, color: const Color(0xFFFF9800), scoreLabel: '2.0'),
                  _BarColumn(heightFactor: 0.8, color: const Color(0xFF16DBAA), scoreLabel: '4.0'),
                  _BarColumn(heightFactor: 0.5, color: const Color(0xFF2196F3), scoreLabel: '2.5'),
                  _BarColumn(heightFactor: 0.7, color: const Color(0xFF16DBAA), scoreLabel: '3.5'),
                  _BarColumn(heightFactor: 0.85, color: const Color(0xFFFF9800), scoreLabel: '4.2'),
                  _BarColumn(heightFactor: 0.65, color: const Color(0xFF2196F3), scoreLabel: '3.2'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final double heightFactor;
  final Color color;
  final String scoreLabel;

  const _BarColumn({required this.heightFactor, required this.color, required this.scoreLabel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(scoreLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          FractionallySizedBox(
            heightFactor: heightFactor,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainCard extends StatelessWidget {
  final String domainTitle;
  final double subScore;
  final List<Widget> items;

  const _DomainCard({
    required this.domainTitle,
    required this.subScore,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(6)),
                child: Text(domainTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF9C4FD6))),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Text('Sub Score: ${subScore.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(children: items),
        ],
      ),
    );
  }
}

class _CriterionItem extends StatelessWidget {
  final String title;
  final String description;
  final double score;
  final ValueChanged<double> onScoreChanged;

  const _CriterionItem({
    required this.title,
    required this.description,
    required this.score,
    required this.onScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade50),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.purple.shade200)),
            child: Text('Score: ${score.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9C4FD6))),
          ),
        ],
      ),
    );
  }
}

class _AddAssessmentModal extends StatefulWidget {
  final void Function(String date, double score) onSaved;
  const _AddAssessmentModal({required this.onSaved});

  @override
  State<_AddAssessmentModal> createState() => _AddAssessmentModalState();
}

class _AddAssessmentModalState extends State<_AddAssessmentModal> {
  final _dateController = TextEditingController(text: '2026-09-08');
  final _scoreController = TextEditingController(text: '5.5');

  @override
  void dispose() {
    _dateController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  void _submit() {
    final score = double.tryParse(_scoreController.text) ?? 5.5;
    widget.onSaved(_dateController.text, score);
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
            gradient: const LinearGradient(
              colors: [Color(0xFF9C4FD6), Color(0xFFBB6FEE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    const Text('Add Assessment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(labelText: 'Assessment Date', hintText: 'YYYY-MM-DD', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _scoreController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Assessment Score', hintText: 'e.g. 5.5', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C4FD6), foregroundColor: Colors.white),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
