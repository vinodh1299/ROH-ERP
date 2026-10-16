import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';
import 'package:roh_erp/core/layout/responsive.dart';
import '../vb_assessment/assessment_records.dart';
import '../vb_assessment/milestone_matrix.dart';

/// Formats a saved test's score for the key table (defaults to total_score).
typedef TestScoreLabel = String Function(Map<String, dynamic> record);

String _defaultScore(Map<String, dynamic> r) {
  final v = double.tryParse(r['total_score']?.toString() ?? '');
  if (v == null) return '—';
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

DateTime? _parseDate(Object? raw) {
  final text = (raw ?? '').toString().split('T').first;
  if (text.isEmpty) return null;
  try {
    return DateTime.parse(text);
  } catch (_) {
    return null;
  }
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Age as "4y 2m" on [on].
String _ageOn(DateTime dob, DateTime on) {
  var months = (on.year - dob.year) * 12 + on.month - dob.month;
  if (on.day < dob.day) months--;
  if (months < 0) return '—';
  return '${months ~/ 12}y ${months % 12}m';
}

class StudentAssessmentBanner extends StatelessWidget {
  final String studentName;
  final String dateOfBirth;
  final String age;
  final Widget? rightContent;

  /// Saved test records (newest row per test_number is used). They fill the
  /// key table and, through their student_dob, the date of birth and the
  /// age at each test.
  final List<Map<String, dynamic>> records;
  final TestScoreLabel scoreLabel;

  const StudentAssessmentBanner({
    super.key,
    this.studentName = 'Student',
    this.dateOfBirth = '-',
    this.age = '-',
    this.rightContent,
    this.records = const [],
    this.scoreLabel = _defaultScore,
  });

  DateTime? get _dob => records.isEmpty
      ? null
      : _parseDate(records.firstWhere((r) => r['student_dob'] != null,
          orElse: () => const {})['student_dob']);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 14 : 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final right = rightContent ??
              DefaultAssessmentScoreTable(
                  records: records, scoreLabel: scoreLabel);
          // Narrow: photo + details on top, score key full-width underneath.
          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AppImages.studentAvatar(
                      width: 56,
                      height: 56,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: _details()),
                  ],
                ),
                const SizedBox(height: 14),
                ScrollableMinWidth(minWidth: 360, child: right),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppImages.studentAvatar(
                width: 80,
                height: 80,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 20),
              Expanded(child: _details()),
              const SizedBox(width: 16),
              right,
            ],
          );
        },
      ),
    );
  }

  /// Age at the date of test [testNumber], or the test number when unknown.
  String _ageAtTest(int testNumber) {
    final dob = _dob;
    final date = _parseDate(
        newestRecordForTest(records, testNumber)?['assessment_date']);
    if (dob == null || date == null) return '$testNumber';
    return _ageOn(dob, date);
  }

  Widget _details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          studentName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Date of Birth : ${_dob == null ? dateOfBirth : _ymd(_dob!)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
        // Age at each test's date (only meaningful once tests are saved).
        if (records.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              Text(
                'Age at Testing: ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 4),
              for (int i = 1; i <= 4; i++)
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: milestoneTestColors[i],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _ageAtTest(i),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class DefaultAssessmentScoreTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final TestScoreLabel scoreLabel;

  const DefaultAssessmentScoreTable({
    super.key,
    this.records = const [],
    this.scoreLabel = _defaultScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1.0),
          2: FlexColumnWidth(1.4),
          3: FlexColumnWidth(1.0),
          4: FlexColumnWidth(1.1),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration:
                BoxDecoration(color: Colors.black.withValues(alpha: 0.25)),
            children: const [
              _HeaderCell('Key'),
              _HeaderCell('Score'),
              _HeaderCell('Date'),
              _HeaderCell('Colour'),
              _HeaderCell('Tester'),
            ],
          ),
          for (int t = 1; t <= 4; t++)
            () {
              // Colours match the graphs (yellow, orange, green, blue).
              final r = newestRecordForTest(records, t);
              final date = _parseDate(r?['assessment_date']);
              final tester = (r?['therapist_name'] ?? '').toString();
              return _buildRow(
                '${['1st', '2nd', '3rd', '4th'][t - 1]} Test',
                r == null ? '—' : scoreLabel(r),
                date == null ? '—' : _ymd(date),
                milestoneTestColors[t]!,
                tester.isEmpty ? '—' : tester,
              );
            }(),
        ],
      ),
    );
  }

  static TableRow _buildRow(
      String key, String score, String date, Color color, String tester) {
    return TableRow(
      children: [
        _BodyCell(key),
        _BodyCell(score),
        _BodyCell(date),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        _BodyCell(tester),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  const _BodyCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
