import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// VB-MAPP structure and licensed protocol content.
///
/// VB-MAPP (Sundberg, AVB Press) is copyrighted, so the app itself only holds
/// category names (barrier and transition area names, EESA group numbers).
/// Item text, scoring criteria, transition score bands and the EESA → Echoic
/// mapping are read from `assets/vbmapp/protocol_content.json`, which the
/// centre fills in from its licensed manual. Anything missing there falls
/// back to a placeholder label (and, for numbers, to manual entry).

const String vbmappProtocolAsset = 'assets/vbmapp/protocol_content.json';
const String _placeholderMarker = 'enter from licensed protocol';

/// Whether [text] holds real protocol content (not empty / not a placeholder).
bool isProtocolText(String? text) =>
    text != null &&
    text.trim().isNotEmpty &&
    !text.toLowerCase().contains(_placeholderMarker);

// ── Barriers ────────────────────────────────────────────────────────────────

/// One VB-MAPP barrier. [key] is the barrier_scores key stored in the
/// database (kept from the original 18-barrier version so old records load).
class VbBarrier {
  final int number;
  final String key;
  final String label;
  const VbBarrier(this.number, this.key, this.label);
}

/// All 24 barriers, in protocol order. Single source for every page.
const List<VbBarrier> vbBarriers = [
  VbBarrier(1, 'Behaviour Problems', 'Negative behaviors'),
  VbBarrier(2, 'Instructional Control', 'Poor instructional control'),
  VbBarrier(3, 'Impaired Mand', 'Mand: absent, weak or impaired'),
  VbBarrier(4, 'Impaired Tact', 'Tact: absent, weak or impaired'),
  VbBarrier(
      5, 'Impaired Imitation', 'Motor imitation: absent, weak or impaired'),
  VbBarrier(6, 'Impaired Echoic', 'Echoic: absent, weak or impaired'),
  VbBarrier(7, 'Impaired VP-MTS',
      'Visual perception & MTS: absent, weak or impaired'),
  VbBarrier(8, 'Impaired Listener Responding',
      'Listener skills: absent, weak or impaired'),
  VbBarrier(9, 'Impaired Intraverbal', 'Intraverbal: absent, weak or impaired'),
  VbBarrier(
      10, 'Impaired Social Skills', 'Social skills: absent, weak or impaired'),
  VbBarrier(11, 'Prompt Dependent', 'Prompt dependent'),
  VbBarrier(12, 'Scrolling', 'Scrolling responses'),
  VbBarrier(13, 'Impaired Scanning', 'Impaired scanning skills'),
  VbBarrier(14, 'Impaired Conditional Discrimination',
      'Failure to make conditional discriminations'),
  VbBarrier(15, 'Failure to Generalize', 'Failure to generalize'),
  VbBarrier(16, 'Weak Motivators', 'Weak or atypical motivating operations'),
  VbBarrier(17, 'Response Requirement weakens MO',
      'Response requirement weakens the MO'),
  VbBarrier(18, 'Reinforcer Dependent', 'Reinforcement dependent'),
  VbBarrier(19, 'Self-Stimulation', 'Self-stimulation'),
  VbBarrier(20, 'Articulation Problems', 'Articulation problems'),
  VbBarrier(
      21, 'Obsessive-Compulsive Behavior', 'Obsessive-compulsive behavior'),
  VbBarrier(22, 'Hyperactive Behavior', 'Hyperactive behavior'),
  VbBarrier(23, 'Failure to Make Eye Contact', 'Failure to make eye contact'),
  VbBarrier(24, 'Sensory Defensiveness', 'Sensory defensiveness'),
];

const int vbBarriersMaxScore = 96; // 24 barriers × 4

// ── Transition ──────────────────────────────────────────────────────────────

class VbTransitionArea {
  /// 1..18; stored as the area_scores key "1".."18". Areas 1–7 keep the
  /// numbering of the original 7-area version, so old records still load.
  final int number;
  final String label;
  final int category; // index into vbTransitionCategories
  const VbTransitionArea(this.number, this.label, this.category);
}

