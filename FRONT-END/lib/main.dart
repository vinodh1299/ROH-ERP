import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/services/schedule_service.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_page.dart';
import 'features/admin/admin_shell.dart';
import 'features/director/director_shell.dart';
import 'features/therapist/therapist_shell.dart';
import 'features/parent/parent_shell.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Dotenv load skipped: $e');
  }
  final authService = AuthService();
  await authService.loadSession();

  int initialTab = 0;
  for (final arg in args) {
    if (arg.startsWith('--role=')) {
      final role = arg.split('=')[1].trim().toLowerCase();
      if (role == 'admin') {
        await authService.login(AppConstants.adminEmail, AppConstants.adminPassword);
      } else if (role == 'director') {
        await authService.login(AppConstants.directorEmail, AppConstants.directorPassword);
      } else if (role == 'therapist') {
        await authService.login(AppConstants.therapistEmail, AppConstants.therapistPassword);
      } else if (role == 'parent') {
        await authService.login(AppConstants.parentEmail, AppConstants.parentPassword);
      }
    } else if (arg.startsWith('--tab=')) {
      initialTab = int.tryParse(arg.split('=')[1].trim()) ?? 0;
    }
  }

  final scheduleService = ScheduleService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<ScheduleService>.value(value: scheduleService),
      ],
      child: RohApp(initialTab: initialTab),
    ),
  );
}

class RohApp extends StatelessWidget {
  final int initialTab;
  const RohApp({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: _getInitialRoute(auth),
          onGenerateRoute: (settings) => _generateGuardedRoute(context, auth, settings),
          onUnknownRoute: (settings) => _generateGuardedRoute(context, auth, settings),
        );
      },
    );
  }

  String _getInitialRoute(AuthService auth) {
    if (!auth.isLoggedIn) return AppConstants.routeLogin;
    return _roleHome(auth.currentUser?.role);
  }

  static String _roleHome(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return AppConstants.routeAdmin;
      case 'director':
        return AppConstants.routeDirector;
      case 'therapist':
        return AppConstants.routeTherapist;
      case 'parent':
        return AppConstants.routeParent;
      default:
        return AppConstants.routeLogin;
    }
  }

  static String? _requiredRoleForRoute(String route) {
    if (route == AppConstants.routeAdmin) return 'admin';
    if (route == AppConstants.routeDirector) return 'director';
    if (route == AppConstants.routeTherapist) return 'therapist';
    if (route == AppConstants.routeParent) return 'parent';
    return null;
  }

  Route<dynamic> _generateGuardedRoute(
    BuildContext context,
    AuthService auth,
    RouteSettings settings,
  ) {
    final rawName = settings.name ?? AppConstants.routeLogin;
    final cleanRoute = rawName.split('?').first;

    debugPrint('🛡️ ROUTE GUARD: Navigation request to "$cleanRoute" | LoggedIn: ${auth.isLoggedIn} | Current Role: ${auth.currentUser?.role}');

    // 1. Handling the Login route
    if (cleanRoute == AppConstants.routeLogin || cleanRoute == '/') {
      if (auth.isLoggedIn) {
        final authorizedHome = _roleHome(auth.currentUser?.role);
        debugPrint('🛡️ ROUTE GUARD: User already authenticated as ${auth.currentUser?.role}. Redirecting to $authorizedHome.');
        return MaterialPageRoute(
          settings: RouteSettings(name: authorizedHome),
          builder: (_) => _buildRoleShell(auth.currentUser?.role),
        );
      }
      return MaterialPageRoute(
        settings: const RouteSettings(name: AppConstants.routeLogin),
        builder: (_) => const LoginPage(),
      );
    }

    // 2. Unauthenticated check: Block any protected route if not logged in
    if (!auth.isLoggedIn) {
      debugPrint('🚨 ROUTE GUARD DENIED: Unauthenticated access attempt to "$cleanRoute". Redirecting to /login.');
      return MaterialPageRoute(
        settings: const RouteSettings(name: AppConstants.routeLogin),
        builder: (_) => const LoginPage(),
      );
    }

    // 3. Authenticated: Role-Based Access Control (RBAC) check
    final userRole = auth.currentUser?.role.toLowerCase() ?? '';
    final requiredRole = _requiredRoleForRoute(cleanRoute);

    if (requiredRole != null && userRole != requiredRole) {
      debugPrint('🚨 ROUTE GUARD DENIED: Role mismatch! User is "$userRole", but "$cleanRoute" requires "$requiredRole". Redirecting to authorized home.');
      final authorizedHome = _roleHome(userRole);
      return MaterialPageRoute(
        settings: RouteSettings(name: authorizedHome),
        builder: (_) => _buildRoleShell(userRole),
      );
    }

    // 4. Authorized access: return the appropriate shell
    switch (cleanRoute) {
      case AppConstants.routeAdmin:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminShell(),
        );
      case AppConstants.routeDirector:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DirectorShell(),
        );
      case AppConstants.routeTherapist:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TherapistShell(),
        );
      case AppConstants.routeParent:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ParentShell(initialTab: initialTab),
        );
      default:
        final fallback = auth.isLoggedIn ? _roleHome(userRole) : AppConstants.routeLogin;
        return MaterialPageRoute(
          settings: RouteSettings(name: fallback),
          builder: (_) => auth.isLoggedIn ? _buildRoleShell(userRole) : const LoginPage(),
        );
    }
  }

  Widget _buildRoleShell(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return const AdminShell();
      case 'director':
        return const DirectorShell();
      case 'therapist':
        return const TherapistShell();
      case 'parent':
        return ParentShell(initialTab: initialTab);
      default:
        return const LoginPage();
    }
  }
}
