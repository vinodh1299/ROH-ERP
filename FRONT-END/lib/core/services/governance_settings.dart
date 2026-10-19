// lib/core/services/governance_settings.dart
//
// Clinical governance values (mastery criteria, review threshold) saved by
// the director in Settings. Fetched once per app session and cached so the
// progress rules in progress_metrics.dart can read them synchronously.
// Until the first load finishes the defaults below apply.

import 'api_service.dart';

class GovernanceSettings {
  static const String defaultMasteryCriteria =
      '80% across 3 consecutive sessions';
  static const double defaultMasteryRatio = 0.8;
  static const int defaultMasterySessions = 3;
  static const int defaultStagnationDays = 21;

  final String masteryCriteria;
  final double masteryRatio;
  final int masterySessions;
  final int stagnationDays;

  const GovernanceSettings._({
    required this.masteryCriteria,
    required this.masteryRatio,
    required this.masterySessions,
    required this.stagnationDays,
  });

  static const GovernanceSettings defaults = GovernanceSettings._(
    masteryCriteria: defaultMasteryCriteria,
    masteryRatio: defaultMasteryRatio,
    masterySessions: defaultMasterySessions,
    stagnationDays: defaultStagnationDays,
  );

  static GovernanceSettings _current = defaults;
  static Future<GovernanceSettings>? _loading;

  /// The cached settings (defaults until [load] has completed once).
  static GovernanceSettings get current => _current;

  /// Fetches the settings once per app session; later calls reuse the result.
  static Future<GovernanceSettings> load({bool force = false}) {
    if (force) _loading = null;
    return _loading ??= _fetch();
  }

  /// Drops the cache, e.g. after the director saves new settings.
  static void invalidate() => _loading = null;

  static Future<GovernanceSettings> _fetch() async {
    try {
      final g = await ApiService().get('get_governance_settings');
      if (g is Map && g['error'] == null) {
        _current = fromMap(g);
      } else if (g is Map) {
        // Request failed: allow a retry on the next load().
        _loading = null;
      }
    } catch (_) {
      _loading = null;
    }
    return _current;
  }

  static GovernanceSettings fromMap(Map g) {
    final criteria = (g['target_mastery_criteria'] ?? '').toString().trim();
    final parsed = parseMasteryCriteria(criteria);
    final days = int.tryParse((g['stagnation_alert_days'] ?? '').toString());
    return GovernanceSettings._(
      masteryCriteria: criteria.isEmpty ? defaultMasteryCriteria : criteria,
      masteryRatio: parsed.ratio,
      masterySessions: parsed.sessions,
      stagnationDays: days != null && days > 0 ? days : defaultStagnationDays,
    );
  }

  /// Reads "80% across 3 consecutive sessions", "90% across 2 sessions",
  /// "85 % over 4 sessions" etc. Missing parts fall back to 80% / 3.
  static ({double ratio, int sessions}) parseMasteryCriteria(String text) {
    double ratio = defaultMasteryRatio;
    int sessions = defaultMasterySessions;
    final pct = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(text);
    if (pct != null) {
      final v = double.tryParse(pct.group(1)!);
      if (v != null && v > 0 && v <= 100) ratio = v / 100;
    }
    final n =
        RegExp(r'(\d+)\s*(?:consecutive\s+)?sessions?', caseSensitive: false)
            .firstMatch(text);
    if (n != null) {
      final v = int.tryParse(n.group(1)!);
      if (v != null && v > 0) sessions = v;
    }
    return (ratio: ratio, sessions: sessions);
  }

  /// Short human description, e.g. "80% in 3 consecutive sessions".
  String get masteryDescription =>
      '${(masteryRatio * 100).round()}% in $masterySessions consecutive '
      'session${masterySessions == 1 ? '' : 's'}';
}
