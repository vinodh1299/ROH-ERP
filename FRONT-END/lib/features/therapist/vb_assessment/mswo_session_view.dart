import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/db_queries.dart';

/// One item in an MSWO session. [category] uses preference_assessments
/// categories ('Edible', 'Toys/Materials', 'Social', 'Sensory', 'Other').
class MswoItem {
  final String name;
  final String category;
  const MswoItem(this.name, this.category);

  bool get isEdible => category == 'Edible';
}

/// Result of one item across the trials of a session.
class MswoResult {
  final MswoItem item;
  final int selections;
  final int opportunities;
  final double? meanPosition;
  int rank = 0;
  MswoResult(this.item, this.selections, this.opportunities, this.meanPosition);

  double get percentage =>
      opportunities == 0 ? 0 : (selections / opportunities * 1000).round() / 10;
}

/// MSWO scoring (multiple-stimulus without replacement). In each trial an
/// item chosen at position p (1-based) was available for p selections; an
/// item never chosen was available for every selection made in that trial.
/// Selection % = selections / opportunities; ranked by % then by mean
/// selection position (earlier = more preferred). The server recomputes the
/// same values when the session is saved.
List<MswoResult> scoreMswo(List<MswoItem> items, List<List<int>> trials) {
  final done = trials.where((t) => t.isNotEmpty).toList();
  final results = <MswoResult>[];
  for (int i = 0; i < items.length; i++) {
    var selections = 0, opportunities = 0, positionSum = 0;
    for (final trial in done) {
      final pos = trial.indexOf(i);
      if (pos >= 0) {
        selections++;
        opportunities += pos + 1;
        positionSum += pos + 1;
      } else {
        opportunities += trial.length;
      }
    }
    results.add(MswoResult(items[i], selections, opportunities,
        selections == 0 ? null : positionSum / selections));
  }
  final ordered = [...results]..sort((a, b) {
      final byPct = b.percentage.compareTo(a.percentage);
      if (byPct != 0) return byPct;
      return (a.meanPosition ?? 99).compareTo(b.meanPosition ?? 99);
    });
  for (int i = 0; i < ordered.length; i++) {
    final r = ordered[i];
    final prev = i > 0 ? ordered[i - 1] : null;
    r.rank = prev != null &&
            prev.percentage == r.percentage &&
            prev.meanPosition == r.meanPosition
        ? prev.rank
        : i + 1;
  }
  return ordered;
}

/// Label for a ranked item. Only edibles are primary (unconditioned)
/// reinforcers; any other well-chosen item is a "high-preference item".
String mswoPreferenceLabel(MswoResult r, int itemCount) {
  final topThird = (itemCount / 3).ceil();
  if (r.selections == 0) return 'Not selected';
  if (r.rank <= topThird) {
    return r.item.isEdible
        ? 'High-preference primary reinforcer (edible)'
        : 'High-preference item';
  }
  return r.rank <= topThird * 2 ? 'Moderate preference' : 'Low preference';
}

/// MSWO session: pick 4–8 items, record the selection order of up to 5
/// trials, see selection % and rank, save, and review past sessions.
class MswoSessionView extends StatefulWidget {
  final int studentId;

  /// Inventory items to choose from, by category value.
  final Map<String, List<String>> itemsByCategory;

  const MswoSessionView({
    super.key,
    required this.studentId,
    required this.itemsByCategory,
  });

  @override
  State<MswoSessionView> createState() => _MswoSessionViewState();
}

class _MswoSessionViewState extends State<MswoSessionView> {
  static const _minItems = 4;
  static const _maxItems = 8;
  static const _maxTrials = 5;

