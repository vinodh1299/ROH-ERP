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
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: _initialRoute(context),
      routes: {
        AppConstants.routeLogin: (_) => const LoginPage(),
        AppConstants.routeAdmin: (_) => const AdminShell(),
        AppConstants.routeDirector: (_) => const DirectorShell(),
        AppConstants.routeTherapist: (_) => const TherapistShell(),
        AppConstants.routeParent: (_) => ParentShell(initialTab: initialTab),
      },
    );
  }

  String _initialRoute(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isLoggedIn) return AppConstants.routeLogin;
    switch (auth.currentUser?.role) {
      case 'admin': return AppConstants.routeAdmin;
      case 'director': return AppConstants.routeDirector;
      case 'therapist': return AppConstants.routeTherapist;
      case 'parent': return AppConstants.routeParent;
      default: return AppConstants.routeLogin;
    }
  }
}
