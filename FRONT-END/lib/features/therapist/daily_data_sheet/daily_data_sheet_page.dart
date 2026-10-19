import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/db_queries.dart';
import '../../../core/services/progress_metrics.dart';
import '../../../core/services/report_pdf.dart';
import '../widgets/student_card_grid.dart';
import 'widgets/incident_stopwatch.dart';
import 'widgets/daily_data_chart_painters.dart';

class DailyDataSheetPage extends StatefulWidget {
  const DailyDataSheetPage({super.key});

  /// Set by other pages (e.g. the dashboard's or timetable's Data Sheet
  /// button) to open a student's sheet directly instead of the student grid.
  static final ValueNotifier<({int id, String name})?> openStudent =
      ValueNotifier(null);

  @override
  State<DailyDataSheetPage> createState() => _DailyDataSheetPageState();
}

class _DailyDataSheetPageState extends State<DailyDataSheetPage> {
  String? _selectedStudent;
  int? _selectedStudentId;
  int _activeTab =
      0; // 0: Manding, 1: Manding Graph, 2: Daily Data Sheet, 3: Skill Tracking Sheet, 4: Acquisition Graph, 5: ABC Data, 6: BRP, 7: PB Graph, 8: IEP Report

  // Manding Filters & State
  late String _mandingDate;
  late String _mandingTimeIn;
  late String _mandingTimeOut;

  // Manding Grid Counters
  final List<String> _mandingColumns = [
    'FP',
    'PP',
    'FM/FV',
    'PM/PV',
    'F3',
    'F5',
    'F6',
    'F6',
    'Error',
    'Vocal'
  ];
  // Manding rows of every date; _mandingRows holds the selected date's rows
  // (same map objects, so edits show in both).
  final List<Map<String, dynamic>> _allMandingRows = [];
  final List<Map<String, dynamic>> _mandingRows = [];

  // Every daily_data_sheets row of the selected student; the graphs, the
  // skill tracking sheet and the IEP summary are computed from these.
  final List<Map<String, dynamic>> _records = [];

  // Daily Data Sheet DTT: session date shown (MM/dd/yyyy)
  late String _ddsDate;
  bool _mandingGoalsExpanded = true;
  bool _listenerGoalsExpanded = true;
  bool _tactingGoalsExpanded = false;
  bool _vpGoalsExpanded = false;
  bool _otherGoalsExpanded = true;
  final List<Map<String, dynamic>> _dttTargets = [];

  // Manding Graph Filters (MM/dd/yyyy, inclusive)
  late String _mgFromDate;
  late String _mgToDate;

  // Skill Tracking Sheet
  String _skillDomain = 'Manding';

  // Acquisition Graph Filters (MM/dd/yyyy, inclusive)
  late String _acqFromDate;
  late String _acqToDate;
  String _acqDomain = 'Manding';

  // ABC Data Sheet: saved incidents (with 'id') plus unsaved new ones
  final List<Map<String, dynamic>> _abcIncidents = [];

  // BRP (Behaviour Reduction Plan) form
  final TextEditingController _brpFormController = TextEditingController();
  final TextEditingController _brpFunctionController = TextEditingController();
  final TextEditingController _brpMeasurementController =
      TextEditingController();

  bool _savingManding = false;
  bool _savingBrp = false;
  int? _brpId; // saved BRP row that the BRP form edits
  // BRP text as last loaded/saved, to spot unsaved edits on Cancel.
  ({String form, String function, String measurement}) _brpSaved =
      (form: '', function: '', measurement: '');

  // PB Graph State
  static const List<String> _pbGraphTypes = [
    'Problem Behaviour Duration',
    'Behaviour Count',
  ];
  String _pbGraphType = 'Problem Behaviour Duration';

  final List<String> _tabs = [
    'Manding',
    'Manding Graph',
    'Daily Data Sheet',
    'Skill Tracking Sheet',
    'Acquisition Graph',
    'ABC Data',
    'BRP',
    'PB Graph',
    'IEP Report',
  ];

  // Keys for each tab item so the selected tab can be scrolled into view on
  // narrow screens where the tab bar scrolls sideways.
  late final List<GlobalKey> _tabKeys =
      List.generate(_tabs.length, (_) => GlobalKey());

  final ScrollController _tabScroll = ScrollController();

  /// Selects a tab and scrolls only the horizontal tab strip (not the page)
  /// so the selected tab sits in view.
  void _selectTab(int index) {
    setState(() => _activeTab = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _tabKeys[index].currentContext?.findRenderObject();
      if (box == null || !_tabScroll.hasClients) return;
      final pos = _tabScroll.position;
      final target = RenderAbstractViewport.of(box)
          .getOffsetToReveal(box, 0.5)
          .offset
          .clamp(pos.minScrollExtent, pos.maxScrollExtent);
      _tabScroll.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    DailyDataSheetPage.openStudent.removeListener(_onOpenRequest);
    _tabScroll.dispose();
    _brpFormController.dispose();
    _brpFunctionController.dispose();
    _brpMeasurementController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final dFormat = DateFormat('MM/dd/yyyy').format(now);
    final tFormat = DateFormat('hh:mm a').format(now);
    final tOutFormat =
        DateFormat('hh:mm a').format(now.add(const Duration(hours: 1)));

    _mandingDate = dFormat;
    _mandingTimeIn = tFormat;
    _mandingTimeOut = tOutFormat;

    _ddsDate = dFormat;

    _mgFromDate = dFormat;
    _mgToDate = dFormat;

    _acqFromDate = dFormat;
    _acqToDate = dFormat;

    DailyDataSheetPage.openStudent.addListener(_onOpenRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onOpenRequest());
  }

  void _onOpenRequest() {
    final request = DailyDataSheetPage.openStudent.value;
    if (request == null || !mounted) return;
    DailyDataSheetPage.openStudent.value = null;
    _onStudentSelected(request.name, request.id);
  }

  int _resolveStudentId(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('alex')) return 1;
    if (lower.contains('aarav')) return 2;
    if (lower.contains('emma')) return 3;
    if (lower.contains('matt')) return 4;
    if (lower.contains('rahul')) return 5;
    if (lower.contains('sophia')) return 6;
    return 1;
  }

  void _onStudentSelected(String studentName, [int? id]) {
    setState(() {
      _selectedStudent = studentName;
      _selectedStudentId = id ?? _resolveStudentId(studentName);
      _activeTab = 0;
      _brpFormController.clear();
      _brpFunctionController.clear();
      _brpMeasurementController.clear();
      _records.clear();
      _abcIncidents.clear();
      _loadStudentData(resetFilters: true);
    });
  }

