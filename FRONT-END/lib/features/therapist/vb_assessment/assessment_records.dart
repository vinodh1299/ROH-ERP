import 'dart:convert';

/// Helpers for reading saved assessment rows (milestone, barriers, transition,
/// EESA) as returned by the get_*_assessments actions.

/// Decodes a JSON column that the API may return as a map or as a string.
Map<String, dynamic> jsonColumnMap(Object? raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return {};
}

int recordId(Map<String, dynamic> r) =>
    int.tryParse(r['id']?.toString() ?? '') ?? 0;

int recordTestNumber(Map<String, dynamic> r) =>
    int.tryParse(r['test_number']?.toString() ?? '') ?? 1;

/// The newest saved row for [testNumber]. Saves update this row, so older
/// duplicates (from before saves became updates) are ignored.
Map<String, dynamic>? newestRecordForTest(
    List<Map<String, dynamic>> records, int testNumber) {
  Map<String, dynamic>? newest;
  for (final r in records) {
    if (recordTestNumber(r) != testNumber) continue;
    if (newest == null || recordId(r) > recordId(newest)) newest = r;
  }
  return newest;
}

/// 'yyyy-MM-dd' of a saved row, or today when there is none. Re-saving an
/// existing test keeps its original assessment date.
String assessmentDateFor(Map<String, dynamic>? record) {
  final saved = (record?['assessment_date'] ?? '').toString().split('T').first;
  if (saved.isNotEmpty) return saved;
  return DateTime.now().toIso8601String().substring(0, 10);
}

/// Item scores per test number from a JSON score column (barrier_scores,
/// area_scores). Rows are applied oldest first, so a newer save of a test
/// overrides the items it scored.
Map<int, Map<String, int>> scoresPerTest(
    List<Map<String, dynamic>> records, String jsonColumn) {
  final sorted = [...records]..sort((a, b) => recordId(a).compareTo(recordId(b)));
  final perTest = <int, Map<String, int>>{};
  for (final r in sorted) {
    final scores = perTest[recordTestNumber(r)] ??= {};
    jsonColumnMap(r[jsonColumn]).forEach((item, v) {
      final score = int.tryParse(v.toString());
      if (score != null) scores[item] = score;
    });
  }
  return perTest;
}
