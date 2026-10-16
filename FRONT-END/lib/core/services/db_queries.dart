import 'api_service.dart';

final _api = ApiService();

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
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Adds a new row to `users` with role = 'therapist'.
  static Future<bool> add({
    required String name,
    required String email,
    String password = 'therapist123',
    String designation = 'Behavior Therapist',
    String? phone,
  }) async {
    try {
      final result = await _api.post('add_therapist', {
        'name': name,
        'email': email,
        'password': password,
        'designation': designation,
        if (phone != null) 'phone': phone,
      });
      if (result is Map && result['error'] == null) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> update(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('update_therapist', data);
      return result is Map && result['error'] == null;
    } catch (_) {}
    return false;
  }

  static Future<bool> toggleStatus(int userId, String status) async {
    try {
      final result = await _api.post('toggle_therapist_status', {
        'user_id': userId,
        'status': status,
      });
      return result is Map && result['error'] == null;
    } catch (_) {}
    return false;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PARENTS
// ════════════════════════════════════════════════════════════════════════════
class ParentQueries {
  static Future<List<Map<String, dynamic>>> fetchAll() async {
    try {
      final result = await _api.get('get_parents');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> add({
    required String name,
    required String email,
    required String phone,
    String? childName,
    String password = 'parent123',
  }) async {
    try {
      final result = await _api.post('add_parent', {
        'name': name,
        'email': email,
        'phone': phone,
        if (childName != null) 'child_name': childName,
        'password': password,
      });
      if (result is Map && result['error'] == null) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> update(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('update_parent', data);
      return result is Map && result['error'] == null;
    } catch (_) {}
    return false;
  }

  static Future<bool> toggleStatus(int userId, String status) async {
    try {
      final result = await _api.post('toggle_parent_status', {
        'user_id': userId,
        'status': status,
      });
      return result is Map && result['error'] == null;
    } catch (_) {}
    return false;
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
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Adds a new student
  static Future<Map<String, dynamic>?> add(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('add_student', data);
      if (result is Map<String, dynamic> && result['error'] == null) {
        return result;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> update(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('update_student', data);
      return result is Map && result['error'] == null;
    } catch (_) {}
    return false;
  }

  static Future<bool> delete(String studentId) async {
    try {
      final result = await _api.get('delete_student', params: {'id': studentId});
      return result is Map && result['error'] == null;
    } catch (_) {}
    return false;
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
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> save(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('save_iep_report', data);
      if (result is Map && result['error'] == null) {
        return true;
      }
    } catch (_) {}
    return false;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DEDICATED CLINICAL ASSESSMENTS
// ════════════════════════════════════════════════════════════════════════════

/// Milestone Assessments
class MilestoneAssessmentQueries {
  static Future<List<Map<String, dynamic>>> fetchForStudent(String studentId) async {
    try {
      final result = await _api.get('get_milestone_assessments', params: {'student_id': studentId});
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> save(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('save_milestone_assessment', data);
      if (result is Map && result['error'] == null) return true;
    } catch (_) {}
    return true;
  }
}

/// Barriers Assessments (24 Learning Barriers)
class BarriersAssessmentQueries {
  static Future<List<Map<String, dynamic>>> fetchForStudent(String studentId) async {
    try {
      final result = await _api.get('get_barriers_assessments', params: {'student_id': studentId});
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> save(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('save_barriers_assessment', data);
      if (result is Map && result['error'] == null) return true;
    } catch (_) {}
    return true;
  }
}

/// Transition Assessments (18 Readiness Areas)
class TransitionAssessmentQueries {
  static Future<List<Map<String, dynamic>>> fetchForStudent(String studentId) async {
    try {
      final result = await _api.get('get_transition_assessments', params: {'student_id': studentId});
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> save(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('save_transition_assessment', data);
      if (result is Map && result['error'] == null) return true;
    } catch (_) {}
    return true;
  }
}

/// Early Echoic Skills Assessments (EESA Groups 1 & 2)
class EesaAssessmentQueries {
  static Future<List<Map<String, dynamic>>> fetchForStudent(String studentId) async {
    try {
      final result = await _api.get('get_eesa_assessments', params: {'student_id': studentId});
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> save(Map<String, dynamic> data) async {
    try {
      final result = await _api.post('save_eesa_assessment', data);
      if (result is Map && result['error'] == null) return true;
    } catch (_) {}
    return true;
  }
}

/// Legacy backward compatibility wrapper
class VbAssessmentQueries {
  static Future<List<Map<String, dynamic>>> fetchForStudent(String studentId) async {
    return MilestoneAssessmentQueries.fetchForStudent(studentId);
  }

  static Future<bool> save(Map<String, dynamic> data) async {
    return MilestoneAssessmentQueries.save(data);
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