  /// Loads the student's rows. [resetFilters] (on student change) points
  /// the date filters at the span of the student's data.
  Future<void> _loadStudentData({bool resetFilters = false}) async {
    if (_selectedStudentId == null) return;
    try {
      final records =
          await DailyDataQueries.fetchForStudent(_selectedStudentId.toString());
      if (mounted) {
        setState(() {
          _records
            ..clear()
            ..addAll(records);
          _mandingRows.clear();
          _allMandingRows.clear();
          _brpId = null;
          _brpSaved = (form: '', function: '', measurement: '');
          _dttTargets.clear();
          // Keep incidents added here but not saved yet.
          final unsaved = _abcIncidents
              .where((i) => i['id'] == null && i['saved'] != true)
              .toList();
          _abcIncidents
            ..clear()
            ..addAll(unsaved);

          for (final r in records) {
            final domain = (r['domain'] ?? '').toString();
            final domainLower = domain.toLowerCase();
            final sessionDateRaw = (r['session_date'] ?? '').toString();
            final completed =
                int.tryParse(r['trials_completed']?.toString() ?? '0') ?? 0;
            final successful =
                int.tryParse(r['trials_successful']?.toString() ?? '0') ?? 0;
            final targetSkill =
                (r['target_skill'] ?? 'Target Skill').toString();
            final prompt = (r['prompt_level'] ?? 'Independent').toString();
            final notesJson = _notesJson(r);

            // 0. BRP — not trial data; the latest one fills the BRP form.
            if (domainLower == 'brp') {
              _brpId = int.tryParse(r['id']?.toString() ?? '');
              _brpFormController.text = (notesJson['form'] ?? '').toString();
              _brpFunctionController.text =
                  (notesJson['function'] ?? '').toString();
              _brpMeasurementController.text =
                  (notesJson['measurement'] ?? '').toString();
              _brpSaved = (
                form: _brpFormController.text,
                function: _brpFunctionController.text,
                measurement: _brpMeasurementController.text,
              );
              continue;
            }

            // 1. Manding Sheet (the Manding Graph is computed from _records)
            if (domainLower == 'manding') {
              // Sheets saved from this tab carry the exact per-column counts.
              final savedCounts = notesJson['counts'];
              final counts = savedCounts is List && savedCounts.length == 10
                  ? savedCounts
                      .map((c) => int.tryParse(c.toString()) ?? 0)
                      .toList()
                  : List.generate(10, (idx) {
                      if (idx < successful) return 1;
                      if (idx < completed) return 2;
                      return 0;
                    });
              _allMandingRows.add({
                'id': r['id'],
                'date': sessionDateRaw.split('T')[0],
                'label': targetSkill,
                'counts': counts,
                'savedCounts': List<int>.from(counts),
                'time_in': notesJson['time_in']?.toString(),
                'time_out': notesJson['time_out']?.toString(),
              });
            }

            // 2. DTT targets (all instructional skill domains)
            if (isSkillRow(r)) {
              final pct =
                  double.tryParse(r['percentage_success']?.toString() ?? '') ??
                      (completed == 0 ? 0 : successful * 100 / completed);
              _dttTargets.add({
                'date': sessionDateRaw.split('T')[0],
                'domain': domain,
                'target': targetSkill,
                'prompt': prompt,
                'trials': completed,
                'success': successful,
                'pct': pct.toStringAsFixed(0),
              });
              continue;
            }

            // 3. ABC incidents / problem behaviour rows
            if (_isBehaviourRow(r)) {
              _abcIncidents.add(_incidentFromRow(r));
            }
          }
          _abcIncidents.sort((a, b) => _incidentSortKey(b)
              .compareTo(_incidentSortKey(a))); // newest first
          if (resetFilters) _resetFilters();
          _applyMandingDate();
        });
      }
    } catch (_) {}
  }

  // ── Data helpers ──────────────────────────────────────────────────────────

  static final DateFormat _filterFmt = DateFormat('MM/dd/yyyy');
  static final DateFormat _labelFmt = DateFormat('dd-MMM');

