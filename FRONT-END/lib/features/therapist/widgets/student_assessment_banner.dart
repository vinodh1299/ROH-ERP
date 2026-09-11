import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_images.dart';

class StudentAssessmentBanner extends StatelessWidget {
  final String studentName;
  final String dateOfBirth;
  final String age;
  final Widget? rightContent;

  const StudentAssessmentBanner({
    super.key,
    this.studentName = 'Alex Thomas Sam',
    this.dateOfBirth = '16-02-2020',
    this.age = '13',
    this.rightContent,
  });

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
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Student photo
          AppImages.studentAvatar(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 20),
          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Date of Birth : $dateOfBirth',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
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
                        width: 24,
                        height: 20,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$i',
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
            ),
          ),
          // Right content (scores table, dates, or inputs)
          if (rightContent != null) rightContent! else const DefaultAssessmentScoreTable(),
        ],
      ),
    );
  }
}

class DefaultAssessmentScoreTable extends StatelessWidget {
  const DefaultAssessmentScoreTable({super.key});

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
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25)),
            children: const [
              _HeaderCell('Key'),
              _HeaderCell('Score'),
              _HeaderCell('Date'),
              _HeaderCell('Colour'),
              _HeaderCell('Tester'),
            ],
          ),
          _buildRow('1st Test', '10.5', '21-03-2021', const Color(0xFF10B981), 'Kezia'),
          _buildRow('2nd Test', '14.5', '21-03-2021', const Color(0xFFF59E0B), 'Kezia'),
          _buildRow('3rd Test', '13.5', '21-03-2021', const Color(0xFFEF4444), 'Kezia'),
          _buildRow('4th Test', '', '', const Color(0xFF3B82F6), ''),
        ],
      ),
    );
  }

  static TableRow _buildRow(String key, String score, String date, Color color, String tester) {
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
