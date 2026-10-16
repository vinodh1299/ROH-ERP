// lib/features/parent/graphs/graphs_page.dart
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import 'package:roh_erp/core/services/db_queries.dart';
import 'package:roh_erp/core/services/progress_metrics.dart';

class GraphsPage extends StatefulWidget {
  const GraphsPage({super.key});

  @override
  State<GraphsPage> createState() => _GraphsPageState();
}

class _GraphsPageState extends State<GraphsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _children = [];
  String? _selectedChildId;

  // Metrics for the selected child.
  List<({DateTime month, int count})> _monthly = [];
  int _totalTrials = 0;
  int _independentTrials = 0;
  int _gesturalTrials = 0;
  int _verbalTrials = 0;
  int _physicalTrials = 0;
  int _otherTrials = 0;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  String _childName(Map<String, dynamic> s) {
    final name = (s['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    final full = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
    return full.isEmpty ? 'Child' : full;
  }

  String get _selectedChildName {
    for (final c in _children) {
      if ('${c['id']}' == _selectedChildId) return _childName(c);
    }
    return 'your child';
  }

  Future<void> _loadChildren() async {
    if (mounted) setState(() => _isLoading = true);
    final children = await StudentQueries.fetchAll();
    if (!mounted) return;
    _children = children;
    final ids = children.map((c) => '${c['id']}').toList();
    if (_selectedChildId == null || !ids.contains(_selectedChildId)) {
      _selectedChildId = ids.isEmpty ? null : ids.first;
    }
    await _loadChildMetrics();
  }

  Future<void> _loadChildMetrics() async {
    final childId = _selectedChildId;
    if (childId == null) {
      _resetMetrics();
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (mounted) setState(() => _isLoading = true);

    final rows = (await DailyDataQueries.fetchForStudent(childId))
        .where((r) => '${r['student_id']}' == childId)
        .toList();
    if (!mounted || childId != _selectedChildId) return;

    final skillRows = rows.where(isSkillRow).toList();
    int total = 0, ind = 0, gest = 0, verb = 0, phys = 0, other = 0;
    for (final row in skillRows) {
      final trials =
          int.tryParse(row['trials_completed']?.toString() ?? '0') ?? 0;
      total += trials;
      final prompt = (row['prompt_level'] ?? '').toString().toLowerCase();
      if (prompt.contains('indep')) {
        ind += trials;
      } else if (prompt.contains('gest')) {
        gest += trials;
      } else if (prompt.contains('verb')) {
        verb += trials;
      } else if (prompt.contains('phys')) {
        phys += trials;
      } else {
        other += trials;
      }
    }

    setState(() {
      _monthly = masteredPerMonth(targetProgress(skillRows));
      _totalTrials = total;
      _independentTrials = ind;
      _gesturalTrials = gest;
      _verbalTrials = verb;
      _physicalTrials = phys;
      _otherTrials = other;
      _isLoading = false;
    });
  }

  void _resetMetrics() {
    _monthly = [];
    _totalTrials = 0;
    _independentTrials = 0;
    _gesturalTrials = 0;
    _verbalTrials = 0;
    _physicalTrials = 0;
    _otherTrials = 0;
  }

  void _selectChild(String id) {
    if (id == _selectedChildId) return;
    setState(() {
      _selectedChildId = id;
      _resetMetrics();
    });
    _loadChildMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final hasChild = _selectedChildId != null;
    return RefreshIndicator(
      onRefresh: _loadChildren,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Breakpoints.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Skill Acquisition Graphs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasChild
                              ? 'Targets mastered each month and prompt levels used, from $_selectedChildName\'s daily therapy data sheets'
                              : 'Targets mastered each month and prompt levels used, from your child\'s daily therapy data sheets',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: _isLoading ? null : _loadChildren,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_children.length > 1) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _children)
                    ChoiceChip(
                      label: Text(_childName(c)),
                      selected: '${c['id']}' == _selectedChildId,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: '${c['id']}' == _selectedChildId
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: '${c['id']}' == _selectedChildId
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                      ),
                      onSelected: (_) => _selectChild('${c['id']}'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!hasChild)
              _buildEmptyCard(
                Icons.child_care_outlined,
                'No child linked to this account',
                'Graphs will appear here once your child is enrolled and linked to your parent account.',
              )
            else if (_totalTrials == 0 && _monthly.every((m) => m.count == 0))
              _buildEmptyCard(
                Icons.show_chart,
                'No therapy data yet',
                'Graphs for $_selectedChildName will appear once therapists record daily data sheets.',
              )
            else ...[
              _buildMonthlyCard(),
              const SizedBox(height: 24),
              _buildPromptCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(IconData icon, String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // Monthly Target Acquisition Bar Chart Card
  Widget _buildMonthlyCard() {
    final totalMastered = _monthly.fold<int>(0, (sum, m) => sum + m.count);
    final maxVal =
        _monthly.fold<int>(0, (mx, m) => m.count > mx ? m.count : mx);
    final now = DateTime.now();

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
              const Icon(Icons.show_chart, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Targets Mastered per Month',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalMastered in 6 months',
                  style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'New skill targets mastered in each of the last 6 months. A target is mastered in its first session with at least 5 trials at 80% or better.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 500;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _monthly.map((m) {
                  final isCurrent =
                      m.month.year == now.year && m.month.month == now.month;
                  final barHeight = m.count == 0 || maxVal == 0
                      ? 4.0
                      : (150.0 * m.count / maxVal).clamp(8.0, 150.0);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${m.count}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: wide ? 44 : 26,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: m.count == 0
                              ? AppColors.divider
                              : (isCurrent
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.45)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        monthLabel(m.month),
                        style: TextStyle(
                          fontSize: wide ? 12 : 10,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Prompt Level Breakdown Card
  Widget _buildPromptCard() {
    double ratio(int n) => _totalTrials == 0 ? 0 : n / _totalTrials;
    String pct(int n) => '${(ratio(n) * 100).toStringAsFixed(0)}% of trials';

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
          const Row(
            children: [
              Icon(Icons.auto_awesome_motion,
                  color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Prompt Levels Used',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _totalTrials == 0
                ? 'No skill trials recorded yet'
                : 'Share of $_totalTrials recorded skill trials by the prompt level used',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _buildPromptLevelRow('Independent (Unprompted)',
              ratio(_independentTrials), pct(_independentTrials), Colors.green),
          const SizedBox(height: 12),
          _buildPromptLevelRow('Gestural / Point Prompt',
              ratio(_gesturalTrials), pct(_gesturalTrials), Colors.blue),
          const SizedBox(height: 12),
          _buildPromptLevelRow('Verbal / Phonemic Prompt',
              ratio(_verbalTrials), pct(_verbalTrials), Colors.orange),
          const SizedBox(height: 12),
          _buildPromptLevelRow('Physical Guidance Prompt',
              ratio(_physicalTrials), pct(_physicalTrials), Colors.redAccent),
          if (_otherTrials > 0) ...[
            const SizedBox(height: 12),
            _buildPromptLevelRow('Other / Not Recorded', ratio(_otherTrials),
                pct(_otherTrials), Colors.grey),
          ],
        ],
      ),
    );
  }

  Widget _buildPromptLevelRow(
      String label, double ratio, String percentageText, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(percentageText,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}