  Map<String, dynamic> _notesJson(Map<String, dynamic> r) {
    try {
      final decoded = jsonDecode((r['notes'] ?? '').toString());
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  int _intOf(Object? v) => int.tryParse(v?.toString() ?? '') ?? 0;

  /// ABC incidents and problem-behaviour counts (not skills, not the BRP).
  bool _isBehaviourRow(Map<String, dynamic> r) {
    final d = (r['domain'] ?? '').toString().toLowerCase();
    return d != 'brp' && !isSkillRow(r);
  }

  DateTime? _parseFilterDate(String mmddyyyy) {
    try {
      return _filterFmt.parseStrict(mmddyyyy);
    } catch (_) {
      return null;
    }
  }

  /// Whether [d] lies within the inclusive MM/dd/yyyy range [from]–[to].
  bool _inRange(DateTime? d, String from, String to) {
    if (d == null) return false;
    final f = _parseFilterDate(from);
    final t = _parseFilterDate(to);
    return (f == null || !d.isBefore(f)) && (t == null || !d.isAfter(t));
  }

  /// Earliest session date among [rows] (or today) through the later of
  /// today and the latest session date, as MM/dd/yyyy.
  (String, String) _spanOf(Iterable<Map<String, dynamic>> rows) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime first = today;
    DateTime last = today;
    for (final r in rows) {
      final d = rowDate(r);
      if (d == null) continue;
      if (d.isBefore(first)) first = d;
      if (d.isAfter(last)) last = d;
    }
    return (_filterFmt.format(first), _filterFmt.format(last));
  }

  void _resetFilters() {
    final manding = _records.where(
        (r) => (r['domain'] ?? '').toString().toLowerCase() == 'manding');
    final (mgFrom, mgTo) = _spanOf(manding);
    _mgFromDate = mgFrom;
    _mgToDate = mgTo;
    final (acqFrom, acqTo) = _spanOf(_records.where(isSkillRow));
    _acqFromDate = acqFrom;
    _acqToDate = acqTo;

    final domains = _skillDomains();
    _skillDomain = _pickDomain(_skillDomain, domains);
    _acqDomain = _pickDomain(_acqDomain, domains);

    // DTT sheet opens on the latest session with skill data.
    DateTime? latest;
    for (final r in _records.where(isSkillRow)) {
      final d = rowDate(r);
      if (d != null && (latest == null || d.isAfter(latest))) latest = d;
    }
    _ddsDate = _filterFmt.format(latest ?? DateTime.now());
  }

  /// Skill domains present in the student's rows, first spelling wins.
  List<String> _skillDomains() {
    final seen = <String, String>{};
    for (final r in _records.where(isSkillRow)) {
      final d = (r['domain'] ?? '').toString().trim();
      if (d.isEmpty) continue;
      seen.putIfAbsent(d.toLowerCase(), () => d);
    }
    final list = seen.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// [current] if it is one of [domains] (ignoring case), else the first.
  String _pickDomain(String current, List<String> domains) {
    for (final d in domains) {
      if (d.toLowerCase() == current.toLowerCase()) return d;
    }
    return domains.isEmpty ? current : domains.first;
  }

  bool _sameDomain(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  /// Opens a date picker for an MM/dd/yyyy filter value.
  Future<void> _pickFilterDate(
      String current, void Function(String picked) apply) async {
    final initial = _parseFilterDate(current) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => apply(_filterFmt.format(picked)));
  }

  /// Applies a picked From/To date, keeping From on or before To.
  void _setRange(String picked, bool isFrom, void Function(String) setFrom,
      void Function(String) setTo, String other) {
    final p = _parseFilterDate(picked)!;
    final o = _parseFilterDate(other);
    if (isFrom) {
      setFrom(picked);
      if (o != null && p.isAfter(o)) setTo(picked);
    } else {
      setTo(picked);
      if (o != null && p.isBefore(o)) setFrom(picked);
    }
  }

  /// One point per manding session date in the selected range:
  /// prompted = completed − successful, unprompted = successful.
  List<Map<String, dynamic>> _mandingGraphPoints() {
    final byDate = <DateTime, List<int>>{};
    for (final r in _records) {
      if ((r['domain'] ?? '').toString().toLowerCase() != 'manding') continue;
      final d = rowDate(r);
      if (!_inRange(d, _mgFromDate, _mgToDate)) continue;
      final completed = _intOf(r['trials_completed']);
      final successful = _intOf(r['trials_successful']);
      final sums = byDate.putIfAbsent(d!, () => [0, 0]);
      sums[0] += (completed - successful).clamp(0, 1 << 30);
      sums[1] += successful;
    }
    final dates = byDate.keys.toList()..sort();
    return [
      for (final d in dates)
        {
          'date': _labelFmt.format(d),
          'prompted': byDate[d]![0],
          'unprompted': byDate[d]![1],
        },
    ];
  }

  /// Cumulative count of [domain] targets mastered, one point per mastery
  /// date within the range. The count includes targets mastered before the
  /// range starts, so the line is the student's running total.
  List<Map<String, dynamic>> _acquisitionPoints() {
    final mastered = targetProgress(_records)
        .where((t) => t.masteredOn != null && _sameDomain(t.domain, _acqDomain))
        .map((t) => t.masteredOn!)
        .toList()
      ..sort();
    final points = <Map<String, dynamic>>[];
    DateTime? lastDate;
    for (int i = 0; i < mastered.length; i++) {
      final d = mastered[i];
      if (!_inRange(d, _acqFromDate, _acqToDate)) continue;
      if (d == lastDate) {
        points.last['count'] = i + 1;
        points.last['new'] = (points.last['new'] as int) + 1;
      } else {
        points.add({'date': _labelFmt.format(d), 'count': i + 1, 'new': 1});
        lastDate = d;
      }
    }
    return points;
  }

  // ── ABC incidents ─────────────────────────────────────────────────────────

  static const List<String> _antecedentOptions = [
    'Work Demand',
    'Denied Access',
    'Transition',
    'Attention',
  ];
  static const List<String> _behaviourOptions = [
    'Hit',
    'Scream',
    'Elopement',
    'Bite',
    'Throwing',
  ];
  static const List<String> _consequenceOptions = [
    'Ignored problem behaviour',
    'Redirected to task',
    'Given break',
    'Response block',
  ];

  /// Incident map for a saved ABC / behaviour row. Rows saved by this page
  /// keep their details as JSON in notes; older rows may use plain text.
  Map<String, dynamic> _incidentFromRow(Map<String, dynamic> r) {
    final notes = (r['notes'] ?? '').toString();
    final j = _notesJson(r);
    final d = rowDate(r);
    String fromText(String key) {
      if (!notes.contains('$key:')) return '';
      return notes.split('$key:')[1].split('.')[0].trim();
    }

    int duration = _intOf(j['duration']);
    if (j['duration'] == null) {
      final m = RegExp(r'Duration\s+(\d+)\s+min', caseSensitive: false)
          .firstMatch(notes);
      duration = int.tryParse(m?.group(1) ?? '') ?? 0;
    }
    final completed = _intOf(r['trials_completed']);
    return {
      'id': r['id'],
      'domain': (r['domain'] ?? 'ABC').toString(),
      'date':
          d == null ? _filterFmt.format(DateTime.now()) : _filterFmt.format(d),
      'time': (j['time'] ?? '').toString(),
      'setting': (j['setting'] ?? '').toString(),
      'antecedent': (j['antecedent'] ?? fromText('Antecedent')).toString(),
      'antecedentNote': (j['antecedent_note'] ?? '').toString(),
      'behavior': (r['target_skill'] ?? '').toString(),
      'count': completed > 0 ? completed : 1,
      'timeMins': duration,
      'consequence': (j['consequence'] ?? fromText('Consequence')).toString(),
      'consequenceNote': (j['consequence_note'] ?? '').toString(),
      'isExpanded': false,
    };
  }

  String _incidentSortKey(Map<String, dynamic> i) {
    final d = _parseFilterDate(i['date'] ?? '');
    final day = d == null ? '' : DateFormat('yyyy-MM-dd').format(d);
    DateTime? t;
    try {
      t = DateFormat('hh:mm a').parseStrict((i['time'] ?? '').toString());
    } catch (_) {}
    return '$day ${t == null ? '' : DateFormat('HH:mm').format(t)}';
  }

  String _incidentTitle(Map<String, dynamic> i) {
    final d = _parseFilterDate(i['date'] ?? '');
    final parts = [
      if (d != null) DateFormat('dd-MMM-yyyy').format(d),
      if ((i['time'] ?? '').toString().isNotEmpty) i['time'],
      if ((i['behavior'] ?? '').toString().isNotEmpty) i['behavior'],
    ];
    final title = parts.isEmpty ? 'New incident' : parts.join('  ');
    return i['id'] == null ? '$title (not saved)' : title;
  }

  Future<void> _saveIncident(Map<String, dynamic> incident) async {
    final studentId = _selectedStudentId;
    if (studentId == null || incident['saving'] == true) return;
    final behaviour = (incident['behavior'] ?? '').toString().trim();
    if (behaviour.isEmpty) {
      _showSnack('Choose the behaviour before saving.', error: true);
      return;
    }
    setState(() => incident['saving'] = true);
    final ok = await DailyDataQueries.saveSheet(
      studentId: studentId,
      sessionDate: _apiDate(incident['date'] ?? ''),
      rows: [
        {
          if (incident['id'] != null) 'id': incident['id'],
          'domain': incident['domain'] ?? 'ABC',
          'target_skill': behaviour,
          'trials_completed': incident['count'] ?? 1,
          'trials_successful': 0,
          'notes': jsonEncode({
            'antecedent': incident['antecedent'] ?? '',
            'antecedent_note': incident['antecedentNote'] ?? '',
            'consequence': incident['consequence'] ?? '',
            'consequence_note': incident['consequenceNote'] ?? '',
            'setting': incident['setting'] ?? '',
            'time': incident['time'] ?? '',
            'duration': incident['timeMins'] ?? 0,
          }),
        },
      ],
    );
    if (!mounted) return;
    setState(() => incident['saving'] = false);
    if (!ok) {
      _showSnack('Could not save the incident. Please try again.', error: true);
      return;
    }
    incident['saved'] = true; // the reload brings it back with its id
    _showSnack('Incident saved successfully.');
    await _loadStudentData();
  }

  // ── PB graph data ─────────────────────────────────────────────────────────

  /// Saved behaviour rows by session date (oldest first).
  Map<DateTime, List<Map<String, dynamic>>> _behaviourRowsByDate() {
    final byDate = <DateTime, List<Map<String, dynamic>>>{};
    for (final r in _records.where(_isBehaviourRow)) {
      final d = rowDate(r);
      if (d == null) continue;
      (byDate[d] ??= []).add(_incidentFromRow(r));
    }
    return Map.fromEntries(
        byDate.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  /// Total problem-behaviour minutes per date.
  List<Map<String, dynamic>> _pbDurationPoints() => [
        for (final e in _behaviourRowsByDate().entries)
          {
            'date': _labelFmt.format(e.key),
            'duration':
                e.value.fold<int>(0, (a, i) => a + (i['timeMins'] as int)),
          },
      ];

  /// Behaviour names (first spelling wins) and per-date counts of each.
  (List<String>, List<Map<String, dynamic>>) _pbCountPoints() {
    final names = <String, String>{};
    final points = <Map<String, dynamic>>[];
    for (final e in _behaviourRowsByDate().entries) {
      final point = <String, dynamic>{'date': _labelFmt.format(e.key)};
      for (final i in e.value) {
        final raw = (i['behavior'] ?? '').toString().trim();
        final name = names.putIfAbsent(
            raw.toLowerCase(), () => raw.isEmpty ? 'Unspecified' : raw);
        point[name] = (point[name] as int? ?? 0) + (i['count'] as int);
      }
      points.add(point);
    }
    return (names.values.toList(), points);
  }

  /// Shows the manding rows recorded on the selected date.
  void _applyMandingDate() {
    final date = _apiDate(_mandingDate);
    _mandingRows
      ..clear()
      ..addAll(_allMandingRows.where((r) => r['date'] == date));
    // Show the session times saved with that date's sheet, if any.
    for (final r in _mandingRows) {
      final tIn = r['time_in'] as String?;
      final tOut = r['time_out'] as String?;
      if (tIn != null && tIn.isNotEmpty) _mandingTimeIn = tIn;
      if (tOut != null && tOut.isNotEmpty) _mandingTimeOut = tOut;
      if (tIn != null || tOut != null) break;
    }
  }

  /// Picks the manding session's Time In ([timeIn]) or Time Out.
  Future<void> _pickMandingTime({required bool timeIn}) async {
    final current = timeIn ? _mandingTimeIn : _mandingTimeOut;
    TimeOfDay initial = TimeOfDay.now();
    try {
      initial =
          TimeOfDay.fromDateTime(DateFormat('hh:mm a').parseStrict(current));
    } catch (_) {}
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    final formatted = DateFormat('hh:mm a')
        .format(DateTime(2000, 1, 1, picked.hour, picked.minute));
    setState(() {
      if (timeIn) {
        _mandingTimeIn = formatted;
      } else {
        _mandingTimeOut = formatted;
      }
    });
  }

  /// Whether a manding row is new with trials, or saved with changed counts.
  bool _mandingRowChanged(Map<String, dynamic> r) {
    final counts = r['counts'] as List<int>;
    if (r['id'] == null) return counts.any((c) => c > 0);
    final saved = r['savedCounts'] as List<int>;
    return List.generate(counts.length, (i) => counts[i] != saved[i])
        .any((d) => d);
  }

  bool get _brpHasUnsavedEdits =>
      _brpFormController.text != _brpSaved.form ||
      _brpFunctionController.text != _brpSaved.function ||
      _brpMeasurementController.text != _brpSaved.measurement;

  /// Cancel on a sheet: asks first when [hasUnsaved], then discards the
  /// edits and goes back to the student list.
  Future<void> _cancelSheet({required bool hasUnsaved}) async {
    if (hasUnsaved) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
              'You have unsaved changes on this sheet. They will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() {
      // Drop unsaved manding rows and restore saved counts and BRP text.
      _allMandingRows.removeWhere((r) => r['id'] == null);
      for (final r in _allMandingRows) {
        r['counts'] = List<int>.from(r['savedCounts'] as List<int>);
      }
      _applyMandingDate();
      _brpFormController.text = _brpSaved.form;
      _brpFunctionController.text = _brpSaved.function;
      _brpMeasurementController.text = _brpSaved.measurement;
      _selectedStudent = null;
    });
  }

  Future<void> _printBrp() async {
    String orDash(String v) => v.trim().isEmpty ? '—' : v.trim();
    await ReportPdf.share(
      title: 'Behaviour Reduction Plan (BRP)',
      subtitle: _selectedStudent,
      fileName: 'BRP_${(_selectedStudent ?? 'student').replaceAll(' ', '_')}',
      sections: [
        ReportSection('Form of the problem behaviours',
            text: orDash(_brpFormController.text)),
        ReportSection('Function of problem behaviours (maintaining variables)',
            text: orDash(_brpFunctionController.text)),
        ReportSection('Measurement of problem behaviours',
            text: orDash(_brpMeasurementController.text)),
      ],
    );
  }

  Future<void> _pickMandingDate() async {
    DateTime initial;
    try {
      initial = DateFormat('MM/dd/yyyy').parseStrict(_mandingDate);
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _mandingDate = DateFormat('MM/dd/yyyy').format(picked);
      _applyMandingDate();
    });
  }

  void _addNewIncident() {
    final now = DateTime.now();
    setState(() {
      _abcIncidents.insert(0, {
        'id': null,
        'domain': 'ABC',
        'date': _filterFmt.format(now),
        'time': DateFormat('hh:mm a').format(now),
        'setting': '',
        'antecedent': '',
        'antecedentNote': '',
        'behavior': '',
        'count': 1,
        'timeMins': 0,
        'consequence': '',
        'consequenceNote': '',
        'isExpanded': true,
      });
    });
  }

  /// Converts a 'MM/dd/yyyy' filter date to the API's 'yyyy-MM-dd'.
  String _apiDate(String mmddyyyy) {
    try {
      return DateFormat('yyyy-MM-dd')
          .format(DateFormat('MM/dd/yyyy').parseStrict(mmddyyyy));
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), backgroundColor: error ? Colors.red : null),
    );
  }

  /// Most intrusive prompt used in a manding row (columns: FP, PP, FM/FV,
  /// PM/PV, F3, F5, F6, F6, Error, Vocal).
  String _mandPromptLevel(List<int> counts) {
    if (counts[0] + counts[1] > 0) return 'Physical';
    if (counts[2] + counts[3] > 0) return 'Verbal';
    if (counts.sublist(4, 8).any((c) => c > 0)) return 'Gestural';
    return 'Independent';
  }

  /// Saves the selected date's new rows and the saved rows whose counts were
  /// changed (those update their existing database row).
  Future<void> _saveMandingSheet() async {
    final studentId = _selectedStudentId;
    if (studentId == null || _savingManding) return;
    final newRows = _mandingRows.where(_mandingRowChanged).toList();
    if (newRows.isEmpty) {
      _showSnack('No new or changed trials to save.', error: true);
      return;
    }
    setState(() => _savingManding = true);
    final ok = await DailyDataQueries.saveSheet(
      studentId: studentId,
      sessionDate: _apiDate(_mandingDate),
      rows: [
        for (final r in newRows)
          () {
            final counts = r['counts'] as List<int>;
            // Same split as the summary bar: the first 8 columns are prompted.
            final unprompted = counts.sublist(8).fold<int>(0, (a, b) => a + b);
            return <String, dynamic>{
              if (r['id'] != null) 'id': r['id'],
              'domain': 'Manding',
              'target_skill': r['label'] ?? 'Mand',
              'prompt_level': _mandPromptLevel(counts),
              'trials_completed': counts.fold<int>(0, (a, b) => a + b),
              'trials_successful': unprompted,
              'notes': jsonEncode({
                'counts': counts,
                'time_in': _mandingTimeIn,
                'time_out': _mandingTimeOut,
              }),
            };
          }(),
      ],
    );
    if (!mounted) return;
    setState(() => _savingManding = false);
    if (!ok) {
      _showSnack('Could not save the session data. Please try again.',
          error: true);
      return;
    }
    _showSnack('Session data saved successfully.');
    await _loadStudentData();
  }

  Future<void> _saveBrp() async {
    final studentId = _selectedStudentId;
    if (studentId == null || _savingBrp) return;
    final form = _brpFormController.text.trim();
    final function = _brpFunctionController.text.trim();
    final measurement = _brpMeasurementController.text.trim();
    if (form.isEmpty && function.isEmpty && measurement.isEmpty) {
      _showSnack('Fill in the plan before saving.', error: true);
      return;
    }
    setState(() => _savingBrp = true);
    final ok = await DailyDataQueries.saveSheet(
      studentId: studentId,
      sessionDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      rows: [
        {
          if (_brpId != null) 'id': _brpId, // edit the saved plan
          'domain': 'BRP',
          'target_skill': form.isEmpty ? 'Behaviour Reduction Plan' : form,
          'trials_completed': 0,
          'trials_successful': 0,
          'notes': jsonEncode({
            'form': form,
            'function': function,
            'measurement': measurement,
          }),
        },
      ],
    );
    if (!mounted) return;
    setState(() => _savingBrp = false);
    if (!ok) {
      _showSnack('Could not save the BRP. Please try again.', error: true);
      return;
    }
    _showSnack('Behaviour Reduction Plan saved successfully.');
    await _loadStudentData();
  }

  void _addNewMandRow() {
    setState(() {
      final row = <String, dynamic>{
        'date': _apiDate(_mandingDate),
        'label': 'Item ${_mandingRows.length + 1}',
        'counts': List.generate(10, (_) => 0),
      };
      _allMandingRows.add(row);
      _mandingRows.add(row);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStudent == null) {
      return StudentCardGrid(
        title: 'Students Daily Data Analysis',
        buttonLabel: 'View',
        onStudentAction: (student, studentId) =>
            _onStudentSelected(student, studentId),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Back Button & Student Title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => setState(() => _selectedStudent = null),
                tooltip: 'Back to students',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 18),
                    children: [
                      TextSpan(
                        text: '$_selectedStudent ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      TextSpan(
                        text: _activeTab == 5
                            ? 'ABC Data Sheet'
                            : (_activeTab == 6
                                ? 'BRP'
                                : (_activeTab == 7
                                    ? 'PBH Graph'
                                    : 'Daily Data Analysis')),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Pink/Lavender Container matching Screenshot
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 650),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tab Bar Container
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    controller: _tabScroll,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_tabs.length,
                          (index) => _buildTabItem(_tabs[index], index)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Active Tab Content
                _buildActiveTabContent(),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      key: _tabKeys[index],
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectTab(index),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? const Color(0xFF7E22CE) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildMandingTab();
      case 1:
        return _buildMandingGraphTab();
      case 2:
        return _buildDailyDataSheetDttTab();
      case 3:
        return _buildSkillTrackingTab();
      case 4:
        return _buildAcquisitionGraphTab();
      case 5:
        return _buildAbcDataTab();
      case 6:
        return _buildBrpTab();
      case 7:
        return _buildPbGraphTab();
      case 8:
        return _buildIepReportTab();
      default:
        return _buildMandingTab();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 1. MANDING TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMandingTab() {
    int totalPrompted = 0;
    int totalUnprompted = 0;
    for (final r in _mandingRows) {
      final counts = r['counts'] as List<int>;
      for (int i = 0; i < counts.length; i++) {
        if (i < 8) {
          totalPrompted += counts[i];
        } else {
          totalUnprompted += counts[i];
        }
      }
    }
    final int grandTotal = totalPrompted + totalUnprompted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Filter Bar
        _buildFilterBar(
          wideAt: 740,
          leading: [
            _buildFilterPill('Date:', _mandingDate, 140,
                onTap: _pickMandingDate),
            _buildFilterPill('Time In:', _mandingTimeIn, 130,
                onTap: () => _pickMandingTime(timeIn: true)),
            _buildFilterPill('Time Out:', _mandingTimeOut, 130,
                onTap: () => _pickMandingTime(timeIn: false)),
          ],
          trailing: ElevatedButton.icon(
            onPressed: _addNewMandRow,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add Row'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_mandingRows.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: const Center(
              child: Text(
                'No manding trials recorded on this date.\nClick "+ Add Row" above to begin recording, or pick another date.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                    fontSize: 13),
              ),
            ),
          )
        else
          // Min width: 120 label + 10 prompt columns x 56 + 70 vocal + gaps.
          ScrollableMinWidth(
            minWidth: 120 + 8 + _mandingColumns.length * 56 + 8 + 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grid Table Header
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8B4FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC084FC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Mands',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87)),
                      ),
                      Expanded(
                        child: Row(
                          children: _mandingColumns.map((col) {
                            return Expanded(
                              child: Center(
                                child: Text(col,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.black87)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Container(
                        width: 70,
                        alignment: Alignment.center,
                        child: const Text('Vocal',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black87)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Manding Rows
                ..._mandingRows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  final counts = row['counts'] as List<int>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC084FC),
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8)),
                                ),
                                child: Text('${idx + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(row['label'] ?? 'Mand',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.black87)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: List.generate(counts.length, (colIdx) {
                              return Expanded(
                                child: Container(
                                  height: 38,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(19),
                                    border: Border.all(
                                        color: const Color(0xFFE9D5FF)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (counts[colIdx] > 0) {
                                            setState(() => counts[colIdx]--);
                                          }
                                        },
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                              color: Color(0xFFE9D5FF),
                                              shape: BoxShape.circle),
                                          child: const Center(
                                              child: Text('-',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Color(0xFF7E22CE)))),
                                        ),
                                      ),
                                      Text('${counts[colIdx]}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => counts[colIdx]++);
                                        },
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                              color: Color(0xFFE9D5FF),
                                              shape: BoxShape.circle),
                                          child: const Center(
                                              child: Text('+',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Color(0xFF7E22CE)))),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 70,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: Text(row['label'] ?? 'Vocal',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // Dynamic Summary Bar
        LayoutBuilder(
          builder: (context, constraints) {
            final boxes = [
              _buildSummaryBox('Prompted', '$totalPrompted'),
              _buildSummaryBox('Unprompted', '$totalUnprompted'),
              _buildSummaryBox('Total', '$grandTotal'),
            ];
            if (constraints.maxWidth >= 3 * 180 + 24) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: boxes,
              );
            }
            return Wrap(spacing: 12, runSpacing: 8, children: boxes);
          },
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => _cancelSheet(
                    hasUnsaved: _allMandingRows.any(_mandingRowChanged)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFE9D5FF),
                  foregroundColor: const Color(0xFF7E22CE),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _savingManding ? null : _saveMandingSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                child: Text(_savingManding ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 2. MANDING GRAPH TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMandingGraphTab() {
    final points = _mandingGraphPoints();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterBar(
          wideAt: 640,
          leading: [
            _buildFilterPill('From Date:', _mgFromDate, 140,
                onTap: () => _pickFilterDate(
                    _mgFromDate,
                    (d) => _setRange(d, true, (v) => _mgFromDate = v,
                        (v) => _mgToDate = v, _mgToDate))),
            _buildFilterPill('To Date:', _mgToDate, 140,
                onTap: () => _pickFilterDate(
                    _mgToDate,
                    (d) => _setRange(d, false, (v) => _mgFromDate = v,
                        (v) => _mgToDate = v, _mgFromDate))),
          ],
          trailing: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC084FC)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 6, backgroundColor: Color(0xFF9333EA)),
                SizedBox(width: 6),
                Text('Line Graph',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7E22CE))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (points.isEmpty)
          _buildEmptyBox(
              'No manding sessions recorded between $_mgFromDate and $_mgToDate.')
        else ...[
          Container(
            height: 340,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: MandingLineChart(data: points),
          ),
          const SizedBox(height: 24),
          _buildMandingSessionTable(points),
        ],
      ],
    );
  }

  /// White bordered box with a short centred message, for empty graphs and
  /// tables.
  Widget _buildEmptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC084FC)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Color(0xFF6B7280), fontSize: 13, fontFamily: 'Poppins'),
      ),
    );
  }

  /// Date / Prompted / Unprompted table with one column per session. On narrow
  /// widths each session column keeps a readable 60px and the table scrolls
  /// sideways; the row-label column stays 96px wide.
  Widget _buildMandingSessionTable(List<Map<String, dynamic>> points) {
    const labelColWidth = 96.0;
    const dataColWidth = 60.0;
    final minWidth = labelColWidth + points.length * dataColWidth;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC084FC)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < minWidth;
          final table = Table(
            border: TableBorder.all(color: const Color(0xFFE9D5FF)),
            columnWidths:
                narrow ? const {0: FixedColumnWidth(labelColWidth)} : null,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFFAF5FF)),
                children: [
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Date',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                  ...points.map((d) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(d['date'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Prompted',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                  ...points.map((d) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('${d['prompted'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Unprompted',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                  ...points.map((d) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('${d['unprompted'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)))),
                ],
              ),
            ],
          );
          return ScrollableMinWidth(minWidth: minWidth, child: table);
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 3. DAILY DATA SHEET DTT TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildDailyDataSheetDttTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterBar(
          wideAt: 720,
          leading: [
            _buildFilterPill('Date:', _ddsDate, 130,
                onTap: () => _pickFilterDate(_ddsDate, (d) => _ddsDate = d)),
          ],
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFED7AA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Date Introduced: ',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    Container(
                        width: 40, height: 10, color: const Color(0xFFB91C1C)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Date Mastered:   ',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    Container(
                        width: 40, height: 10, color: const Color(0xFF15803D)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildAccordionSection(
          title: 'MANDING GOALS',
          isExpanded: _mandingGoalsExpanded,
          onToggle: () =>
              setState(() => _mandingGoalsExpanded = !_mandingGoalsExpanded),
          child: _buildDttDomainTargets(
              'mand', 'No manding targets recorded on this date.'),
        ),
        const SizedBox(height: 12),
        _buildAccordionSection(
          title: 'LISTENER RESPONDING GOALS',
          isExpanded: _listenerGoalsExpanded,
          onToggle: () =>
              setState(() => _listenerGoalsExpanded = !_listenerGoalsExpanded),
          child: _buildDttDomainTargets('listener',
              'No listener responding targets recorded on this date.'),
        ),
        const SizedBox(height: 12),
        _buildAccordionSection(
          title: 'TACTING GOALS',
          isExpanded: _tactingGoalsExpanded,
          onToggle: () =>
              setState(() => _tactingGoalsExpanded = !_tactingGoalsExpanded),
          child: _buildDttDomainTargets(
              'tact', 'No tacting targets recorded on this date.'),
        ),
        const SizedBox(height: 12),
        _buildAccordionSection(
          title: 'VISUAL PERCEPTUAL SKILLS AND MATCHING-TO-SAMPLE',
          isExpanded: _vpGoalsExpanded,
          onToggle: () => setState(() => _vpGoalsExpanded = !_vpGoalsExpanded),
          child: _buildDttDomainTargets(
              'vp', 'No VP/MTS targets recorded on this date.'),
        ),
        if (_dttForDate().any((t) => _dttSection(t) == 'other')) ...[
          const SizedBox(height: 12),
          _buildAccordionSection(
            title: 'OTHER SKILL GOALS',
            isExpanded: _otherGoalsExpanded,
            onToggle: () =>
                setState(() => _otherGoalsExpanded = !_otherGoalsExpanded),
            child: _buildDttDomainTargets('other', ''),
          ),
        ],
      ],
    );
  }

  /// DTT rows of the selected session date.
  List<Map<String, dynamic>> _dttForDate() {
    final date = _apiDate(_ddsDate);
    return _dttTargets.where((t) => t['date'] == date).toList();
  }

  /// Which DTT accordion a target belongs to.
  String _dttSection(Map<String, dynamic> t) {
    final d = (t['domain'] ?? '').toString().toLowerCase();
    if (d.contains('mand')) return 'mand';
    if (d.contains('listener')) return 'listener';
    if (d.contains('tact')) return 'tact';
    if (d.contains('vp') || d.contains('visual') || d.contains('matching')) {
      return 'vp';
    }
    return 'other';
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 4. SKILL TRACKING SHEET TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildSkillTrackingTab() {
    final domains = _skillDomains();
    final domain = _pickDomain(_skillDomain, domains);
    // One row per target of the chosen domain, oldest introduced first.
    final targets = targetProgress(_records)
        .where((t) => _sameDomain(t.domain, domain))
        .toList()
      ..sort((a, b) => (a.firstSession ?? DateTime(0))
          .compareTo(b.firstSession ?? DateTime(0)));
    final masteredCount = targets.where((t) => t.mastered).length;

    final summary = Text(
      domains.isEmpty
          ? 'No skill targets recorded yet'
          : '${targets.length} target${targets.length == 1 ? '' : 's'} · '
              '$masteredCount mastered',
      style: const TextStyle(
          fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC084FC), Color(0xFFD8B4FE)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 20,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (domains.isNotEmpty)
                _buildDomainDropdown(domains, domain,
                    (val) => setState(() => _skillDomain = val)),
              summary,
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: targets.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                        domains.isEmpty
                            ? 'No skill targets recorded for this student yet.'
                            : 'No $domain targets recorded for this student.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 13)),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text('Target',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                          Expanded(
                              flex: 3,
                              child: Text('Date Introduced',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                          Expanded(
                              flex: 3,
                              child: Text('Date Mastered',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...targets.map((t) {
                      final dateFmt = DateFormat('dd-MMM-yyyy');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                            color: t.mastered
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text(t.target,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12))),
                            Expanded(
                                flex: 3,
                                child: Text(
                                    t.firstSession == null
                                        ? '—'
                                        : dateFmt.format(t.firstSession!),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12))),
                            Expanded(
                                flex: 3,
                                child: Text(
                                    t.masteredOn == null
                                        ? 'In acquisition'
                                        : dateFmt.format(t.masteredOn!),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        Text(
          'A target is mastered on the first session with at least '
          '$masteryMinTrials trials and ${(masteryRatio * 100).round()}% success.',
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  /// White domain dropdown used by the Skill Tracking and Acquisition tabs.
  /// [value] must be one of [domains].
  Widget _buildDomainDropdown(
      List<String> domains, String value, ValueChanged<String> onChanged) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: domains
              .map((d) => DropdownMenuItem(
                  value: d,
                  child: Text(d,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600))))
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 5. ACQUISITION GRAPH TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildAcquisitionGraphTab() {
    final domains = _skillDomains();
    _acqDomain = _pickDomain(_acqDomain, domains);
    final points = _acquisitionPoints();
    const headStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterBar(
          wideAt: 640,
          leading: [
            _buildFilterPill('From Date:', _acqFromDate, 140,
                onTap: () => _pickFilterDate(
                    _acqFromDate,
                    (d) => _setRange(d, true, (v) => _acqFromDate = v,
                        (v) => _acqToDate = v, _acqToDate))),
            _buildFilterPill('To Date:', _acqToDate, 140,
                onTap: () => _pickFilterDate(
                    _acqToDate,
                    (d) => _setRange(d, false, (v) => _acqFromDate = v,
                        (v) => _acqToDate = v, _acqFromDate))),
          ],
          trailing: domains.isEmpty
              ? null
              : _buildDomainDropdown(domains, _acqDomain,
                  (val) => setState(() => _acqDomain = val)),
        ),
        const SizedBox(height: 24),
        if (domains.isEmpty)
          _buildEmptyBox('No skill targets recorded for this student yet.')
        else if (points.isEmpty)
          _buildEmptyBox(
              'No $_acqDomain targets mastered between $_acqFromDate and $_acqToDate.')
        else ...[
          Container(
            height: 340,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: AcquisitionLineChart(data: points),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC084FC)),
            ),
            child: Table(
              border: TableBorder.all(color: const Color(0xFFE9D5FF)),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFFAF5FF)),
                  children: [
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Date', style: headStyle)),
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Mastered', style: headStyle)),
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Cumulative', style: headStyle)),
                  ],
                ),
                ...points.map((d) => TableRow(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(d['date'] ?? '',
                                style: const TextStyle(fontSize: 12))),
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('${d['new'] ?? 0}',
                                style: const TextStyle(fontSize: 12))),
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('${d['count'] ?? 0}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF7E22CE)))),
                      ],
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 6. ABC DATA TAB (Live Incident Stopwatch & Dynamic Form)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildAbcDataTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: _addNewIncident,
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16, color: Color(0xFF7E22CE)),
                  SizedBox(width: 4),
                  Text('Add Incident',
                      style: TextStyle(
                          color: Color(0xFF7E22CE),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_abcIncidents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: const Center(
              child: Text(
                'No antecedent-behavior-consequence (ABC) incidents logged for this student.\nClick "Add Incident" above to record one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                    fontSize: 13),
              ),
            ),
          )
        else
          ..._abcIncidents.map(_buildIncidentCard),
      ],
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final isExpanded = incident['isExpanded'] as bool;
    final saving = incident['saving'] == true;
    return Container(
      key: ObjectKey(incident),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC084FC), Color(0xFFD8B4FE)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => incident['isExpanded'] = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _incidentTitle(incident),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF5FF),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 20,
                    runSpacing: 10,
                    children: [
                      _buildFilterPill('Date:', incident['date'] ?? '', 130,
                          onTap: () => _pickFilterDate(incident['date'] ?? '',
                              (d) => incident['date'] = d)),
                      _buildFilterPill('Time:', incident['time'] ?? '', 130,
                          onTap: () => _pickIncidentTime(incident)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Setting Events:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE9D5FF))),
                    child: TextFormField(
                      initialValue: incident['setting'] ?? '',
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          hintText:
                              'Enter setting events or environmental triggers'),
                      onChanged: (val) => incident['setting'] = val,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Antecedent',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  _buildDropdownWithNote(
                    value: incident['antecedent'] ?? '',
                    options: _antecedentOptions,
                    hint: 'Select antecedent',
                    note: incident['antecedentNote'] ?? '',
                    onSelected: (val) =>
                        setState(() => incident['antecedent'] = val),
                    onNoteChanged: (val) => incident['antecedentNote'] = val,
                  ),
                  const SizedBox(height: 14),
                  const Text('Behaviors',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final behaviorDropdown = _buildOptionDropdown(
                        value: incident['behavior'] ?? '',
                        options: _behaviourOptions,
                        hint: 'Select behaviour',
                        onSelected: (val) =>
                            setState(() => incident['behavior'] = val),
                      );
                      const countLabel = Text('Count: ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13));
                      final countCounter = _buildMiniCounter(incident['count'],
                          (val) => setState(() => incident['count'] = val));
                      const timeLabel = Text('Time(mint): ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13));
                      final timeCounter = _buildMiniCounter(
                          incident['timeMins'],
                          (val) => setState(() => incident['timeMins'] = val));
                      // Real Interactive Digital Stopwatch with Start/Stop/Reset
                      final stopwatch = IncidentStopwatch(
                        onMinutesUpdated: (mins) {
                          setState(() {
                            incident['timeMins'] = mins;
                          });
                        },
                      );

                      if (constraints.maxWidth >= 720) {
                        return Row(
                          children: [
                            behaviorDropdown,
                            const SizedBox(width: 16),
                            countLabel,
                            const SizedBox(width: 6),
                            countCounter,
                            const SizedBox(width: 16),
                            timeLabel,
                            const SizedBox(width: 6),
                            timeCounter,
                            const SizedBox(width: 16),
                            stopwatch,
                          ],
                        );
                      }
                      return Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          behaviorDropdown,
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            countLabel,
                            const SizedBox(width: 6),
                            countCounter
                          ]),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            timeLabel,
                            const SizedBox(width: 6),
                            timeCounter
                          ]),
                          stopwatch,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Consequences',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  _buildDropdownWithNote(
                    value: incident['consequence'] ?? '',
                    options: _consequenceOptions,
                    hint: 'Select consequence',
                    note: incident['consequenceNote'] ?? '',
                    onSelected: (val) =>
                        setState(() => incident['consequence'] = val),
                    onNoteChanged: (val) => incident['consequenceNote'] = val,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (incident['id'] == null)
                          OutlinedButton(
                            onPressed: saving
                                ? null
                                : () => setState(
                                    () => _abcIncidents.remove(incident)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFE9D5FF),
                              foregroundColor: const Color(0xFF7E22CE),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: const Text('Discard'),
                          ),
                        ElevatedButton(
                          onPressed:
                              saving ? null : () => _saveIncident(incident),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9333EA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: Text(saving
                              ? 'Saving…'
                              : (incident['id'] == null ? 'Save' : 'Update')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickIncidentTime(Map<String, dynamic> incident) async {
    TimeOfDay initial = TimeOfDay.now();
    try {
      initial = TimeOfDay.fromDateTime(DateFormat('hh:mm a')
          .parseStrict((incident['time'] ?? '').toString()));
    } catch (_) {}
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    setState(() => incident['time'] = DateFormat('hh:mm a')
        .format(DateTime(2000, 1, 1, picked.hour, picked.minute)));
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 7. BRP TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildBrpTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_selectedStudent',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        const Text(
          'BEHAVIOUR REDUCTION PLAN (BRP)',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          alignment: Alignment.topLeft,
          child: Text(_selectedStudent ?? 'Student Name',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 16),
        const Text('What is the form of the problem behaviors?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9D5FF))),
          child: TextField(
            controller: _brpFormController,
            maxLines: 2,
            decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintText:
                    'Describe physical topography of observed behaviors...'),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
            'DESCRIPTION OF PROBLEM BEHAVIOURS FUNCTION OF PROBLEM BEHAVIOURS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        const Text(
            'Which variables have reinforced and continue to maintain the problem behaviours?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9D5FF))),
          child: TextField(
            controller: _brpFunctionController,
            maxLines: 2,
            decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintText: 'Identify maintaining variables and functions...'),
          ),
        ),
        const SizedBox(height: 16),
        const Text('MEASUREMENT OF PROBLEM BEHAVIOURS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9D5FF))),
          child: TextField(
            controller: _brpMeasurementController,
            maxLines: 2,
            decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintText:
                    'Specify measurement metric (Frequency, Duration, Latency, PIR)...'),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => _cancelSheet(hasUnsaved: _brpHasUnsavedEdits),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFE9D5FF),
                  foregroundColor: const Color(0xFF7E22CE),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _savingBrp ? null : _saveBrp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(_savingBrp ? 'Saving…' : 'Save'),
              ),
              ElevatedButton(
                onPressed: _printBrp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Print'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 8. PB GRAPH TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildPbGraphTab() {
    final isDuration = _pbGraphType == _pbGraphTypes.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _pbGraphType,
                items: _pbGraphTypes
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _pbGraphType = val);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (isDuration) _buildPbDurationView() else _buildPbCountView(),
      ],
    );
  }

  /// Total problem-behaviour minutes per date: graph, then table.
  Widget _buildPbDurationView() {
    final points = _pbDurationPoints();
    if (points.isEmpty) {
      return _buildEmptyBox(
          'No problem behaviour incidents recorded for this student.');
    }
    return Column(
      children: [
        Container(
          height: 330,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: Column(
            children: [
              const Text('DURATION (MINS)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E3A8A))),
              const SizedBox(height: 12),
              Expanded(child: PbDurationLineChart(data: points)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildPbTable(
          headers: const ['Date', 'Duration (mins)'],
          rows: [
            for (final p in points) ['${p['date']}', '${p['duration']}'],
          ],
        ),
      ],
    );
  }

  /// Count of each behaviour per date: multi-line graph, then table.
  Widget _buildPbCountView() {
    final (behaviours, points) = _pbCountPoints();
    if (points.isEmpty) {
      return _buildEmptyBox(
          'No problem behaviour incidents recorded for this student.');
    }
    return Column(
      children: [
        Container(
          height: 330,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (int i = 0; i < behaviours.length; i++)
                    _buildLegendItem(behaviours[i], pbBehaviorColor(i)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PbMultiBehaviorLineChart(
                    data: points, behaviors: behaviours),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildPbTable(
          headers: ['Date', ...behaviours],
          rows: [
            for (final p in points)
              ['${p['date']}', for (final b in behaviours) '${p[b] ?? 0}'],
          ],
        ),
      ],
    );
  }

  /// Simple bordered table; scrolls sideways when there are many columns.
  Widget _buildPbTable(
      {required List<String> headers, required List<List<String>> rows}) {
    const headStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC084FC)),
      ),
      child: ScrollableMinWidth(
        minWidth: headers.length * 90.0,
        child: Table(
          border: TableBorder.all(color: const Color(0xFFE9D5FF)),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFFAF5FF)),
              children: [
                for (final h in headers)
                  Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(h, style: headStyle)),
              ],
            ),
            for (final r in rows)
              TableRow(
                children: [
                  for (int i = 0; i < r.length; i++)
                    Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(r[i],
                            style: i == 0
                                ? const TextStyle(fontSize: 12)
                                : const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF7E22CE)))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 9. IEP REPORT TAB
  // ════════════════════════════════════════════════════════════════════════════
  /// Summary of the student's recorded data: sessions, targets per domain
  /// (mastered via progress_metrics) and behaviour incidents.
  Widget _buildIepReportTab() {
    final skillRows = _records.where(isSkillRow).toList();
    final targets = targetProgress(_records);
    final behaviourRows = _records.where(_isBehaviourRow).toList();
    final sessionDates = {
      for (final r in skillRows) rowDate(r),
    }.whereType<DateTime>().toList()
      ..sort();
    final dateFmt = DateFormat('dd-MMM-yyyy');

    // Targets and mastered targets per domain, first spelling wins.
    final byDomain = <String, List<TargetProgress>>{};
    for (final t in targets) {
      final key = byDomain.keys.firstWhere((k) => _sameDomain(k, t.domain),
          orElse: () => t.domain.trim());
      (byDomain[key] ??= []).add(t);
    }
    final domainNames = byDomain.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final recentlyMastered = targets.where((t) => t.mastered).toList()
      ..sort((a, b) => b.masteredOn!.compareTo(a.masteredOn!));

    const headStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    Widget stat(String label, String value) => Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7E22CE))),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IEP Daily Session Takeaways & Objectives',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              sessionDates.isEmpty
                  ? 'No skill sessions recorded for this student yet.'
                  : 'Sessions from ${dateFmt.format(sessionDates.first)} '
                      'to ${dateFmt.format(sessionDates.last)}.',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          if (_records.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                stat('Session days', '${sessionDates.length}'),
                stat('Targets', '${targets.length}'),
                stat('Mastered', '${targets.where((t) => t.mastered).length}'),
                stat('In acquisition',
                    '${targets.where((t) => !t.mastered).length}'),
                stat('Behaviour incidents', '${behaviourRows.length}'),
              ],
            ),
          ],
          if (domainNames.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Targets by domain', style: headStyle),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: const Color(0xFFE9D5FF)),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFFAF5FF)),
                  children: [
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Domain', style: headStyle)),
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Targets', style: headStyle)),
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Mastered', style: headStyle)),
                  ],
                ),
                for (final d in domainNames)
                  TableRow(
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(d, style: const TextStyle(fontSize: 12))),
                      Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('${byDomain[d]!.length}',
                              style: const TextStyle(fontSize: 12))),
                      Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                              '${byDomain[d]!.where((t) => t.mastered).length}',
                              style: const TextStyle(fontSize: 12))),
                    ],
                  ),
              ],
            ),
          ],
          if (recentlyMastered.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Recently mastered', style: headStyle),
            const SizedBox(height: 8),
            for (final t in recentlyMastered.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                    '${t.target} (${t.domain}) · ${dateFmt.format(t.masteredOn!)}',
                    style: const TextStyle(fontSize: 12)),
              ),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ════════════════════════════════════════════════════════════════════════════
  /// Gradient filter bar: a single row (leading items, then [trailing] pushed
  /// to the end) when there is room, otherwise the items wrap onto new lines.
  Widget _buildFilterBar({
    required List<Widget> leading,
    Widget? trailing,
    double wideAt = 720,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC084FC), Color(0xFFD8B4FE)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= wideAt) {
            return Row(
              children: [
                for (int i = 0; i < leading.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  leading[i],
                ],
                if (trailing != null) ...[const Spacer(), trailing],
              ],
            );
          }
          return Wrap(
            spacing: 16,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [...leading, if (trailing != null) trailing],
          );
        },
      ),
    );
  }

  Widget _buildFilterPill(String label, String value, double width,
      {VoidCallback? onTap}) {
    final pill = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        const SizedBox(width: 8),
        Container(
          width: width,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ),
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: Color(0xFF7E22CE)),
            ],
          ),
        ),
      ],
    );
    if (onTap == null) return pill;
    return InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(16), child: pill);
  }

  /// White 200px dropdown for the ABC form. An empty [value] shows [hint];
  /// a saved value that is not one of [options] is added so it still shows.
  Widget _buildOptionDropdown({
    required String value,
    required List<String> options,
    required String hint,
    required ValueChanged<String> onSelected,
  }) {
    final items = [
      ...options,
      if (value.isNotEmpty && !options.contains(value)) value,
    ];
    return Container(
      height: 38,
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE9D5FF))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          items: items
              .map((o) => DropdownMenuItem(
                  value: o,
                  child: Text(o,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12))))
              .toList(),
          onChanged: (val) {
            if (val != null) onSelected(val);
          },
        ),
      ),
    );
  }

  /// ABC "dropdown + Note: field" row. Side by side when there is room,
  /// otherwise the note field drops below the dropdown.
  Widget _buildDropdownWithNote({
    required String value,
    required List<String> options,
    required String hint,
    required String note,
    required ValueChanged<String> onSelected,
    required ValueChanged<String> onNoteChanged,
  }) {
    final dropdown = _buildOptionDropdown(
        value: value, options: options, hint: hint, onSelected: onSelected);
    final noteRow = <Widget>[
      const Text('Note:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          height: 38,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9D5FF))),
          child: TextFormField(
            initialValue: note,
            decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            onChanged: onNoteChanged,
          ),
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 480) {
          return Row(
              children: [dropdown, const SizedBox(width: 16), ...noteRow]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dropdown,
            const SizedBox(height: 8),
            Row(children: noteRow),
          ],
        );
      },
    );
  }

  Widget _buildSummaryBox(String label, String count) {
    return Container(
      width: 180,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black87)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(count,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCounter(int count, ValueChanged<int> onChanged) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
          color: const Color(0xFFE9D5FF),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (count > 0) onChanged(count - 1);
            },
            child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('-',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7E22CE)))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Text('$count',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          InkWell(
            onTap: () => onChanged(count + 1),
            child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('+',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7E22CE)))),
          ),
        ],
      ),
    );
  }

  Widget _buildDttDomainTargets(String domainKey, String emptyMessage) {
    final targets =
        _dttForDate().where((t) => _dttSection(t) == domainKey).toList();
    // Introduced / mastered dates of each target, keyed like targetKey().
    final progress = {
      for (final p in targetProgress(_records))
        '${p.domain.trim().toLowerCase()}|${p.target.trim().toLowerCase()}': p,
    };

    if (targets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.black54,
                fontStyle: FontStyle.italic,
                fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: targets.map((t) {
        final target = (t['target'] ?? '').toString();
        final prompt = (t['prompt'] ?? '').toString();
        final trials = t['trials'] ?? 0;
        final success = t['success'] ?? 0;
        final pct = (t['pct'] ?? '0').toString();
        final tp =
            progress['${(t['domain'] ?? '').toString().trim().toLowerCase()}'
                '|${target.trim().toLowerCase()}'];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF3B0764)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Prompt Level: $prompt',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  if (tp != null) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (tp.firstSession != null)
                          _buildDateTag(
                              'Introduced ${_labelFmt.format(tp.firstSession!)}',
                              const Color(0xFFB91C1C)),
                        if (tp.masteredOn != null)
                          _buildDateTag(
                              'Mastered ${_labelFmt.format(tp.masteredOn!)}',
                              const Color(0xFF15803D)),
                      ],
                    ),
                  ],
                ],
              );
              final trialsChip = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Text(
                  'Trials: $success / $trials',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B21A8)),
                ),
              );
              final pctChip = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              );

              // Narrow cards: chips drop below the target name.
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    info,
                    const SizedBox(height: 8),
                    Row(children: [
                      trialsChip,
                      const SizedBox(width: 12),
                      pctChip
                    ]),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 3, child: info),
                  trialsChip,
                  const SizedBox(width: 12),
                  pctChip,
                ],
              );
            },
          ),
        );
      }).toList(),
    );
  }

  /// Small coloured label matching the DTT legend (introduced / mastered).
  Widget _buildDateTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }

  Widget _buildAccordionSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87))),
                  Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.black87),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}
