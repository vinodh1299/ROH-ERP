import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'assessment_records.dart';

/// VB-MAPP milestone scoring and the shared drawing of the matrix cells.
///
/// Each milestone scores 0, ½ or 1. Level 1 holds milestones 1–5 of each of
/// its domains, Level 2 milestones 6–10 and Level 3 milestones 11–15, so a
/// domain score (the sum of its milestones) is at most 5 per level and the
/// total at most 170. Per-milestone scores are saved in
/// scores_detail.milestone_scores = {"<domain>_score": {"<n>": 0.5|1}}; for
/// older records without them they are derived from the domain total (a Tact
/// score of 2.5 = milestones 1–2 in full plus half of milestone 3).
/// Each half of a matrix cell takes the colour of the first test that
/// achieved it (½ fills the bottom half, 1 the whole cell).

/// Domain columns of each VB-MAPP level, in matrix order.
const milestoneLevelColumns = <int, List<String>>{
  1: [
    'Mand', 'Tact', 'Listener', 'VP/ MTS', 'Play', 'Social', 'Imitation',
    'Echoic', 'Vocal',
  ],
  2: [
    'Mand', 'Tact', 'Listener', 'VP/ MTS', 'Play', 'Social', 'Imitation',
    'Echoic', 'LRFFC', 'Intraverbal', 'Group', 'Linguistics',
  ],
  3: [
    'Mand', 'Tact', 'Listener', 'VP/ MTS', 'Play', 'Social', 'Reading',
    'LRFFC', 'Writing', 'Intraverbal', 'Group', 'Linguistics', 'Math',
  ],
};

/// Milestone numbers of a level (Level 2 → 6..10).
List<int> milestoneNumbers(int level) =>
    [for (int i = 1; i <= 5; i++) (level - 1) * 5 + i];

int milestoneLevelOf(int milestone) => (milestone - 1) ~/ 5 + 1;

/// Whether [column] (a *_score column) has milestones at [level].
bool milestoneDomainAtLevel(String column, int level) =>
    milestoneLevelColumns[level]!
        .any((c) => milestoneScoreColumn(c) == column);

/// Every *_score column used by the milestone matrix.
final List<String> milestoneScoreColumns = {
  for (final cols in milestoneLevelColumns.values)
    for (final c in cols) milestoneScoreColumn(c)!,
}.toList();

/// Per-milestone scores of a record: column → {milestone number → score}.
Map<String, Map<int, double>> milestoneScoresOf(Map<String, dynamic> record) {
  final saved =
      jsonColumnMap(jsonColumnMap(record['scores_detail'])['milestone_scores']);
  final result = <String, Map<int, double>>{};
  if (saved.isNotEmpty) {
    saved.forEach((column, items) {
      jsonColumnMap(items).forEach((n, v) {
        final number = int.tryParse(n);
        final score = double.tryParse(v.toString()) ?? 0;
        if (number != null && score > 0) {
          (result[column] ??= {})[number] = score;
        }
      });
    });
    return result;
  }
  // Older records: spread each domain total over its milestones in order.
  for (final column in milestoneScoreColumns) {
    var remaining = double.tryParse(record[column]?.toString() ?? '') ?? 0;
    for (int n = 1; n <= 15 && remaining > 0; n++) {
      if (!milestoneDomainAtLevel(column, milestoneLevelOf(n))) continue;
      final score = ((remaining.clamp(0, 1)) * 2).floor() / 2;
      if (score <= 0) break;
      (result[column] ??= {})[n] = score;
      remaining -= score;
    }
  }
  return result;
}

/// Whether the record stores per-milestone scores (not only domain totals).
bool hasMilestoneDetail(Map<String, dynamic> record) =>
    jsonColumnMap(jsonColumnMap(record['scores_detail'])['milestone_scores'])
        .isNotEmpty;

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

/// Which test first filled each half of milestone [row] in [colName]:
/// a score of ½ fills the bottom half, 1 fills both halves. Only the newest
/// record of each test counts.
({int? bottom, int? top}) milestoneCellTests(
    List<Map<String, dynamic>> records, String colName, int row) {
  final column = milestoneScoreColumn(colName);
  int? bottom;
  int? top;
  for (int test = 4; test >= 1; test--) {
    final r = newestRecordForTest(records, test);
    if (r == null || column == null) continue;
    final score = milestoneScoresOf(r)[column]?[row] ?? 0;
    if (score >= 0.5) bottom = test;
    if (score >= 1) top = test;
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
