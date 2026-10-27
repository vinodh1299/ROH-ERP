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
import 'core/widgets/in_app_notification_banner.dart';
import 'core/widgets/first_launch_permissions_gate.dart';
import 'core/widgets/notification_center_drawer.dart';
import 'core/services/notification_service.dart';
import 'core/services/system_notifications.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Dotenv load skipped: $e');
  }
  final authService = AuthService();
  await authService.loadSession();

  // Clicking an OS notification brings the app forward (see
  // SystemNotifications) and opens the notification drawer.
  SystemNotifications.onTap = () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = RohApp.navigatorKey.currentContext;
      if (ctx == null || !authService.isLoggedIn) return;
      NotificationService().fetchNotifications(silent: true);
      NotificationCenterDrawer.show(ctx);
    });
    WidgetsBinding.instance.scheduleFrame();
  };
  await SystemNotifications.init();

  // An expired or revoked session (a 401 mid-use, or a failed token refresh)
  // has already been signed out locally by AuthService; take the user to the
  // login screen and say why.
  authService.onSessionExpired = () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RohApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppConstants.routeLogin,
        (route) => false,
      );
      RohApp.showSessionExpiredMessage();
    });
    WidgetsBinding.instance.scheduleFrame();
  };
  if (authService.expiredAtStartup) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => RohApp.showSessionExpiredMessage(),
    );
  }

  int initialTab = 0;
  for (final arg in args) {
    if (arg.startsWith('--tab=')) {
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
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showSessionExpiredMessage() {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please sign in again.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 6),
        ),
      );
  }

  final int initialTab;
  const RohApp({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: messengerKey,
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: _getInitialRoute(auth),
          builder: (context, child) => FirstLaunchPermissionsGate(
            child: InAppNotificationOverlay(
              child: child ?? const SizedBox(),
            ),
          ),
          // Exactly one starting route. Flutter's default would also push "/"
          // under e.g. "/therapist", and "/" builds the role shell for a
          // signed-in user, so every portal ran twice (duplicate polling,
          // dialogs, and a hidden copy consuming "open this student" requests).
          onGenerateInitialRoutes: (initialRoute) => [
            _generateGuardedRoute(
                context, auth, RouteSettings(name: initialRoute)),
          ],
          onGenerateRoute: (settings) =>
              _generateGuardedRoute(context, auth, settings),
          onUnknownRoute: (settings) =>
              _generateGuardedRoute(context, auth, settings),
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

    debugPrint(
        '🛡️ ROUTE GUARD: Navigation request to "$cleanRoute" | LoggedIn: ${auth.isLoggedIn} | Current Role: ${auth.currentUser?.role}');

    // 1. Handling the Login route
    if (cleanRoute == AppConstants.routeLogin || cleanRoute == '/') {
      if (auth.isLoggedIn) {
        final authorizedHome = _roleHome(auth.currentUser?.role);
        debugPrint(
            '🛡️ ROUTE GUARD: User already authenticated as ${auth.currentUser?.role}. Redirecting to $authorizedHome.');
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
      debugPrint(
          '🚨 ROUTE GUARD DENIED: Unauthenticated access attempt to "$cleanRoute". Redirecting to /login.');
      return MaterialPageRoute(
        settings: const RouteSettings(name: AppConstants.routeLogin),
        builder: (_) => const LoginPage(),
      );
    }

    // 3. Authenticated: Role-Based Access Control (RBAC) check
    final userRole = auth.currentUser?.role.toLowerCase() ?? '';
    final requiredRole = _requiredRoleForRoute(cleanRoute);

    if (requiredRole != null && userRole != requiredRole) {
      debugPrint(
          '🚨 ROUTE GUARD DENIED: Role mismatch! User is "$userRole", but "$cleanRoute" requires "$requiredRole". Redirecting to authorized home.');
      final authorizedHome = _roleHome(userRole);
      return MaterialPageRoute(
        settings: RouteSettings(name: authorizedHome),
        builder: (_) => _buildRoleShell(userRole),
      );
    }

    // 4. Authorized access: return the appropriate shell
    final tabParam =
        int.tryParse(Uri.tryParse(rawName)?.queryParameters['tab'] ?? '');
    final tab = tabParam ?? initialTab;

    switch (cleanRoute) {
      case AppConstants.routeAdmin:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AdminShell(initialTab: tab),
        );
      case AppConstants.routeDirector:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DirectorShell(initialTab: tab),
        );
      case AppConstants.routeTherapist:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TherapistShell(initialTab: tab),
        );
      case AppConstants.routeParent:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ParentShell(initialTab: tab),
        );
      default:
        final fallback =
            auth.isLoggedIn ? _roleHome(userRole) : AppConstants.routeLogin;
        return MaterialPageRoute(
          settings: RouteSettings(name: fallback),
          builder: (_) => auth.isLoggedIn
              ? _buildRoleShell(userRole, tab)
              : const LoginPage(),
        );
    }
  }

  Widget _buildRoleShell(String? role, [int tab = 0]) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return AdminShell(initialTab: tab);
      case 'director':
        return DirectorShell(initialTab: tab);
      case 'therapist':
        return TherapistShell(initialTab: tab);
      case 'parent':
        return ParentShell(initialTab: tab);
      default:
        return const LoginPage();
    }
  }
}