const List<String> vbTransitionCategories = [
  'Learner skills',
  'Learning patterns',
  'Self-help & spontaneity',
];

const List<VbTransitionArea> vbTransitionAreas = [
  VbTransitionArea(1, 'Milestones Assessment score', 0),
  VbTransitionArea(2, 'Barriers Assessment score', 0),
  VbTransitionArea(3, 'Negative behaviors & instructional control', 0),
  VbTransitionArea(4, 'Classroom routines & group skills', 0),
  VbTransitionArea(5, 'Social skills & social play', 0),
  VbTransitionArea(6, 'Independent academic work', 0),
  VbTransitionArea(7, 'Generalization', 0),
  VbTransitionArea(8, 'Range of reinforcers', 1),
  VbTransitionArea(9, 'Rate of acquisition of new skills', 1),
  VbTransitionArea(10, 'Retention of new skills', 1),
  VbTransitionArea(11, 'Learning from the natural environment', 1),
  VbTransitionArea(12, 'Transfer of skills without training', 1),
  VbTransitionArea(13, 'Adaptability to change', 1),
  VbTransitionArea(14, 'Spontaneous behaviors', 2),
  VbTransitionArea(15, 'Independent play & leisure skills', 2),
  VbTransitionArea(16, 'General self-help skills', 2),
  VbTransitionArea(17, 'Toileting skills', 2),
  VbTransitionArea(18, 'Eating skills', 2),
];

const int vbTransitionMaxScore = 90; // 18 areas × 5

// ── EESA ────────────────────────────────────────────────────────────────────

/// One EESA group with its item labels (protocol text or placeholders).
class EesaGroup {
  final int number;
  final String title;
  final String description;
  final List<String> items;
  const EesaGroup(this.number, this.title, this.description, this.items);
}

/// Default EESA layout used when the JSON gives no groups: 100 items.
const List<int> _defaultEesaGroupSizes = [25, 25, 20, 15, 15];
const int eesaGroupCount = 5;

/// A score band: totals in [min, max] (inclusive) earn [score].
class ScoreBand {
  final double min;
  final double max;
  final int score;
  const ScoreBand(this.min, this.max, this.score);
}

class _EchoicMapRow {
  final double minTotal;
  final double echoicScore;
  const _EchoicMapRow(this.minTotal, this.echoicScore);
}

// ── Loader ──────────────────────────────────────────────────────────────────

/// Parsed protocol_content.json. Use [VbMappProtocolContent.load] (cached);
/// [VbMappProtocolContent.current] is the placeholder-only content until the
/// asset has loaded.
class VbMappProtocolContent {
  final Map<String, dynamic> _raw;
  VbMappProtocolContent._(this._raw);

  static VbMappProtocolContent _current = VbMappProtocolContent._(const {});
  static Future<VbMappProtocolContent>? _loading;

  static VbMappProtocolContent get current => _current;

