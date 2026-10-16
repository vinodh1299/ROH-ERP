// lib/core/services/progress_metrics.dart
//
// Shared rules for turning daily_data_sheets rows into progress numbers, so
// the therapist data sheet, the parent pages and the director/admin progress
// pages all count the same way.

/// A target is mastered in a session where at least [masteryMinTrials]
/// trials were run and at least [masteryRatio] of them were successful.
const int masteryMinTrials = 5;
const double masteryRatio = 0.8;

int _int(Object? v) => int.tryParse(v?.toString() ?? '') ?? 0;

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

bool isMasterySession(Map<String, dynamic> row) {
  final completed = _int(row['trials_completed']);
  final successful = _int(row['trials_successful']);
  return completed >= masteryMinTrials &&
      successful / completed >= masteryRatio;
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
    required this.lastSuccessRatio,
    required this.therapistName,
  });

  bool get mastered => masteredOn != null;

  /// Days from first session to mastery.
  int? get daysToMastery => masteredOn == null || firstSession == null
      ? null
      : masteredOn!.difference(firstSession!).inDays;
}

/// One entry per skill target, with the date it was first mastered.
List<TargetProgress> targetProgress(List<Map<String, dynamic>> rows) {
  final byTarget = <String, List<Map<String, dynamic>>>{};
  for (final r in rows) {
    if (!isSkillRow(r) || rowDate(r) == null) continue;
    (byTarget[targetKey(r)] ??= []).add(r);
  }
  final result = <TargetProgress>[];
  byTarget.forEach((_, list) {
    list.sort((a, b) => rowDate(a)!.compareTo(rowDate(b)!));
    DateTime? masteredOn;
    for (final r in list) {
      if (isMasterySession(r)) {
        masteredOn = rowDate(r);
        break;
      }
    }
    final last = list.last;
    final lastCompleted = _int(last['trials_completed']);
    result.add(TargetProgress(
      studentId: '${last['student_id']}',
      studentName: (last['student_name'] ?? '').toString(),
      domain: (last['domain'] ?? '').toString(),
      target: (last['target_skill'] ?? '').toString(),
      firstSession: rowDate(list.first),
      lastSession: rowDate(last),
      masteredOn: masteredOn,
      lastSuccessRatio: lastCompleted == 0
          ? 0
          : _int(last['trials_successful']) / lastCompleted,
      therapistName: (last['therapist_name'] ?? '').toString(),
    ));
  });
  return result;
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
