import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/login_page.dart';
import '../../features/admin/admin_shell.dart';
import '../../features/director/director_shell.dart';
import '../../features/therapist/therapist_shell.dart';
import '../../features/parent/parent_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;
      final isLoggingIn = state.matchedLocation == '/login';

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      // User is authenticated
      if (isLoggingIn) {
        switch (user.role) {
          case 'admin':
            return '/admin';
          case 'director':
            return '/director';
          case 'therapist':
            return '/therapist';
          case 'parent':
            return '/parent';
          default:
            return '/login';
        }
      }

      // Role-based protection guards
      if (state.matchedLocation.startsWith('/admin') && user.role != 'admin') {
        return '/${user.role}';
      }
      if (state.matchedLocation.startsWith('/director') && user.role != 'director') {
        return '/${user.role}';
      }
      if (state.matchedLocation.startsWith('/therapist') && user.role != 'therapist') {
        return '/${user.role}';
      }
      if (state.matchedLocation.startsWith('/parent') && user.role != 'parent') {
        return '/${user.role}';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminShell(),
      ),
      GoRoute(
        path: '/director',
        builder: (context, state) => const DirectorShell(),
      ),
      GoRoute(
        path: '/therapist',
        builder: (context, state) => const TherapistShell(),
      ),
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentShell(),
      ),
    ],
  );
});