  static Future<VbMappProtocolContent> load() {
    return _loading ??= () async {
      try {
        final text = await rootBundle.loadString(vbmappProtocolAsset);
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          _current =
              VbMappProtocolContent._(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Missing or malformed file: keep placeholders everywhere.
      }
      return _current;
    }();
  }

  Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : const {};
  List<dynamic> _list(Object? v) => v is List ? v : const [];
  double? _num(Object? v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');

  // Barriers
  /// Scoring guidance for [barrier] at [score] (0–4), or a placeholder.
  String barrierCriterion(VbBarrier barrier, int score) {
    final text =
        _map(_map(_map(_raw['barriers'])[barrier.key])['criteria'])['$score']
            ?.toString();
    return isProtocolText(text)
        ? text!
        : 'Barrier ${barrier.number} · Score $score — enter from licensed protocol';
  }

  bool hasBarrierCriteria(VbBarrier barrier) => [
        for (int s = 0; s <= 4; s++)
          _map(_map(_map(_raw['barriers'])[barrier.key])['criteria'])['$s']
              ?.toString()
      ].any(isProtocolText);

  // Transition
  String transitionCriterion(VbTransitionArea area, int score) {
    final text = _map(
            _map(_map(_map(_raw['transition'])['areas'])['${area.number}'])[
                'criteria'])['$score']
        ?.toString();
    return isProtocolText(text)
        ? text!
        : 'Transition area ${area.number} · Score $score — enter from licensed protocol';
  }

  List<ScoreBand>? _bands(String name) {
    final rows = _list(_map(_raw['transition'])[name]);
    final bands = <ScoreBand>[];
    for (final r in rows) {
      final m = _map(r);
      final min = _num(m['min']);
      final max = _num(m['max']);
      final score = _num(m['transition_score'])?.toInt();
      if (min == null || max == null || score == null) return null;
      if (score < 1 || score > 5 || max < min) return null;
      bands.add(ScoreBand(min, max, score));
    }
    return bands.length == 5 ? bands : null;
  }

  /// Bands mapping the Milestones total (0–170) to transition area 1, or
  /// null when the centre has not entered them (manual entry then).
  List<ScoreBand>? get milestonesScoreBands => _bands('milestones_score_bands');

  /// Bands mapping the Barriers total (0–96) to transition area 2, or null.
  List<ScoreBand>? get barriersScoreBands => _bands('barriers_score_bands');

  // EESA
  List<EesaGroup> get eesaGroups {
    final rows = _list(_map(_raw['eesa'])['groups']);
    final groups = <EesaGroup>[];
    for (int g = 1; g <= eesaGroupCount; g++) {
      final m =
          g <= rows.length ? _map(rows[g - 1]) : const <String, dynamic>{};
      final rawItems = _list(m['items']);
      final size =
          rawItems.isNotEmpty ? rawItems.length : _defaultEesaGroupSizes[g - 1];
      final items = [
        for (int i = 1; i <= size; i++)
          () {
            final t = i <= rawItems.length ? rawItems[i - 1]?.toString() : null;
            return isProtocolText(t)
                ? t!
                : 'EESA Group $g · Item $i — enter from licensed protocol';
          }(),
      ];
      final title = m['title']?.toString();
      final description = m['description']?.toString();
      groups.add(EesaGroup(
        g,
        isProtocolText(title) ? 'Group $g · $title' : 'Group $g',
        isProtocolText(description)
            ? description!
            : 'Group $g targets — enter from licensed protocol',
        items,
      ));
    }
    return groups;
  }

  /// Item text of EESA records saved by app v1 (responses keyed by word).
  List<String> eesaLegacyWords(int group) => [
        for (final w in _list(
            _map(_map(_raw['eesa'])['legacy_v1_words'])['group$group']))
          w.toString()
      ];

  List<_EchoicMapRow>? get _echoicMap {
    final rows = _list(_map(_raw['eesa'])['echoic_milestone_mapping']);
    if (rows.isEmpty) return null;
    final result = <_EchoicMapRow>[];
    for (final r in rows) {
      final m = _map(r);
      final min = _num(m['min_total']);
      final score = _num(m['echoic_score']);
      if (min == null || score == null) return null;
      if (score < 0 || score > 10) return null;
      result.add(_EchoicMapRow(min, score));
    }
    result.sort((a, b) => a.minTotal.compareTo(b.minTotal));
    return result;
  }

  /// Whether the EESA → Echoic milestone mapping has been entered.
  bool get hasEchoicMapping => _echoicMap != null;

  /// Echoic milestone score (0–10, steps of ½) for an EESA [total], or null
  /// when the mapping has not been entered (Echoic is then scored by hand).
  double? echoicScoreForEesaTotal(double total) {
    final map = _echoicMap;
    if (map == null) return null;
    double score = 0;
    for (final row in map) {
      if (total >= row.minTotal) score = row.echoicScore;
    }
    return (score * 2).floor() / 2;
  }
}

/// Transition score (1–5) for [total] from [bands], or null when no band
/// covers it.
int? transitionScoreFromBands(List<ScoreBand>? bands, double total) {
  if (bands == null) return null;
  for (final b in bands) {
    if (total >= b.min && total <= b.max) return b.score;
  }
  return null;
}
