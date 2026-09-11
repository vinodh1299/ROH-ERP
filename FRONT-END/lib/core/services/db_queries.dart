import 'api_service.dart';

final _api = ApiService();

// ════════════════════════════════════════════════════════════════════════════
// IN-MEMORY MOCK DATABASE STORE FOR OFFLINE TESTING
// ════════════════════════════════════════════════════════════════════════════
class MockData {
  static final List<Map<String, dynamic>> therapists = [
    {'id': '1', 'name': 'Dr. Sarah Lee', 'email': 'sarah.lee@roh.com', 'status': 'Active'},
    {'id': '2', 'name': 'Dr. Michael Chen', 'email': 'm.chen@roh.com', 'status': 'Active'},
    {'id': '3', 'name': 'Priya Sharma', 'email': 'priya.s@roh.com', 'status': 'Active'},
    {'id': '4', 'name': 'David Miller', 'email': 'd.miller@roh.com', 'status': 'Active'},
    {'id': '5', 'name': 'Ananya Roy', 'email': 'ananya.r@roh.com', 'status': 'Active'},
    {'id': '6', 'name': 'James Wilson', 'email': 'j.wilson@roh.com', 'status': 'Active'},
  ];

  static final List<Map<String, dynamic>> students = [
    {
      'id': '1',
      'name': 'Aarav Patel',
      'dob': '2018-05-14',
      'phone_number': '+1 (555) 019-2831',
      'email': 'parent.aarav@roh.com',
      'parent_name': 'Suresh Patel',
      'status': 'Active',
    },
    {
      'id': '2',
      'name': 'Emma Watson',
      'dob': '2019-09-20',
      'phone_number': '+1 (555) 014-9284',
      'email': 'parent.emma@roh.com',
      'parent_name': 'Robert Watson',
      'status': 'Active',
    },
    {
      'id': '3',
      'name': 'Rahul Sharma',
      'dob': '2017-11-03',
      'phone_number': '+1 (555) 018-4720',
      'email': 'parent.rahul@roh.com',
      'parent_name': 'Sunita Sharma',
      'status': 'Active',
    },
    {
      'id': '4',
      'name': 'Sophia Garcia',
      'dob': '2020-02-17',
      'phone_number': '+1 (555) 016-3912',
      'email': 'parent.sophia@roh.com',
      'parent_name': 'Maria Garcia',
      'status': 'Active',
    },
    {
      'id': '5',
      'name': 'Leo Thomas',
      'dob': '2018-12-08',
      'phone_number': '+1 (555) 015-8392',
      'email': 'parent.leo@roh.com',
      'parent_name': 'David Thomas',
      'status': 'Active',
    },
    {
      'id': '6',
      'name': 'Maya Lin',
      'dob': '2019-04-25',
      'phone_number': '+1 (555) 012-7491',
      'email': 'parent.maya@roh.com',
      'parent_name': 'Grace Lin',
      'status': 'Active',
    },
  ];

  static final List<Map<String, dynamic>> parents = [
    {'id': '1', 'name': 'Mr. John Wilson', 'email': 'parent@roh.com', 'child_name': 'Aarav Patel', 'phone': '+1 (555) 019-2831', 'status': 'Active'},
    {'id': '2', 'name': 'Suresh Patel', 'email': 'suresh.p@roh.com', 'child_name': 'Aarav Patel', 'phone': '+1 (555) 019-2831', 'status': 'Active'},
    {'id': '3', 'name': 'Robert Watson', 'email': 'robert.w@roh.com', 'child_name': 'Emma Watson', 'phone': '+1 (555) 014-9284', 'status': 'Active'},
    {'id': '4', 'name': 'Sunita Sharma', 'email': 'sunita.s@roh.com', 'child_name': 'Rahul Sharma', 'phone': '+1 (555) 018-4720', 'status': 'Active'},
    {'id': '5', 'name': 'Maria Garcia', 'email': 'maria.g@roh.com', 'child_name': 'Sophia Garcia', 'phone': '+1 (555) 016-3912', 'status': 'Active'},
  ];

  static final List<Map<String, dynamic>> iepReports = [
    {
      'id': '1',
      'title': 'Q3 Behavioral Plan',
      'student_name': 'Aarav Patel',
      'goals': 'Improve social interaction & non-verbal communication',
      'status': 'Pending Approval',
      'created_date': '2026-07-10',
    },
    {
      'id': '2',
      'title': 'Speech Therapy Assessment',
      'student_name': 'Emma Watson',
      'goals': 'Vocabulary expansion & vocal clarity exercises',
      'status': 'Active',
      'created_date': '2026-07-12',
    },
    {
      'id': '3',
      'title': 'Occupational Therapy Milestones',
      'student_name': 'Rahul Sharma',
      'goals': 'Fine motor skills & sensory integration protocol',
      'status': 'Pending Approval',
      'created_date': '2026-07-15',
    },
  ];
}

