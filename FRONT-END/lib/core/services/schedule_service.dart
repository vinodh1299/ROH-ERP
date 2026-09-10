// lib/core/services/schedule_service.dart
import 'package:flutter/material.dart';
import '../models/schedule_model.dart';

class ScheduleService extends ChangeNotifier {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;

  ScheduleService._internal() {
    _initSampleData();
  }

  final List<TherapySession> _sessions = [];
  final List<DirectorAppointment> _directorAppointments = [];

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

  static const List<Map<String, String>> centerTherapists = [
    {'id': 'T1', 'name': 'Dr. Sarah Lee', 'designation': 'Senior BCBA / Lead Therapist'},
    {'id': 'T2', 'name': 'Michael Chang', 'designation': 'Assistant Behavior Analyst (BCaBA)'},
    {'id': 'T3', 'name': 'Emily Chen', 'designation': 'Speech & Language Pathologist'},
    {'id': 'T4', 'name': 'David Kim', 'designation': 'RBT Senior Clinician'},
    {'id': 'T5', 'name': 'Jessica Taylor', 'designation': 'Occupational Therapist'},
    {'id': 'T6', 'name': 'Amanda Martinez', 'designation': 'Behavior Technician'},
  ];

  static const List<Map<String, dynamic>> centerStudents = [
    {'id': 'S1', 'name': 'Alex Thomas Sam', 'age': 15, 'programs': 'VB-MAPP Manding & Echoic Probes'},
    {'id': 'S2', 'name': 'Jemi Wilson', 'age': 15, 'programs': 'Tact Acquisition & Listener Responding'},
    {'id': 'S3', 'name': 'Cameron Williamson', 'age': 12, 'programs': 'Visual Performance & Motor Imitation'},
    {'id': 'S4', 'name': 'Matt Dickerson', 'age': 14, 'programs': 'Social Interaction & Intraverbals'},
    {'id': 'S5', 'name': 'Romeo Alex A', 'age': 15, 'programs': 'Behavior Intervention Plan (BIP)'},
    {'id': 'S6', 'name': 'Sophia Martinez', 'age': 9, 'programs': 'Early Echoic Skill Assessment (EESA)'},
  ];

  void _initSampleData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Initial Director Appointments (Admin scheduled & Director scheduled)
    _directorAppointments.addAll([
      DirectorAppointment(
        id: 'DA-101',
        title: 'Parent Diagnostic Intake & Clinical Assessment',
        type: AppointmentType.diagnosticIntake,
        date: today,
        startTime: '09:00 AM',
        endTime: '10:00 AM',
        attendeeName: 'Mr. John Wilson',
        attendeeRole: 'Parent of Jemi Wilson',
        attendeePhone: '+1 (555) 234-8901',
        attendeeEmail: 'john.wilson@email.com',
        location: 'Director Suite 201',
        scheduledBy: 'Admin',
        status: AppointmentStatus.confirmed,
        notes: 'Initial evaluation for VB-MAPP milestone placement and sensory profile review.',
      ),
      DirectorAppointment(
        id: 'DA-102',
        title: 'IEP Semi-Annual Sign-Off & Audit',
        type: AppointmentType.iepReview,
        date: today,
        startTime: '11:30 AM',
        endTime: '12:30 PM',
        attendeeName: 'Dr. Sarah Lee',
        attendeeRole: 'Lead BCBA Clinician',
        attendeePhone: '+1 (555) 789-1122',
        attendeeEmail: 'sarah.lee@roh.org',
        location: 'Conference Room B',
        scheduledBy: 'Admin',
        status: AppointmentStatus.confirmed,
        notes: 'Review student Alex Thomas Sam progress report and sign digital authorization stamp.',
      ),
      DirectorAppointment(
        id: 'DA-103',
        title: 'BACB 5% Monthly Supervision Review',
        type: AppointmentType.bacbSupervision,
        date: today,
        startTime: '02:45 PM',
        endTime: '03:45 PM',
        attendeeName: 'Michael Chang',
        attendeeRole: 'BCaBA Trainee',
        attendeePhone: '+1 (555) 432-8877',
        attendeeEmail: 'm.chang@roh.org',
        location: 'Director Suite 201',
        scheduledBy: 'Director',
        status: AppointmentStatus.confirmed,
        notes: 'Review discrete trial training fidelity and data sheet documentation.',
      ),
      DirectorAppointment(
        id: 'DA-104',
        title: 'Parent Progress & Transition Conference',
        type: AppointmentType.parentConference,
        date: today.add(const Duration(days: 1)),
        startTime: '10:15 AM',
        endTime: '11:15 AM',
        attendeeName: 'Mrs. Linda Williamson',
        attendeeRole: 'Parent of Cameron Williamson',
        attendeePhone: '+1 (555) 678-3344',
        attendeeEmail: 'linda.w@email.com',
        location: 'Director Suite 201',
        scheduledBy: 'Admin',
        status: AppointmentStatus.confirmed,
        notes: 'Discuss transition to inclusive classroom setting.',
      ),
    ]);