  final List<MswoItem> _items = [];
  List<List<int>> _trials = [[]];
  int _activeTrial = 0;
  bool _saving = false;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void didUpdateWidget(covariant MswoSessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) {
      _resetSession();
      _loadSessions();
    }
  }

  Future<void> _loadSessions() async {
    final rows =
        await PreferenceSessionQueries.fetchForStudent('${widget.studentId}');
    if (mounted) setState(() => _sessions = rows);
  }

  void _resetSession() {
    _items.clear();
    _trials = [[]];
    _activeTrial = 0;
  }

  bool get _hasSelections => _trials.any((t) => t.isNotEmpty);

  void _toggleItem(MswoItem item) {
    if (_hasSelections) {
      _showMessage('Clear the trials before changing the items.');
      return;
    }
    setState(() {
      final i = _items.indexWhere((e) => e.name == item.name);
      if (i >= 0) {
        _items.removeAt(i);
      } else if (_items.length < _maxItems) {
        _items.add(item);
      } else {
        _showMessage('An MSWO session uses at most $_maxItems items.');
      }
    });
  }

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? Colors.red : null,
    ));
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_items.length < _minItems) {
      _showMessage('Choose at least $_minItems items.', error: true);
      return;
    }
    if (!_hasSelections) {
      _showMessage('Record at least one selection.', error: true);
      return;
    }
    final results = scoreMswo(_items, _trials);
    setState(() => _saving = true);
    final error = await PreferenceSessionQueries.trySave({
      'student_id': widget.studentId,
      'session_date': DateTime.now().toIso8601String().substring(0, 10),
      'method': 'MSWO',
      'items': [
        for (final i in _items) {'name': i.name, 'category': i.category},
      ],
      'trials': _trials.where((t) => t.isNotEmpty).toList(),
      'results': [
        for (final r in results)
          {
            'name': r.item.name,
            'category': r.item.category,
            'selections': r.selections,
            'opportunities': r.opportunities,
            'percentage': r.percentage,
            'rank': r.rank,
          },
      ],
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      _showMessage('Could not save the MSWO session: $error', error: true);
      return;
    }
    _showMessage('MSWO session saved.');
    setState(_resetSession);
    await _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          '1. Choose $_minItems–$_maxItems items',
          'Items come from the preference inventory (add new ones there). '
              'Selected: ${_items.length}.',
          _buildItemPicker(),
        ),
        const SizedBox(height: 16),
        _card(
          '2. Record the selection order',
          'Present all remaining items in a row; tap the item the child '
              'selects. The selected item is not replaced. Up to $_maxTrials '
              'trials.',
          _buildTrials(),
        ),
        const SizedBox(height: 16),
        _card(
          '3. Results',
          'Selection % = times selected ÷ times available. Only edibles are '
              'called primary reinforcers; other top items are high-preference '
              'items.',
          _buildResults(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _saving ? null : () => setState(_resetSession),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Reset',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_saving ? 'Saving…' : 'Save session',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _card('Saved MSWO sessions', null, _buildHistory()),
      ],
    );
  }

  Widget _card(String title, String? subtitle, Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildItemPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in widget.itemsByCategory.entries)
          if (entry.value.isNotEmpty) ...[
            Text(entry.key,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in entry.value)
                  FilterChip(
                    label: Text(name, style: const TextStyle(fontSize: 12)),
                    selected: _items.any((i) => i.name == name),
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    checkmarkColor: AppColors.primary,
                    onSelected: (_) => _toggleItem(MswoItem(name, entry.key)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildTrials() {
    if (_items.length < _minItems) {
      return const Text('Choose at least $_minItems items first.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary));
    }
    final trial = _trials[_activeTrial];
    final remaining = [
      for (int i = 0; i < _items.length; i++)
        if (!trial.contains(i)) i,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (int t = 0; t < _trials.length; t++)
              ChoiceChip(
                label: Text('Trial ${t + 1} (${_trials[t].length})'),
                selected: t == _activeTrial,
                selectedColor: AppColors.primary.withValues(alpha: 0.18),
                onSelected: (_) => setState(() => _activeTrial = t),
              ),
            if (_trials.length < _maxTrials)
              TextButton.icon(
                onPressed: () => setState(() {
                  _trials.add([]);
                  _activeTrial = _trials.length - 1;
                }),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add trial'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Selection order',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        if (trial.isEmpty)
          const Text('No selections yet.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int p = 0; p < trial.length; p++)
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text('${p + 1}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                  label: Text(_items[trial[p]].name,
                      style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Text(
          remaining.isEmpty
              ? 'All items selected in this trial.'
              : 'Still on the table: tap the one selected next',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final i in remaining)
              ActionChip(
                label:
                    Text(_items[i].name, style: const TextStyle(fontSize: 12)),
                onPressed: () => setState(() => trial.add(i)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: trial.isEmpty
                  ? null
                  : () => setState(() => trial.removeLast()),
              child: const Text('Undo last'),
            ),
            TextButton(
              onPressed:
                  trial.isEmpty ? null : () => setState(() => trial.clear()),
              child: const Text('Clear trial'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (!_hasSelections) {
      return const Text('Results appear once selections are recorded.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary));
    }
    final results = scoreMswo(_items, _trials);
    return _resultsTable([
      for (final r in results)
        [
          '${r.rank}',
          r.item.name,
          r.item.category,
          '${r.selections}/${r.opportunities}',
          '${r.percentage.toStringAsFixed(r.percentage % 1 == 0 ? 0 : 1)}%',
          mswoPreferenceLabel(r, _items.length),
        ],
    ]);
  }

  Widget _resultsTable(List<List<String>> rows) {
    const header = ['Rank', 'Item', 'Category', 'Selected', '%', 'Preference'];
    Widget cell(String text, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Text(text,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: bold ? AppColors.primary : AppColors.textPrimary)),
        );
    return ScrollableMinWidth(
      minWidth: 640,
      child: Table(
        border: TableBorder.all(color: AppColors.divider),
        columnWidths: const {
          0: FixedColumnWidth(52),
          3: FixedColumnWidth(76),
          4: FixedColumnWidth(64),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFEDE9FE)),
            children: [for (final h in header) cell(h, bold: true)],
          ),
          for (final row in rows)
            TableRow(
              decoration: const BoxDecoration(color: Colors.white),
              children: [for (final c in row) cell(c)],
            ),
        ],
      ),
    );
  }

  List<dynamic> _jsonList(Object? raw) {
    if (raw is List) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is List) return d;
      } catch (_) {}
    }
    return const [];
  }

  Widget _buildHistory() {
    if (_sessions.isEmpty) {
      return const Text('No MSWO sessions saved yet.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in _sessions) ...[
          Builder(builder: (context) {
            final results = _jsonList(s['results'])
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList()
              ..sort((a, b) => (int.tryParse('${a['rank']}') ?? 99)
                  .compareTo(int.tryParse('${b['rank']}') ?? 99));
            final trials = _jsonList(s['trials']).length;
            final date = (s['session_date'] ?? '').toString().split('T').first;
            final by = (s['therapist_name'] ?? '').toString();
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$date · MSWO · ${results.length} items · $trials '
                    'trial${trials == 1 ? '' : 's'}'
                    '${by.isEmpty ? '' : ' · $by'}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      for (final r in results)
                        '${r['rank']}. ${r['name']} (${r['percentage']}%)'
                    ].join('  ·  '),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
