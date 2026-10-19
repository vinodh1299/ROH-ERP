// lib/core/services/progress_metrics.dart
//
// Shared rules for turning daily_data_sheets rows into progress numbers, so
// the therapist data sheet, the parent pages and the director/admin progress
// pages all count the same way.

import 'dart:convert';

import 'governance_settings.dart';

/// A session only counts towards mastery when at least [masteryMinTrials]
/// trials were run.
const int masteryMinTrials = 5;

/// Success ratio a session must reach, from the director's governance
/// setting `target_mastery_criteria` (default 80%). Callers should await
/// [GovernanceSettings.load] before computing progress.
double get masteryRatio => GovernanceSettings.current.masteryRatio;

/// Number of consecutive qualifying sessions needed for mastery (default 3).
int get masterySessions => GovernanceSettings.current.masterySessions;

/// "80% in 3 consecutive sessions (each with at least 5 trials)".
String get masteryRuleText =>
    '${GovernanceSettings.current.masteryDescription} '
    '(each with at least $masteryMinTrials trials)';

int _int(Object? v) => int.tryParse(v?.toString() ?? '') ?? 0;

// ── Manding sheet columns ───────────────────────────────────────────────────
// The therapist Manding tab saves one tally per column in the row's notes
// JSON as `counts`: FP, PP, FM/FV, PM/PV, F3, F5, F6, F6, Error, Vocal.
// Columns 0-7 are prompted responses, 8 is an incorrect / no response and
// 9 ("Vocal") is the independent (unprompted) mand — the only success.
const int mandingColumnCount = 10;
const int mandingPromptedColumns = 8; // columns 0-7
const int mandingErrorColumn = 8;
const int mandingIndependentColumn = 9;

/// Per-column manding tallies saved in [row]'s notes, or null when the row
/// has none (older rows, or other domains).
List<int>? mandingCounts(Map<String, dynamic> row) {
  Object? notes = row['notes'];
  if (notes is String) {
    if (!notes.contains('counts')) return null;
    try {
      notes = jsonDecode(notes);
    } catch (_) {
      return null;
    }
  }
  if (notes is! Map) return null;
  final c = notes['counts'];
  if (c is! List || c.length != mandingColumnCount) return null;
  return [for (final v in c) _int(v)];
}

/// Trials run in [row]. Manding rows with saved tallies count every column.
int trialsCompleted(Map<String, dynamic> row) {
  final counts = mandingCounts(row);
  if (counts != null) return counts.fold(0, (a, b) => a + b);
  return _int(row['trials_completed']);
}

/// Successful (independent) trials in [row]. For manding rows with saved
/// tallies this is the Vocal column only — rows saved by older versions
/// stored Error + Vocal in trials_successful, so the tallies win.
int trialsSuccessful(Map<String, dynamic> row) {
  final counts = mandingCounts(row);
  if (counts != null) return counts[mandingIndependentColumn];
  return _int(row['trials_successful']);
}

/// Session date of a row as a local calendar date, or null.
DateTime? rowDate(Map<String, dynamic> row) {
  final raw = (row['session_date'] ?? '').toString().split('T').first;
  if (raw.isEmpty) return null;
  try {
    final d = DateTime.parse(raw);
    return DateTime(d.year, d.month, d.day);
  } catch (_) {
    return null;
  }
}

/// Rows that record skill trials (not BRP plans, ABC incidents or problem
/// behaviour counts).
bool isSkillRow(Map<String, dynamic> row) {
  final domain = (row['domain'] ?? '').toString().toLowerCase();
  return domain != 'brp' &&
      !domain.contains('abc') &&
      !domain.contains('behavio');
}

/// True when this single session meets the per-session bar (enough trials
/// and at least [masteryRatio] success). Mastery itself needs
/// [masterySessions] of these in a row — see [masteryDate].
bool isMasterySession(Map<String, dynamic> row) {
  final completed = trialsCompleted(row);
  final successful = trialsSuccessful(row);
  return completed >= masteryMinTrials &&
      successful / completed >= masteryRatio;
}

