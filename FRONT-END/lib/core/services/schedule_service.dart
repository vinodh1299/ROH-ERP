// lib/core/services/schedule_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import 'api_service.dart';
import 'notification_service.dart';

class ScheduleService extends ChangeNotifier {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;

  final ApiService _api = ApiService();
  Timer? _periodicTimer;

  ScheduleService._internal() {
    syncWithBackend();
    // Continuous background sync every 4 seconds across browser tabs
    _periodicTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      syncWithBackend();
    });
  }

  Future<void> syncWithBackend() async {
    try {
      final sessRes = await _api.get('get_sessions');
      if (sessRes is List) {
        _sessions.clear();
        for (final item in sessRes) {
          if (item is Map<String, dynamic>) {
            final sDate = item['session_date'] != null
                ? DateTime.tryParse(item['session_date'].toString()) ?? DateTime.now()
                : DateTime.now();
            SessionStatus stat = SessionStatus.upcoming;
            if (item['status'] == 'completed') stat = SessionStatus.completed;
            if (item['status'] == 'inProgress') stat = SessionStatus.inProgress;
            if (item['status'] == 'cancelled') stat = SessionStatus.cancelled;

            _sessions.add(TherapySession(
              id: item['id'].toString(),
              therapistId: (item['therapist_id'] ?? '').toString(),
              therapistName: item['therapist_name'] ?? 'Therapist',
              studentId: (item['student_id'] ?? '').toString(),
              studentName: item['student_name'] ?? 'Student',
              studentAge: 15,
              programTitle: item['program_title'] ?? 'ABA Intervention',
              room: item['room'] ?? 'Sensory Room A',
              date: sDate,
              startTime: item['start_time'] ?? '09:00 AM',
              endTime: item['end_time'] ?? '10:15 AM',
              status: stat,
              notes: item['clinical_notes'] ?? '',
            ));
          }
        }
      }

      final apptRes = await _api.get('get_director_appointments');
      if (apptRes is List) {
        _directorAppointments.clear();
        for (final item in apptRes) {
          if (item is Map<String, dynamic>) {
            final aDate = item['date'] != null
                ? DateTime.tryParse(item['date'].toString()) ?? DateTime.now()
                : DateTime.now();
            AppointmentType aType = AppointmentType.diagnosticIntake;
            final typeStr = item['appointment_type']?.toString() ?? '';
            if (typeStr.contains('iep')) aType = AppointmentType.iepReview;
            if (typeStr.contains('bacb')) aType = AppointmentType.bacbSupervision;
            if (typeStr.contains('parent')) aType = AppointmentType.parentConference;

            _directorAppointments.add(DirectorAppointment(
              id: item['id'].toString(),
              title: item['title'] ?? 'Director Consultation',
              type: aType,
              date: aDate,
              startTime: item['start_time'] ?? '09:00 AM',
              endTime: item['end_time'] ?? '10:00 AM',
              attendeeName: item['attendee_name'] ?? 'Parent',
              attendeeRole: item['attendee_role'] ?? 'Parent',
              attendeePhone: item['attendee_phone'] ?? '',
              attendeeEmail: item['attendee_email'] ?? '',
              location: item['location'] ?? 'Director Office Suite',
              scheduledBy: item['scheduled_by'] ?? 'Admin',
              status: AppointmentStatus.confirmed,
              notes: item['notes'] ?? '',
            ));
          }
        }
      }

      final thRes = await _api.get('get_therapists');
      if (thRes is List) {
        _therapistsList.clear();
        for (final t in thRes) {
          if (t is Map<String, dynamic>) {
            _therapistsList.add({
              'id': t['id']?.toString() ?? '',
              'name': t['name']?.toString() ?? 'Therapist',
              'designation': t['designation']?.toString() ?? 'Behavior Therapist',
            });
          }
        }
      }

      final stRes = await _api.get('get_students');
      if (stRes is List) {
        _studentsList.clear();
        for (final s in stRes) {
          if (s is Map<String, dynamic>) {
            _studentsList.add({
              'id': s['id']?.toString() ?? '',
              'name': (s['name'] ?? '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}').toString().trim(),
              'age': s['age'] ?? 10,
              'programs': (s['program'] ?? s['primary_diagnosis'] ?? 'ABA Intervention').toString(),
            });
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('ScheduleService sync error: $e');
    }
  }

  final List<TherapySession> _sessions = [];
  final List<DirectorAppointment> _directorAppointments = [];
  static final List<Map<String, String>> _therapistsList = [];
  static final List<Map<String, dynamic>> _studentsList = [];

  List<TherapySession> get allSessions => List.unmodifiable(_sessions);
  List<DirectorAppointment> get allDirectorAppointments => List.unmodifiable(_directorAppointments);

  // Standard Director Booking Slots
  static const List<String> standardTimeSlots = [
    '09:00 AM - 10:00 AM',
    '10:15 AM - 11:15 AM',
    '11:30 AM - 12:30 PM',
    '01:30 PM - 02:30 PM',
    '02:45 PM - 03:45 PM',
    '04:00 PM - 05:00 PM',
  ];

  static const List<String> standardTherapySlots = [
    '09:00 AM - 10:15 AM',
    '10:30 AM - 11:45 AM',
    '01:00 PM - 02:15 PM',
    '02:30 PM - 03:45 PM',
    '04:00 PM - 05:15 PM',
  ];

  static const List<String> centerRooms = [
    'Sensory Room A',
    'Sensory Room B',
    'Speech & Language Cabin 1',
    'Speech & Language Cabin 2',
    'ABA Table 1 (DTT)',
    'ABA Table 2 (DTT)',
    'Natural Environment Station 3',
    'Gross Motor Activity Hall',
  ];

  // Dynamic lists populated from live database
  static List<Map<String, String>> get centerTherapists => List.unmodifiable(_therapistsList);
  static List<Map<String, dynamic>> get centerStudents => List.unmodifiable(_studentsList);

  // ──────────────────────────────────────────────────────────────────────────
  // THERAPIST SCHEDULE METHODS
  // ──────────────────────────────────────────────────────────────────────────

  List<TherapySession> getSessionsForTherapist(String therapistId, {DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    return _sessions.where((s) {
      final isSameDate = s.date.year == targetDate.year &&
          s.date.month == targetDate.month &&
          s.date.day == targetDate.day;
      final matchesTherapist = s.therapistId == therapistId || therapistId.isEmpty;
      return isSameDate && matchesTherapist;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<TherapySession> getAllSessionsForDate(DateTime date) {
    return _sessions.where((s) {
      return s.date.year == date.year &&
          s.date.month == date.month &&
          s.date.day == date.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Director schedules session for a therapist
  bool scheduleTherapySession(TherapySession session) {
    // Check therapist time conflict
    final conflict = _sessions.any((s) =>
        s.therapistId == session.therapistId &&
        s.date.year == session.date.year &&
        s.date.month == session.date.month &&
        s.date.day == session.date.day &&
        s.startTime == session.startTime);

    if (conflict) {
      return false; // Conflict exists
    }

    _sessions.add(session);
    notifyListeners();
    return true;
  }

  void updateSessionStatus(String sessionId, SessionStatus newStatus) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index] = _sessions[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void deleteTherapySession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DIRECTOR CALENDAR & APPOINTMENT METHODS (ADMIN SCHEDULES TO DIRECTOR)
  // ──────────────────────────────────────────────────────────────────────────

  List<DirectorAppointment> getDirectorAppointments({DateTime? date}) {
    if (date == null) {
      return List.unmodifiable(_directorAppointments);
    }
    return _directorAppointments.where((a) {
      return a.date.year == date.year &&
          a.date.month == date.month &&
          a.date.day == date.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Check available slots for a specific date
  List<String> getAvailableDirectorSlots(DateTime date) {
    final bookedSlots = _directorAppointments
        .where((a) =>
            a.date.year == date.year &&
            a.date.month == date.month &&
            a.date.day == date.day &&
            a.status != AppointmentStatus.cancelled)
        .map((a) => '${a.startTime} - ${a.endTime}')
        .toSet();

    return standardTimeSlots.where((slot) => !bookedSlots.contains(slot)).toList();
  }

  // Admin books appointment for Director
  Future<bool> scheduleDirectorAppointment(DirectorAppointment appointment) async {
    // Conflict check
    final conflict = _directorAppointments.any((a) =>
        a.date.year == appointment.date.year &&
        a.date.month == appointment.date.month &&
        a.date.day == appointment.date.day &&
        a.startTime == appointment.startTime &&
        a.status != AppointmentStatus.cancelled);

    if (conflict) {
      return false;
    }

    // Optimistic local add
    _directorAppointments.add(appointment);
    notifyListeners();

    try {
      // Synchronize with backend database
      final res = await _api.post('save_director_appointment', {
        'title': appointment.title,
        'appointment_type': appointment.type.name,
        'date': appointment.date.toIso8601String().split('T')[0],
        'start_time': appointment.startTime,
        'end_time': appointment.endTime,
        'attendee_name': appointment.attendeeName,
        'attendee_role': appointment.attendeeRole,
        'attendee_phone': appointment.attendeePhone,
        'attendee_email': appointment.attendeeEmail,
        'location': appointment.location,
        'notes': appointment.notes,
      });

      debugPrint('ScheduleService: Appointment saved successfully: $res');

      // Trigger immediate notification refresh across all listeners
      NotificationService().fetchNotifications(silent: true);

      // Re-sync with backend to get latest database IDs
      await syncWithBackend();
      return true;
    } catch (e) {
      debugPrint('ScheduleService save_director_appointment error: $e');
      return true; // Keep optimistic state
    }
  }

  void updateAppointmentStatus(String appointmentId, AppointmentStatus newStatus) {
    final index = _directorAppointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      _directorAppointments[index] =
          _directorAppointments[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void deleteDirectorAppointment(String appointmentId) {
    _directorAppointments.removeWhere((a) => a.id == appointmentId);
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PARENT & CHILD QUERY HELPER METHODS
  // ──────────────────────────────────────────────────────────────────────────

  List<TherapySession> getSessionsForStudent(String studentName, {DateTime? date}) {
    return _sessions.where((s) {
      final matchesStudent = s.studentName.toLowerCase().contains(studentName.toLowerCase()) ||
          s.studentId.toLowerCase() == studentName.toLowerCase();
      if (!matchesStudent) return false;
      if (date != null) {
        return s.date.year == date.year &&
            s.date.month == date.month &&
            s.date.day == date.day;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<DirectorAppointment> getAppointmentsForStudentOrParent(String query, {DateTime? date}) {
    final q = query.toLowerCase();
    return _directorAppointments.where((a) {
      final matches = a.attendeeName.toLowerCase().contains(q) ||
          a.attendeeRole.toLowerCase().contains(q) ||
          a.title.toLowerCase().contains(q) ||
          a.notes.toLowerCase().contains(q);
      if (!matches) return false;
      if (date != null) {
        return a.date.year == date.year &&
            a.date.month == date.month &&
            a.date.day == date.day;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
}
