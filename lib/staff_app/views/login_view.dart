import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_theme.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (response.user == null) throw 'Login fehlgeschlagen.';
      
      // Redirect happens automatically via AuthGuard in main_staff.dart
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
              const Text(
                'CHECKET STAFF',
                style: TextStyle(
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
              _isLoading
                  ? const CircularProgressIndicator(color: AppTheme.active)
                  : AppTheme.buildPrimaryButton(
                      text: 'Anmelden',
                      color: AppTheme.active,
                      onTap: _handleLogin,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
