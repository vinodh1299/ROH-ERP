// lib/features/shared_progress/student_progress_table.dart
//
// Per-student progress summary used by the director and admin
// "Student Progress" pages: a table on wide screens, cards on phones.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'progress_data.dart';

class StudentProgressTable extends StatelessWidget {
  final List<StudentProgressRow> rows;

  const StudentProgressTable({super.key, required this.rows});

  static String milestoneText(Map<String, dynamic>? m) {
    if (m == null) return '—';
    return '${formatScore(numValue(m['total_score']))} / 170';
  }

  static String milestoneDetail(Map<String, dynamic>? m) {
    if (m == null) return 'No milestone test';
    final date = parseDay(m['assessment_date']);
    final test = 'Test ${numValue(m['test_number']).toInt()}';
    return date == null ? test : '$test • ${DateFormat('dd MMM yyyy').format(date)}';
  }

  static String successText(double? pct) =>
      pct == null ? '—' : '${pct.toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 4),
            child: Text(
              'Per-Student Progress',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Text(
              'Targets mastered to date, sessions and trial success over the last 30 days, and the latest VB-MAPP milestone score.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Text(
                'No students to show yet.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth < 700
                  ? _buildCards()
                  : _buildTable(),
            ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    const header = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary);
    const cell = TextStyle(fontSize: 13, color: AppColors.textPrimary);

    Widget row(List<Widget> cells, {Color? color}) => Container(
          color: color,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Expanded(flex: 3, child: cells[0]),
              Expanded(flex: 2, child: cells[1]),
              Expanded(flex: 2, child: cells[2]),
              Expanded(flex: 2, child: cells[3]),
              Expanded(flex: 3, child: cells[4]),
            ],
          ),
        );

    return Column(
      children: [
        row(const [
          Text('STUDENT', style: header),
          Text('TARGETS MASTERED', style: header),
          Text('SESSIONS (30D)', style: header),
          Text('SUCCESS (30D)', style: header),
          Text('LATEST MILESTONE', style: header),
        ], color: const Color(0xFFF9F7FB)),
        for (final r in rows) ...[
          const Divider(height: 1, color: AppColors.divider),
          row([
            Text(r.name,
                style: cell.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
            Text('${r.targetsMastered}', style: cell),
            Text('${r.sessions30d}', style: cell),
            Text(successText(r.successPct30d), style: cell),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(milestoneText(r.latestMilestone), style: cell),
                Text(milestoneDetail(r.latestMilestone),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildCards() {
    return Column(
      children: [
        for (final r in rows) ...[
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _stat('Mastered', '${r.targetsMastered}')),
                    Expanded(
                        child: _stat('Sessions 30d', '${r.sessions30d}')),
                    Expanded(
                        child: _stat(
                            'Success 30d', successText(r.successPct30d))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Milestone: ${milestoneText(r.latestMilestone)}'
                  '${r.latestMilestone == null ? '' : ' (${milestoneDetail(r.latestMilestone)})'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

/// Centered icon + title + text card used for empty states.
class ProgressEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const ProgressEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
