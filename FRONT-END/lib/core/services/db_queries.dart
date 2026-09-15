import 'api_service.dart';

final _api = ApiService();

// ════════════════════════════════════════════════════════════════════════════
// IN-MEMORY MOCK DATABASE STORE FOR OFFLINE TESTING
// ════════════════════════════════════════════════════════════════════════════
class MockData {
  static final List<Map<String, dynamic>> therapists = [];
  static final List<Map<String, dynamic>> students = [];
  static final List<Map<String, dynamic>> parents = [];
  static final List<Map<String, dynamic>> iepReports = [];
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
      if (result is List) {
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
      if (result is List) {
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
    return null;
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
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
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
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
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
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
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
      if (result is List) {
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
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
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
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
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
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> save(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('save_reinforcer', data);
      if (result is Map && result['error'] == null) return true;
    } catch (_) {}
    return true;
  }
}
