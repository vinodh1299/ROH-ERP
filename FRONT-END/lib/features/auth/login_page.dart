// lib/features/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roh_erp/core/constants/app_colors.dart';
import 'package:roh_erp/core/constants/app_constants.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMsg = null);

    final auth = context.read<AuthService>();
    final role = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;

    if (role == null) {
      setState(() => _errorMsg = 'Invalid email or password. Please try again.');
      return;
    }

    switch (role) {
      case 'admin':
        Navigator.of(context).pushReplacementNamed(AppConstants.routeAdmin);
        break;
      case 'director':
        Navigator.of(context).pushReplacementNamed(AppConstants.routeDirector);
        break;
      case 'therapist':
        Navigator.of(context).pushReplacementNamed(AppConstants.routeTherapist);
        break;
      case 'parent':
        Navigator.of(context).pushReplacementNamed(AppConstants.routeParent);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ── Wide layout: split panel ──────────────────────────────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left branding panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.welcomeGradient,
            ),
            child: const _BrandingPanel(),
          ),
        ),
        // Right form panel
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Narrow layout: stacked ─────────────────────────────────────────────────
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: const BoxDecoration(
              gradient: AppColors.welcomeGradient,
            ),
            child: const _BrandingPanel(compact: true),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildForm(),
          ),
        ],
      ),
    );
  }

  // ── Shared form ───────────────────────────────────────────────────────────
  Widget _buildForm() {
    final isLoading = context.watch<AuthService>().isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          const Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to continue to ${AppConstants.appShortName} ERP',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Email
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Please enter your email' : null,
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Please enter your password' : null,
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 8),

          // Error message
          if (_errorMsg != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Login button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 32),

          // Demo credentials hint
          _DemoCredentials(
            onSelect: (email, pass) {
              _emailCtrl.text = email;
              _passCtrl.text = pass;
              _handleLogin();
            },
          ),
        ],
      ),
    );
  }
}

// ── Branding panel ────────────────────────────────────────────────────────────
class _BrandingPanel extends StatelessWidget {
  final bool compact;
  const _BrandingPanel({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment:
          compact ? MainAxisAlignment.center : MainAxisAlignment.center,
      children: [
        // Logo circle
        Container(
          width: compact ? 64 : 80,
          height: compact ? 64 : 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              'ROH',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 16 : 24),
        Text(
          AppConstants.centerName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 16 : 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Clinical Care & Enterprise Resource Planning',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: compact ? 12 : 14,
          ),
        ),
      ],
    );
  }
}

// ── Demo credentials hint ─────────────────────────────────────────────────────
class _DemoCredentials extends StatelessWidget {
  final void Function(String email, String password)? onSelect;
  const _DemoCredentials({this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text('One-Click Demo Sign In (Quick Testing)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CredPill('Admin', AppConstants.adminEmail, AppConstants.adminPassword, onSelect),
              _CredPill('Director', AppConstants.directorEmail, AppConstants.directorPassword, onSelect),
              _CredPill('Therapist', AppConstants.therapistEmail, AppConstants.therapistPassword, onSelect),
              _CredPill('Parent', AppConstants.parentEmail, AppConstants.parentPassword, onSelect),
            ],
          ),
        ],
      ),
    );
  }
}

class _CredPill extends StatelessWidget {
  final String role;
  final String email;
  final String pass;
  final void Function(String email, String password)? onSelect;
  const _CredPill(this.role, this.email, this.pass, this.onSelect);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelect?.call(email, pass),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              role,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
