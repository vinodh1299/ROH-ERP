import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/user_model.dart';

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final storage = ref.watch(secureStorageProvider);
    final userJson = await storage.read(key: 'auth_user');
    final token = await storage.read(key: 'auth_token');

    if (userJson != null && token != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(map);
      } catch (_) {
        await storage.delete(key: 'auth_user');
        await storage.delete(key: 'auth_token');
      }
    }
    return null;
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/api.php?action=login',
        data: {'email': email.trim(), 'password': password.trim()},
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['token'] != null) {
        final user = UserModel.fromJson(data);
        final storage = ref.read(secureStorageProvider);

        await storage.write(key: 'auth_token', value: data['token']);
        await storage.write(key: 'auth_user', value: jsonEncode(user.toJson()));

        state = AsyncValue.data(user);
        return true;
      } else {
        final err = data is Map ? data['error']?.toString() : 'Invalid credentials';
        state = AsyncValue.error(err ?? 'Login failed', StackTrace.current);
        return false;
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['error'] != null
          ? e.response?.data['error'].toString()
          : (e.message ?? 'Network error');
      state = AsyncValue.error(msg!, StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'auth_user');
    state = const AsyncValue.data(null);
  }
}
