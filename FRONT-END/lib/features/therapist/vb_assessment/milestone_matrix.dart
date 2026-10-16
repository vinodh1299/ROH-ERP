import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'assessment_records.dart';

/// Shared drawing of the VB-MAPP milestone matrix cells.
///
/// A domain score is the number of milestones achieved, in steps of ½
/// (each milestone scores 0, ½ or 1). So a Tact score of 2.5 means
/// milestones 1–2 in full plus the bottom half of milestone 3.
/// Each half of a cell takes the colour of the first test that achieved it.

const milestoneTestColors = {
  1: Color(0xFFFBBF24), // Yellow (1st Test)
  2: Color(0xFFF97316), // Orange (2nd Test)
  3: Color(0xFF10B981), // Green (3rd Test)
  4: Color(0xFF3B82F6), // Blue (4th Test)
};

/// milestone_assessments column holding the score for a matrix column title.
String? milestoneScoreColumn(String colName) {
  final lower = colName.toLowerCase();
  if (lower.contains('mand')) return 'manding_score';
  if (lower.contains('tact')) return 'tacting_score';
  if (lower.contains('listener')) return 'listener_score';
  if (lower.contains('vp') || lower.contains('mts')) return 'vp_mts_score';
  if (lower.contains('play')) return 'play_score';
  if (lower.contains('social')) return 'social_score';
  if (lower.contains('imitation')) return 'imitation_score';
  if (lower.contains('echoic')) return 'echoic_score';
  if (lower.contains('vocal')) return 'vocal_score';
  if (lower.contains('lrffc')) return 'lrffc_score';
  if (lower.contains('intraverbal')) return 'intraverbal_score';
  if (lower.contains('group')) return 'group_score';
  if (lower.contains('linguistic')) return 'linguistic_score';
  if (lower.contains('reading')) return 'reading_score';
  if (lower.contains('writing')) return 'writing_score';
  if (lower.contains('math')) return 'math_score';
  return null;
}

double milestoneScore(Map<String, dynamic> record, String colName) {
  final column = milestoneScoreColumn(colName);
  if (column == null) return 0;
  return double.tryParse(record[column]?.toString() ?? '') ?? 0;
}

/// Which test first filled each half of milestone [row] in [colName]:
/// the bottom half needs a score of at least row − ½, the top half the full row.
({int? bottom, int? top}) milestoneCellTests(
    List<Map<String, dynamic>> records, String colName, int row) {
  int? bottom;
  int? top;
  for (final r in records) {
    final test = recordTestNumber(r);
    final score = milestoneScore(r, colName);
    if (score >= row - 0.5 && (bottom == null || test < bottom)) bottom = test;
    if (score >= row && (top == null || test < top)) top = test;
  }
  return (bottom: bottom, top: top);
}

/// One matrix cell split into a top and bottom half by a thin divider,
/// with the milestone number on top.
class MilestoneMatrixCell extends StatelessWidget {
  final int row;
  final int? bottomTest;
  final int? topTest;
  final double height;

  const MilestoneMatrixCell({
    super.key,
    required this.row,
    required this.bottomTest,
    required this.topTest,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = milestoneTestColors[bottomTest] ?? Colors.white;
    final top = milestoneTestColors[topTest] ?? Colors.white;
    final filled = bottomTest != null || topTest != null;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(child: Container(color: top)),
              Container(height: 0.6, color: const Color(0xFFE5D5F5)),
              Expanded(child: Container(color: bottom)),
            ],
          ),
          Center(
            child: Text(
              '$row',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.black87 : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
