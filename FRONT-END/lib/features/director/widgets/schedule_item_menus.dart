// lib/features/director/widgets/schedule_item_menus.dart
//
// Overflow menus for director appointments and therapy sessions shown on the
// Director dashboard and the Master Schedule. Each action calls the backend,
// reports the result and re-syncs ScheduleService so every view refreshes.
import 'package:flutter/material.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/models/schedule_model.dart';
import 'package:roh_erp/core/services/api_service.dart';
import 'package:roh_erp/core/services/schedule_service.dart';
import 'package:roh_erp/core/widgets/edit_record_dialogs.dart';

/// Asks before a destructive action; resolves to true when confirmed.
Future<bool> confirmDirectorAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel,
              style: const TextStyle(color: AppColors.statusDeactivated)),
        ),
      ],
    ),
  );
  return ok == true;
}

PopupMenuItem<String> _item(String value, IconData icon, String label,
    {Color color = AppColors.textPrimary}) {
  return PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
      ],
    ),
  );
}

/// ⋮ menu for a director appointment: Mark completed / Cancel / Delete.
class DirectorAppointmentMenu extends StatelessWidget {
  final DirectorAppointment appointment;
  const DirectorAppointmentMenu({super.key, required this.appointment});

  Future<void> _run(BuildContext context, String action) async {
    final appt = appointment;
    final api = ApiService();
    final schedule = ScheduleService();
    dynamic res;
    String success;
    switch (action) {
      case 'complete':
        res = await api.post('update_director_appointment',
            {'id': appt.id, 'status': 'completed'});
        success = '"${appt.title}" marked as completed.';
        break;
      case 'cancel':
        if (!await confirmDirectorAction(context,
            title: 'Cancel appointment?',
            message:
                'Cancel "${appt.title}" with ${appt.attendeeName} at ${appt.startTime}?',
            confirmLabel: 'Cancel appointment')) {
          return;
        }
        res = await api.post('update_director_appointment',
            {'id': appt.id, 'status': 'cancelled'});
        success = '"${appt.title}" cancelled.';
        break;
      case 'delete':
        if (!await confirmDirectorAction(context,
            title: 'Delete appointment?',
            message:
                'Permanently delete "${appt.title}" with ${appt.attendeeName}? This cannot be undone.',
            confirmLabel: 'Delete')) {
          return;
        }
        res = await api.post('delete_director_appointment', {'id': appt.id});
        success = 'Appointment deleted.';
        break;
      default:
        return;
    }
    if (!context.mounted) return;
    if (showApiResult(context, res, success)) await schedule.syncWithBackend();
  }

  @override
  Widget build(BuildContext context) {
    final status = appointment.status;
    return PopupMenuButton<String>(
      tooltip: 'Appointment actions',
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      onSelected: (v) => _run(context, v),
      itemBuilder: (_) => [
        if (status != AppointmentStatus.completed &&
            status != AppointmentStatus.cancelled)
          _item('complete', Icons.check_circle_outline, 'Mark completed',
              color: AppColors.statusActive),
        if (status != AppointmentStatus.cancelled &&
            status != AppointmentStatus.completed)
          _item('cancel', Icons.event_busy, 'Cancel appointment',
              color: AppColors.statusPending),
        _item('delete', Icons.delete_outline, 'Delete',
            color: AppColors.statusDeactivated),
      ],
    );
  }
}

/// ⋮ menu for a therapy session: Mark completed / Cancel / Delete.
class TherapySessionMenu extends StatelessWidget {
  final TherapySession session;
  final Color? iconColor;
  const TherapySessionMenu({super.key, required this.session, this.iconColor});

  Future<void> _run(BuildContext context, String action) async {
    final s = session;
    final api = ApiService();
    final schedule = ScheduleService();
    final label = '${s.studentName} with ${s.therapistName} (${s.startTime})';
    dynamic res;
    String success;
    switch (action) {
      case 'complete':
        res = await api.post(
            'update_therapy_session', {'id': s.id, 'status': 'completed'});
        success = 'Session marked as completed.';
        break;
      case 'cancel':
        if (!await confirmDirectorAction(context,
            title: 'Cancel session?',
            message: 'Cancel the session for $label?',
            confirmLabel: 'Cancel session')) {
          return;
        }
        res = await api.post(
            'update_therapy_session', {'id': s.id, 'status': 'cancelled'});
        success = 'Session cancelled.';
        break;
      case 'delete':
        if (!await confirmDirectorAction(context,
            title: 'Delete session?',
            message:
                'Permanently delete the session for $label? This cannot be undone.',
            confirmLabel: 'Delete')) {
          return;
        }
        res = await api.post('delete_therapy_session', {'id': s.id});
        success = 'Session deleted.';
        break;
      default:
        return;
    }
    if (!context.mounted) return;
    if (showApiResult(context, res, success)) await schedule.syncWithBackend();
  }

  @override
  Widget build(BuildContext context) {
    final status = session.status;
    final open =
        status != SessionStatus.completed && status != SessionStatus.cancelled;
    return PopupMenuButton<String>(
      tooltip: 'Session actions',
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert,
          size: 18, color: iconColor ?? AppColors.textSecondary),
      onSelected: (v) => _run(context, v),
      itemBuilder: (_) => [
        if (open)
          _item('complete', Icons.check_circle_outline, 'Mark completed',
              color: AppColors.statusActive),
        if (open)
          _item('cancel', Icons.event_busy, 'Cancel session',
              color: AppColors.statusPending),
        _item('delete', Icons.delete_outline, 'Delete',
            color: AppColors.statusDeactivated),
      ],
    );
  }
}
