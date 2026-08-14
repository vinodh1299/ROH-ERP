import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_page.dart';
import 'features/admin/admin_shell.dart';
import 'features/director/director_shell.dart';
import 'features/therapist/therapist_shell.dart';
import 'features/parent/parent_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('Dotenv load skipped: $e');
    }
  }
  final authService = AuthService();
  await authService.loadSession();
  runApp(
    ChangeNotifierProvider<AuthService>.value(
      value: authService,
      child: const RohApp(),
    ),
  );
}

class RohApp extends StatelessWidget {
  const RohApp({super.key});

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
        AppConstants.routeParent: (_) => const ParentShell(),
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
