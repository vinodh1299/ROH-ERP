import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import 'package:roh_erp/core/services/session_reminders.dart';

/// True once [session]'s start time has passed (sessions can only be marked
/// completed from then on; there is no separate "Start" step).
bool sessionHasStarted(TherapySession session) {
  final start = SessionReminders.startOf(session);
  return start == null || !DateTime.now().isBefore(start);
}

/// Whether [session] still needs to be marked completed.
bool sessionAwaitingCompletion(TherapySession session) =>
    session.status == SessionStatus.upcoming ||
    session.status == SessionStatus.inProgress;

/// Asks for confirmation, then marks [session] completed. The server notifies
/// the Clinical Director.
Future<void> confirmSessionCompleted(
    BuildContext context, TherapySession session) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Mark session completed?'),
      content: Text(
          '${session.studentName} · ${session.startTime}–${session.endTime}\n\n'
          'The Clinical Director will be notified.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Mark Completed'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await ScheduleService()
      .updateSessionStatus(session.id, SessionStatus.completed);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('Session with ${session.studentName} marked completed.'),
    backgroundColor: AppColors.statusActive,
  ));
}