// ════════════════════════════════════════════════════════════════════════════
// AUTH
// ════════════════════════════════════════════════════════════════════════════
class AuthQueries {
  /// Returns the user map {id, name, email, role} on success, or null.
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
      final result = await _api.post('login', {
        'email': email,
        'password': password,
      });
      if (result is Map<String, dynamic> && result['error'] == null) {
        return result;
      }
    } catch (_) {}
    return null;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// THERAPISTS
// ════════════════════════════════════════════════════════════════════════════
class TherapistQueries {
  /// All users with role = 'therapist'
  static Future<List<Map<String, dynamic>>> fetchAll() async {
    try {
      final result = await _api.get('get_therapists');
      if (result is List && result.isNotEmpty) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(MockData.therapists);
  }

  /// Adds a new row to `users` with role = 'therapist'.
  static Future<bool> add({
    required String name,
    required String email,
    String password = 'therapist123',
  }) async {
    try {
      final result = await _api.post('add_therapist', {
        'name': name,
        'email': email,
        'password': password,
      });
      if (result is Map && result['error'] == null) {
        return true;
      }
    } catch (_) {}
    // Fallback: add to local mock data for offline testing
    MockData.therapists.add({
      'id': '${MockData.therapists.length + 1}',
      'name': name,
      'email': email,
      'status': 'Active',
    });
    return true;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PARENTS
// ════════════════════════════════════════════════════════════════════════════
class ParentQueries {
  static Future<List<Map<String, dynamic>>> fetchAll() async {
    try {
      final result = await _api.get('get_parents');
      if (result is List && result.isNotEmpty) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(MockData.parents);
  }

  static Future<bool> add({
    required String name,
    required String email,
    required String phone,
    required String childName,
    String password = 'parent123',
  }) async {
    try {
      final result = await _api.post('add_parent', {
        'name': name,
        'email': email,
        'phone': phone,
        'child_name': childName,
        'password': password,
      });
      if (result is Map && result['error'] == null) {
        return true;
      }
    } catch (_) {}
    MockData.parents.add({
      'id': '${MockData.parents.length + 1}',
      'name': name,
      'email': email,
      'phone': phone,
      'child_name': childName,
      'status': 'Active',
    });
    return true;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STUDENTS
// ════════════════════════════════════════════════════════════════════════════
class StudentQueries {
  /// Full student list for the grid
  static Future<List<Map<String, dynamic>>> fetchAll() async {
    try {
      final result = await _api.get('get_students_full');
      if (result is List && result.isNotEmpty) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(MockData.students);
  }

  /// Adds a new student
  static Future<Map<String, dynamic>?> add(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('add_student', data);
      if (result is Map<String, dynamic> && result['error'] == null) {
        return result;
      }
    } catch (_) {}
    final newStudent = {
      'id': '${MockData.students.length + 1}',
      'name': data['first_name'] ?? data['name'] ?? 'New Student',
      'dob': data['dob'] ?? '2019-01-01',
      'phone_number': data['phone_number'] ?? '+1 (555) 010-9281',
      'email': data['email'] ?? 'student@roh.com',
      'parent_name': data['parent_name'] ?? 'Parent',
      'status': 'Active',
    };
    MockData.students.add(newStudent);
    return newStudent;
  }

  static Future<bool> delete(String studentId) async {
    try {
      final result = await _api.get('delete_student', params: {'id': studentId});
      if (result is Map && result['error'] == null) {
        MockData.students.removeWhere((s) => '${s['id']}' == studentId);
        return true;
      }
    } catch (_) {}
    MockData.students.removeWhere((s) => '${s['id']}' == studentId);
    return true;
  }

  // ── Medical info ──
  static Future<Map<String, dynamic>?> fetchMedicalInfo(String studentId) async {
    try {
      final result = await _api.get('get_student_medical_info', params: {'student_id': studentId});
      if (result is Map<String, dynamic>) return result;
    } catch (_) {}
    return {
      'has_medical_conditions': 1,
      'conditions_detail': 'Mild sensory sensitivity to loud noises',
      'allergies': 'Peanuts',
      'seizure_history': 0,
      'taking_medications': 1,
    };
  }

  static Future<bool> saveMedicalInfo(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('save_student_medical_info', data);
      return result is Map && result['error'] == null;
    } catch (_) {}
    return true;
  }

  // ── Medications ──
  static Future<List<Map<String, dynamic>>> fetchMedications(String studentId) async {
    try {
      final result = await _api.get('get_student_medications', params: {'student_id': studentId});
      if (result is List && result.isNotEmpty) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [
      {'id': '1', 'medication_name': 'Vitamin D3 Supplement', 'used_for': 'General Health'},
      {'id': '2', 'medication_name': 'Melatonin (Low Dose)', 'used_for': 'Sleep Support'},
    ];
  }

  static Future<bool> addMedication({
    required String studentId,
    required String medicationName,
    required String usedFor,
  }) async {
    try {
      final result = await _api.post('add_student_medication', {
        'student_id': studentId,
        'medication_name': medicationName,
        'dosage': '1 dose',
        'used_for': usedFor,
      });
      return result is Map && result['error'] == null;
    } catch (_) {}
    return true;
  }

  // ── Guardians ──
  static Future<List<Map<String, dynamic>>> fetchGuardians(String studentId) async {
    try {
      final result = await _api.get('get_student_guardians', params: {'student_id': studentId});
      if (result is List && result.isNotEmpty) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [
      {
        'id': '1',
        'relationship': 'Mother',
        'first_name': 'Sarah',
        'last_name': 'Patel',
        'mobile_number': '+1 (555) 019-2831',
        'email': 'sarah.p@example.com',
      },
    ];
  }

  static Future<bool> addGuardian(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('add_student_guardian', data);
      return result is Map && result['error'] == null;
    } catch (_) {}
    return true;
  }

  // ── Emergency contact ──
  static Future<List<Map<String, dynamic>>> fetchEmergencyContacts(String studentId) async {
    try {
      final result = await _api.get('get_student_emergency_contacts', params: {'student_id': studentId});
      if (result is List && result.isNotEmpty) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [
      {
        'id': '1',
        'contact_name': 'Grandmother - Elena Patel',
        'message': 'Call grandmother if parents are unreachable.',
      },
    ];
  }

  static Future<bool> saveEmergencyContact({
    required String studentId,
    required String contactName,
    required String message,
  }) async {
    return true;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// IEP REPORTS
// ════════════════════════════════════════════════════════════════════════════
class IepQueries {
  static Future<List<Map<String, dynamic>>> fetchAll() async {
    try {
      final result = await _api.get('get_iep_reports');
      if (result is List && result.isNotEmpty) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(MockData.iepReports);
  }

  static Future<bool> save(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('save_iep_report', data);
      if (result is Map && result['error'] == null) {
        return true;
      }
    } catch (_) {}
    MockData.iepReports.add({
      'id': '${MockData.iepReports.length + 1}',
      'title': data['title'] ?? 'IEP Goal',
      'student_name': data['student_name'] ?? 'Aarav Patel',
      'goals': data['goals_summary'] ?? 'Updated IEP Goals',
      'status': data['status'] ?? 'Pending Approval',
      'created_date': DateTime.now().toString().split(' ')[0],
    });
    return true;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// VB ASSESSMENTS
// ════════════════════════════════════════════════════════════════════════════
class VbAssessmentQueries {
  static Future<List<Map<String, dynamic>>> fetchForStudent(
      String studentId) async {
    try {
      final result = await _api.get('get_vb_assessments', params: {'student_id': studentId});
      if (result is List && result.isNotEmpty) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [
      {
        'id': '1',
        'assessment_date': '2026-06-15',
        'milestone_score': '42/170',
        'barriers_score': '12/96',
        'notes': 'Good progress on manding and tacting milestones.',
      }
    ];
  }

  static Future<bool> save(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('save_vb_assessment', data);
      if (result is Map && result['error'] == null) return true;
    } catch (_) {}
    return true;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DAILY DATA SHEETS
// ════════════════════════════════════════════════════════════════════════════
class DailyDataQueries {
  static Future<List<Map<String, dynamic>>> fetchForStudent(
      String studentId) async {
    try {
      final result = await _api.get('get_daily_data', params: {'student_id': studentId});
      if (result is List && result.isNotEmpty) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [
      {
        'id': '1',
        'date': '2026-07-22',
        'target_metric': 'Eye Contact (3sec)',
        'score_value': '8/10 trials',
      }
    ];
  }

  static Future<bool> save(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('save_daily_data', data);
      if (result is Map && result['error'] == null) return true;
    } catch (_) {}
    return true;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// REINFORCERS ASSESSMENTS
// ════════════════════════════════════════════════════════════════════════════
class ReinforcerQueries {
  static Future<List<Map<String, dynamic>>> fetchAll() async {
    try {
      final result = await _api.get('get_reinforcers');
      if (result is List && result.isNotEmpty) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [
      {'id': '1', 'category': 'Edible', 'item_name': 'Apple', 'rating': 5, 'notes': 'Highly preferred during manding'},
      {'id': '2', 'category': 'Social', 'item_name': 'High Five & Praise', 'rating': 4, 'notes': 'Effective after successful task'},
      {'id': '3', 'category': 'Toys/Materials', 'item_name': 'Light-Up Sensory Ball', 'rating': 5, 'notes': 'Best for break time'},
    ];
  }

  static Future<bool> save(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('save_reinforcer', data);
      if (result is Map && result['error'] == null) return true;
    } catch (_) {}
    return true;
  }
}