    // Initial Therapist Sessions (Scheduled by Director)
    _sessions.addAll([
      // Dr. Sarah Lee sessions (Lead therapist logged in on therapist portal)
      TherapySession(
        id: 'TS-201',
        therapistId: 'T1',
        therapistName: 'Dr. Sarah Lee',
        studentId: 'S1',
        studentName: 'Alex Thomas Sam',
        studentAge: 15,
        programTitle: 'VB-MAPP Milestone Level 2: Manding & Echoic Probes',
        room: 'Sensory Room A',
        date: today,
        startTime: '09:00 AM',
        endTime: '10:15 AM',
        status: SessionStatus.inProgress,
        notes: 'Target 10 unprompted mands for preferred tactile items; record rate and prompt delay.',
      ),
      TherapySession(
        id: 'TS-202',
        therapistId: 'T1',
        therapistName: 'Dr. Sarah Lee',
        studentId: 'S2',
        studentName: 'Jemi Wilson',
        studentAge: 15,
        programTitle: 'Tact Acquisition & Listener Responding by Feature',
        room: 'ABA Table 2 (DTT)',
        date: today,
        startTime: '10:30 AM',
        endTime: '11:45 AM',
        status: SessionStatus.upcoming,
        notes: 'LRFFC Level 3: Select animal by characteristic feature from array of 6.',
      ),
      TherapySession(
        id: 'TS-203',
        therapistId: 'T1',
        therapistName: 'Dr. Sarah Lee',
        studentId: 'S3',
        studentName: 'Cameron Williamson',
        studentAge: 12,
        programTitle: 'Visual Performance & Block Pattern Matching',
        room: 'Natural Environment Station 3',
        date: today,
        startTime: '01:00 PM',
        endTime: '02:15 PM',
        status: SessionStatus.upcoming,
        notes: 'VP-MTS Level 2 Task 9: Replicate 3D block design within 30s.',
      ),
      TherapySession(
        id: 'TS-204',
        therapistId: 'T1',
        therapistName: 'Dr. Sarah Lee',
        studentId: 'S4',
        studentName: 'Matt Dickerson',
        studentAge: 14,
        programTitle: 'Social Play & Turn Taking Protocol',
        room: 'Gross Motor Activity Hall',
        date: today,
        startTime: '04:00 PM',
        endTime: '05:15 PM',
        status: SessionStatus.upcoming,
        notes: 'Peer interaction probe during board game activity.',
      ),

      // Michael Chang sessions
      TherapySession(
        id: 'TS-205',
        therapistId: 'T2',
        therapistName: 'Michael Chang',
        studentId: 'S5',
        studentName: 'Romeo Alex A',
        studentAge: 15,
        programTitle: 'Differential Reinforcement & Task Completion',
        room: 'ABA Table 1 (DTT)',
        date: today,
        startTime: '09:00 AM',
        endTime: '10:15 AM',
        status: SessionStatus.inProgress,
        notes: 'DRA on token economy schedule: FR3 token delivery.',
      ),
      TherapySession(
        id: 'TS-206',
        therapistId: 'T2',
        therapistName: 'Michael Chang',
        studentId: 'S1',
        studentName: 'Alex Thomas Sam',
        studentAge: 15,
        programTitle: 'Intraverbal Fill-ins & Functional Questions',
        room: 'Speech & Language Cabin 1',
        date: today,
        startTime: '01:00 PM',
        endTime: '02:15 PM',
        status: SessionStatus.upcoming,
        notes: 'Intraverbal Level 3: Answers "What do you do when you are thirsty?".',
      ),

      // Emily Chen sessions (Speech)
      TherapySession(
        id: 'TS-207',
        therapistId: 'T3',
        therapistName: 'Emily Chen',
        studentId: 'S6',
        studentName: 'Sophia Martinez',
        studentAge: 9,
        programTitle: 'Early Echoic Skills & Vocal Articulation',
        room: 'Speech & Language Cabin 2',
        date: today,
        startTime: '09:00 AM',
        endTime: '10:15 AM',
        status: SessionStatus.inProgress,
        notes: 'Subtest 1 simple syllables /ba/, /ma/, /da/.',
      ),
      TherapySession(
        id: 'TS-208',
        therapistId: 'T3',
        therapistName: 'Emily Chen',
        studentId: 'S2',
        studentName: 'Jemi Wilson',
        studentAge: 15,
        programTitle: 'Oral Motor Function & Vocal Echoics',
        room: 'Speech & Language Cabin 2',
        date: today,
        startTime: '10:30 AM',
        endTime: '11:45 AM',
        status: SessionStatus.upcoming,
        notes: 'Vocal volume regulation in structured communication settings.',
      ),

      // David Kim sessions
      TherapySession(
        id: 'TS-209',
        therapistId: 'T4',
        therapistName: 'David Kim',
        studentId: 'S3',
        studentName: 'Cameron Williamson',
        studentAge: 12,
        programTitle: 'Fine Motor Imitation & Writing Grasp',
        room: 'Natural Environment Station 3',
        date: today,
        startTime: '09:00 AM',
        endTime: '10:15 AM',
        status: SessionStatus.completed,
        notes: 'Tripod grasp intervention on 10 pre-writing strokes.',
      ),
    ]);
  }

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
  bool scheduleDirectorAppointment(DirectorAppointment appointment) {
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

    _directorAppointments.add(appointment);
    notifyListeners();
    return true;
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