/// Date a target was mastered: the date of the [masterySessions]-th
/// consecutive qualifying session in [sortedRows] (oldest first, one
/// target). Any non-qualifying session resets the run. Null if not mastered.
DateTime? masteryDate(List<Map<String, dynamic>> sortedRows) {
  final needed = masterySessions;
  int run = 0;
  for (final r in sortedRows) {
    if (isMasterySession(r)) {
      run++;
      if (run >= needed) return rowDate(r);
    } else {
      run = 0;
    }
  }
  return null;
}

/// Identifies one skill target of one student.
String targetKey(Map<String, dynamic> row) =>
    '${row['student_id']}|${(row['domain'] ?? '').toString().trim().toLowerCase()}'
    '|${(row['target_skill'] ?? '').toString().trim().toLowerCase()}';

class TargetProgress {
  final String studentId;
  final String studentName;
  final String domain;
  final String target;
  final DateTime? firstSession;
  final DateTime? lastSession;
  final DateTime? masteredOn;

  /// Date of the most recent session whose success % was higher than every
  /// earlier session of this target (the first session counts as the
  /// starting point). Used for "no recent progress" review flags.
  final DateTime? lastImproved;
  final double lastSuccessRatio;
  final String therapistName;

  TargetProgress({
    required this.studentId,
    required this.studentName,
    required this.domain,
    required this.target,
    required this.firstSession,
    required this.lastSession,
    required this.masteredOn,
    required this.lastImproved,
    required this.lastSuccessRatio,
    required this.therapistName,
  });

  bool get mastered => masteredOn != null;

  /// Days from first session to mastery.
  int? get daysToMastery => masteredOn == null || firstSession == null
      ? null
      : masteredOn!.difference(firstSession!).inDays;
}

/// One entry per skill target, with the date it was first mastered
/// (see [masteryDate] for the rule).
List<TargetProgress> targetProgress(List<Map<String, dynamic>> rows) {
  final byTarget = <String, List<Map<String, dynamic>>>{};
  for (final r in rows) {
    if (!isSkillRow(r) || rowDate(r) == null) continue;
    (byTarget[targetKey(r)] ??= []).add(r);
  }
  final result = <TargetProgress>[];
  byTarget.forEach((_, list) {
    list.sort((a, b) => rowDate(a)!.compareTo(rowDate(b)!));
    final masteredOn = masteryDate(list);
    DateTime? lastImproved;
    double best = -1;
    for (final r in list) {
      final completed = trialsCompleted(r);
      if (completed == 0) continue;
      final ratio = trialsSuccessful(r) / completed;
      if (ratio > best) {
        best = ratio;
        lastImproved = rowDate(r);
      }
    }
    final last = list.last;
    final lastCompleted = trialsCompleted(last);
    result.add(TargetProgress(
      studentId: '${last['student_id']}',
      studentName: (last['student_name'] ?? '').toString(),
      domain: (last['domain'] ?? '').toString(),
      target: (last['target_skill'] ?? '').toString(),
      firstSession: rowDate(list.first),
      lastSession: rowDate(last),
      masteredOn: masteredOn,
      lastImproved: lastImproved ?? rowDate(list.first),
      lastSuccessRatio:
          lastCompleted == 0 ? 0 : trialsSuccessful(last) / lastCompleted,
      therapistName: (last['therapist_name'] ?? '').toString(),
    ));
  });
  return result;
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String monthLabel(DateTime d) => _monthNames[d.month - 1];

/// Targets newly mastered in each of the last [months] calendar months,
/// oldest first, ending with the current month.
List<({DateTime month, int count})> masteredPerMonth(
    List<TargetProgress> targets,
    {int months = 6,
    DateTime? now}) {
  final today = now ?? DateTime.now();
  return [
    for (int i = months - 1; i >= 0; i--)
      () {
        final month = DateTime(today.year, today.month - i);
        final count = targets
            .where((t) =>
                t.masteredOn != null &&
                t.masteredOn!.year == month.year &&
                t.masteredOn!.month == month.month)
            .length;
        return (month: month, count: count);
      }(),
  ];
}
