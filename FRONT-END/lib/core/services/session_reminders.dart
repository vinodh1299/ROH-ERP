// lib/core/services/session_reminders.dart
// Alerts a therapist 5 minutes before each of their upcoming sessions.
// On iOS, Android and macOS the OS delivers a pre-scheduled notification,
// so it arrives even when the app is closed. Elsewhere (web, Windows) an
// in-app timer posts it while the app is open.
import 'dart:async';

import '../models/schedule_model.dart';
import 'system_notifications.dart';

class SessionReminders {
  SessionReminders._();

  static const Duration leadTime = Duration(minutes: 5);

  /// How far ahead to schedule. iOS keeps at most 64 pending notifications.
  static const Duration _horizon = Duration(days: 7);
  static const int _maxScheduled = 50;

  /// Reminder notification ids are this base + the session id, so they never
  /// collide with server notification ids.
  static const int _idBase = 700000000;

  static String _signature = '';
  static final Map<int, Timer> _timers = {};
  static final Set<int> _shown = {};

  /// Start time of [s] as a local DateTime ("09:00 AM" on the session date).
  static DateTime? startOf(TherapySession s) {
    final m = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])?\s*$')
        .firstMatch(s.startTime);
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final ampm = m.group(3)?.toUpperCase();
    if (ampm == 'PM' && hour < 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;
    return DateTime(s.date.year, s.date.month, s.date.day, hour, minute);
  }

  /// Brings the scheduled reminders in line with [sessions] (the signed-in
  /// therapist's sessions). Cheap to call often: it only reschedules when
  /// the set of upcoming sessions or their times change.
  static Future<void> sync(List<TherapySession> sessions) async {
    final now = DateTime.now();
    final upcoming = <({int id, DateTime start, TherapySession s})>[];
    for (final s in sessions) {
      if (s.status != SessionStatus.upcoming) continue;
      final id = int.tryParse(s.id);
      final start = startOf(s);
      if (id == null || start == null) continue;
      if (!start.isAfter(now) || start.isAfter(now.add(_horizon))) continue;
      upcoming.add((id: id, start: start, s: s));
    }
    upcoming.sort((a, b) => a.start.compareTo(b.start));
    final wanted = upcoming.take(_maxScheduled).toList();

    final signature =
        wanted.map((w) => '${w.id}@${w.start.toIso8601String()}').join(',');
    if (signature == _signature) return;
    _signature = signature;

    await _cancelAll();
    for (final w in wanted) {
      final notifyId = _idBase + w.id;
      const title = 'Session in 5 minutes';
      final body =
          '${w.s.studentName} · ${w.s.startTime} · ${w.s.room}'.trim();
      final at = w.start.subtract(leadTime);

      // Inside the 5-minute window already: alert once, right now.
      if (!at.isAfter(now)) {
        if (_shown.add(notifyId)) {
          SystemNotifications.show(id: notifyId, title: title, body: body);
        }
        continue;
      }
      final scheduled = await SystemNotifications.schedule(
          id: notifyId, title: title, body: body, at: at);
      if (!scheduled) {
        _timers[notifyId] = Timer(at.difference(now), () {
          _timers.remove(notifyId);
          if (_shown.add(notifyId)) {
            SystemNotifications.show(id: notifyId, title: title, body: body);
          }
        });
      }
    }
  }

  /// Removes every pending reminder (e.g. on sign-out).
  static Future<void> clear() async {
    _signature = '';
    await _cancelAll();
  }

  static Future<void> _cancelAll() async {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    for (final id in await SystemNotifications.pendingIds()) {
      if (id >= _idBase && id < _idBase + 100000000) {
        await SystemNotifications.cancel(id);
      }
    }
  }
}
