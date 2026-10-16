import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

// ─── REPOSITORIES ─────────────────────────────────────────────────────────────

class MilestoneRepository {
  final Dio _dio;
  MilestoneRepository(this._dio);

  Future<List<Map<String, dynamic>>> getAssessments(int studentId) async {
    final res = await _dio.get('/api.php?action=get_milestone_assessments', queryParameters: {'student_id': studentId});
    if (res.data is List) {
      return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<bool> saveAssessment(Map<String, dynamic> data) async {
    final res = await _dio.post('/api.php?action=save_milestone_assessment', data: data);
    return res.data is Map && res.data['success'] == true;
  }
}

class BarriersRepository {
  final Dio _dio;
  BarriersRepository(this._dio);

  Future<List<Map<String, dynamic>>> getAssessments(int studentId) async {
    final res = await _dio.get('/api.php?action=get_barriers_assessments', queryParameters: {'student_id': studentId});
    if (res.data is List) {
      return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<bool> saveAssessment(Map<String, dynamic> data) async {
    final res = await _dio.post('/api.php?action=save_barriers_assessment', data: data);
    return res.data is Map && res.data['success'] == true;
  }
}

class TransitionRepository {
  final Dio _dio;
  TransitionRepository(this._dio);

  Future<List<Map<String, dynamic>>> getAssessments(int studentId) async {
    final res = await _dio.get('/api.php?action=get_transition_assessments', queryParameters: {'student_id': studentId});
    if (res.data is List) {
      return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<bool> saveAssessment(Map<String, dynamic> data) async {
    final res = await _dio.post('/api.php?action=save_transition_assessment', data: data);
    return res.data is Map && res.data['success'] == true;
  }
}

class EesaRepository {
  final Dio _dio;
  EesaRepository(this._dio);

  Future<List<Map<String, dynamic>>> getAssessments(int studentId) async {
    final res = await _dio.get('/api.php?action=get_eesa_assessments', queryParameters: {'student_id': studentId});
    if (res.data is List) {
      return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<bool> saveAssessment(Map<String, dynamic> data) async {
    final res = await _dio.post('/api.php?action=save_eesa_assessment', data: data);
    return res.data is Map && res.data['success'] == true;
  }
}

// ─── RIVERPOD PROVIDERS ───────────────────────────────────────────────────────

final milestoneRepoProvider = Provider<MilestoneRepository>((ref) {
  return MilestoneRepository(ref.watch(dioProvider));
});

final barriersRepoProvider = Provider<BarriersRepository>((ref) {
  return BarriersRepository(ref.watch(dioProvider));
});

final transitionRepoProvider = Provider<TransitionRepository>((ref) {
  return TransitionRepository(ref.watch(dioProvider));
});

final eesaRepoProvider = Provider<EesaRepository>((ref) {
  return EesaRepository(ref.watch(dioProvider));
});

// Auto-dispose family providers for dynamic reactive UI
final studentMilestonesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, studentId) async {
  return ref.watch(milestoneRepoProvider).getAssessments(studentId);
});

final studentBarriersProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, studentId) async {
  return ref.watch(barriersRepoProvider).getAssessments(studentId);
});

final studentTransitionsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, studentId) async {
  return ref.watch(transitionRepoProvider).getAssessments(studentId);
});

final studentEesaProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, studentId) async {
  return ref.watch(eesaRepoProvider).getAssessments(studentId);
});
