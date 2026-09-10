// lib/core/models/schedule_model.dart

enum SessionStatus {
  upcoming,
  inProgress,
  completed,
  cancelled,
}

extension SessionStatusExt on SessionStatus {
  String get label {
    switch (this) {
      case SessionStatus.upcoming:
        return 'Upcoming';
      case SessionStatus.inProgress:
        return 'In Progress';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class TherapySession {
  final String id;
  final String therapistId;
  final String therapistName;
  final String studentId;
  final String studentName;
  final int studentAge;
  final String studentAvatar;
  final String programTitle; // e.g. "VB-MAPP Manding & Echoic Probes"
  final String room;         // e.g. "Sensory Room A", "Table 2", "Speech Cabin 1"
  final DateTime date;
  final String startTime;    // e.g. "09:00 AM"
  final String endTime;      // e.g. "10:15 AM"
  SessionStatus status;
  final String notes;

  TherapySession({
    required this.id,
    required this.therapistId,
    required this.therapistName,
    required this.studentId,
    required this.studentName,
    required this.studentAge,
    this.studentAvatar = '',
    required this.programTitle,
    required this.room,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = SessionStatus.upcoming,
    this.notes = '',
  });

  TherapySession copyWith({
    String? id,
    String? therapistId,
    String? therapistName,
    String? studentId,
    String? studentName,
    int? studentAge,
    String? studentAvatar,
    String? programTitle,
    String? room,
    DateTime? date,
    String? startTime,
    String? endTime,
    SessionStatus? status,
    String? notes,
  }) {
    return TherapySession(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      therapistName: therapistName ?? this.therapistName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentAge: studentAge ?? this.studentAge,
      studentAvatar: studentAvatar ?? this.studentAvatar,
      programTitle: programTitle ?? this.programTitle,
      room: room ?? this.room,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

enum AppointmentType {
  diagnosticIntake,
  iepReview,
  bacbSupervision,
  parentConference,
  staffConsultation,
}

extension AppointmentTypeExt on AppointmentType {
  String get label {
    switch (this) {
      case AppointmentType.diagnosticIntake:
        return 'Parent Diagnostic Intake';
      case AppointmentType.iepReview:
        return 'IEP Final Sign-Off Audit';
      case AppointmentType.bacbSupervision:
        return 'BACB 5% Clinical Supervision';
      case AppointmentType.parentConference:
        return 'Parent Progress Conference';
      case AppointmentType.staffConsultation:
        return 'Clinical Staff Case Review';
    }
  }

  String get shortTag {
    switch (this) {
      case AppointmentType.diagnosticIntake:
        return 'Intake';
      case AppointmentType.iepReview:
        return 'IEP Audit';
      case AppointmentType.bacbSupervision:
        return 'BACB';
      case AppointmentType.parentConference:
        return 'Parent Conf';
      case AppointmentType.staffConsultation:
        return 'Staff Review';
    }
  }
}

enum AppointmentStatus {
  confirmed,
  tentative,
  completed,
  cancelled,
}

class DirectorAppointment {
  final String id;
  final String title;
  final AppointmentType type;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String attendeeName;  // e.g. "Mr. John Wilson (Father of Jemi)"
  final String attendeeRole;  // e.g. "Parent", "BCBA Trainee", "External Consultant"
  final String attendeePhone;
  final String attendeeEmail;
  final String location;      // "Director Office Suite" or "Zoom Video Conference"
  final String scheduledBy;   // "Admin", "Director"
  AppointmentStatus status;
  final String notes;

  DirectorAppointment({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.attendeeName,
    this.attendeeRole = 'Parent',
    this.attendeePhone = '',
    this.attendeeEmail = '',
    this.location = 'Director Office Suite',
    this.scheduledBy = 'Admin',
    this.status = AppointmentStatus.confirmed,
    this.notes = '',
  });

  DirectorAppointment copyWith({
    String? id,
    String? title,
    AppointmentType? type,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? attendeeName,
    String? attendeeRole,
    String? attendeePhone,
    String? attendeeEmail,
    String? location,
    String? scheduledBy,
    AppointmentStatus? status,
    String? notes,
  }) {
    return DirectorAppointment(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      attendeeName: attendeeName ?? this.attendeeName,
      attendeeRole: attendeeRole ?? this.attendeeRole,
      attendeePhone: attendeePhone ?? this.attendeePhone,
      attendeeEmail: attendeeEmail ?? this.attendeeEmail,
      location: location ?? this.location,
      scheduledBy: scheduledBy ?? this.scheduledBy,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
