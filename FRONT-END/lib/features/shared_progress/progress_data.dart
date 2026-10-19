// lib/features/shared_progress/progress_data.dart
//
// Loads the raw records behind the director and admin "Student Progress"
// pages (students, daily data sheets, VB-MAPP milestone assessments) and
// derives the per-student numbers both pages show. Counting rules come from
// core/services/progress_metrics.dart so they agree with the therapist pages.
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/services/db_queries.dart';
import 'package:roh_erp/core/services/governance_settings.dart';
import 'package:roh_erp/core/services/progress_metrics.dart';

/// VB-MAPP milestone total is out of 170 (Levels 1-3).
const double milestoneMaxScore = 170;

/// Milestone domains shown in the cohort heatmap. Each VB-MAPP level a
/// domain appears in contributes 5 milestones, so [max] = 5 x levels.
const List<({String label, String key, double max})> vbMappDomains = [
  (label: 'Mand', key: 'manding_score', max: 15),
  (label: 'Tact', key: 'tacting_score', max: 15),
  (label: 'Listener', key: 'listener_score', max: 15),
  (label: 'VP/MTS', key: 'vp_mts_score', max: 15),
  (label: 'Play', key: 'play_score', max: 15),
  (label: 'Social', key: 'social_score', max: 15),
  (label: 'Imitation', key: 'imitation_score', max: 10),
  (label: 'Echoic', key: 'echoic_score', max: 10),
  (label: 'Vocal', key: 'vocal_score', max: 5),
  (label: 'LRFFC', key: 'lrffc_score', max: 10),
  (label: 'Intraverbal', key: 'intraverbal_score', max: 10),
  (label: 'Group', key: 'group_score', max: 10),
  (label: 'Linguistics', key: 'linguistic_score', max: 10),
  (label: 'Reading', key: 'reading_score', max: 5),
  (label: 'Writing', key: 'writing_score', max: 5),
  (label: 'Math', key: 'math_score', max: 5),
];

double numValue(Object? v) => double.tryParse(v?.toString() ?? '') ?? 0;

/// Formats a score without a trailing ".0" (e.g. 12, 7.5).
String formatScore(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

DateTime? parseDay(Object? raw) {
  final s = (raw ?? '').toString().split('T').first;
  if (s.isEmpty) return null;
  final d = DateTime.tryParse(s);
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

String studentDisplayName(Map<String, dynamic> s) {
  final name = (s['name'] ?? '').toString().trim();
  if (name.isNotEmpty) return name;
  return '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
}

/// Newest milestone row per student: highest test_number, then highest id.
Map<String, Map<String, dynamic>> latestMilestones(
    List<Map<String, dynamic>> rows) {
  final result = <String, Map<String, dynamic>>{};
  for (final r in rows) {
    final sid = '${r['student_id']}';
    final current = result[sid];
    if (current == null) {
      result[sid] = r;
      continue;
    }
    final t = numValue(r['test_number']);
    final ct = numValue(current['test_number']);
    if (t > ct || (t == ct && numValue(r['id']) > numValue(current['id']))) {
      result[sid] = r;
    }
  }
  return result;
}

Future<List<Map<String, dynamic>>> _fetchList(String action) async {
  try {
    final res = await ApiService().get(action);
    if (res is List) {
      return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
  } catch (_) {}
  return [];
}

class StudentProgressRow {
  final String studentId;
  final String name;
  final int targetsMastered;
  final int sessions30d;
  final double? successPct30d;
  final Map<String, dynamic>? latestMilestone;

  StudentProgressRow({
    required this.studentId,
    required this.name,
    required this.targetsMastered,
    required this.sessions30d,
    required this.successPct30d,
    required this.latestMilestone,
  });
}

class ProgressData {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> dailyRows;
  final List<Map<String, dynamic>> milestones;

  ProgressData({
    required this.students,
    required this.dailyRows,
    required this.milestones,
  });

  /// Also loads the governance settings so [targets] uses the director's
  /// mastery criteria.
  static Future<ProgressData> load() async {
    final results = await Future.wait([
      StudentQueries.fetchAll(),
      _fetchList('get_daily_data'),
      _fetchList('get_milestone_assessments'),
      GovernanceSettings.load().then((_) => <Map<String, dynamic>>[]),
    ]);
    return ProgressData(
      students: results[0],
      dailyRows: results[1],
      milestones: results[2],
    );
  }

  bool get hasAnyData => dailyRows.isNotEmpty || milestones.isNotEmpty;

  late final List<TargetProgress> targets = targetProgress(dailyRows);

  late final Map<String, Map<String, dynamic>> latestMilestoneByStudent =
      latestMilestones(milestones);

  /// Student id -> display name, from the student list and, for any student
  /// only present in records, the name the record carries.
  late final Map<String, String> studentNames = () {
    final names = <String, String>{};
    for (final s in students) {
      names['${s['id']}'] = studentDisplayName(s);
    }
    for (final r in [...dailyRows, ...milestones]) {
      final id = '${r['student_id']}';
      names.putIfAbsent(id, () => (r['student_name'] ?? 'Student').toString());
    }
    return names;
  }();

  /// One row per student with progress figures, alphabetically.
  List<StudentProgressRow> studentRows({DateTime? now}) {
    final day = now ?? today();
    final since = day.subtract(const Duration(days: 30));

    final mastered = <String, int>{};
    for (final t in targets) {
      if (t.mastered) mastered[t.studentId] = (mastered[t.studentId] ?? 0) + 1;
    }

    final sessionDates = <String, Set<DateTime>>{};
    final trials = <String, int>{};
    final successes = <String, int>{};
    for (final r in dailyRows) {
      final d = rowDate(r);
      if (d == null || d.isBefore(since) || d.isAfter(day)) continue;
      final sid = '${r['student_id']}';
      (sessionDates[sid] ??= {}).add(d);
      if (!isSkillRow(r)) continue;
      trials[sid] = (trials[sid] ?? 0) + trialsCompleted(r);
      successes[sid] = (successes[sid] ?? 0) + trialsSuccessful(r);
    }

    final rows = studentNames.entries.map((e) {
      final sid = e.key;
      final t = trials[sid] ?? 0;
      return StudentProgressRow(
        studentId: sid,
        name: e.value,
        targetsMastered: mastered[sid] ?? 0,
        sessions30d: sessionDates[sid]?.length ?? 0,
        successPct30d: t > 0 ? (successes[sid] ?? 0) / t * 100 : null,
        latestMilestone: latestMilestoneByStudent[sid],
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return rows;
  }
}
