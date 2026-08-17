import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import '../../shared/theme/app_theme.dart';

class LoginView extends StatefulWidget {
  final bool isAdminMode;

  const LoginView({
    super.key,
    this.isAdminMode = false,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _navigateToAdmin() {
    final origin = web.window.location.origin;
    final path = web.window.location.pathname;
    // Append /admin to the path, ensuring it doesn't double-slash
    final cleanPath = path.endsWith('/') ? path : '$path/';
    web.window.location.href = '$origin${cleanPath}admin';
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (response.user == null) throw 'Login fehlgeschlagen.';
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppTheme.unpaid,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isAdminMode ? 'ADMIN' : 'CHECKET STAFF',
                style: const TextStyle(
                  fontSize: AppTheme.medium,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppTheme.white),
                cursorColor: AppTheme.white,
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
                  labelStyle: TextStyle(color: AppTheme.free),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.surface)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.active)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.white),
                cursorColor: AppTheme.white,
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  labelStyle: TextStyle(color: AppTheme.free),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.surface)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.active)),
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator(color: AppTheme.active)
              else ...[
                AppTheme.buildPrimaryButton(
                  text: 'Anmelden',
                  color: AppTheme.active,
                  onTap: _handleLogin,
                ),
                if (!widget.isAdminMode) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _navigateToAdmin,
                    child: const Text(
                      'Admin-Plattformverwaltung',
                      style: TextStyle(color: AppTheme.free),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
