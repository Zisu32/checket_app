import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../../shared/widgets/app_primary_button.dart';

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
  bool _showErrors = false;

  Future<void> _handleLogin() async {
    setState(() => _showErrors = true);
    
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (response.user == null) throw 'Login fehlgeschlagen.';
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Fehler: $e'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailEmpty = _showErrors && _emailController.text.isEmpty;
    final passwordEmpty = _showErrors && _passwordController.text.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/full-icon.svg',
                height: 48,
              ),
              if (widget.isAdminMode) ...[
                const SizedBox(height: 8),
                const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: AppTheme.small,
                    color: AppTheme.white,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppTheme.white),
                cursorColor: AppTheme.white,
                maxLength: 64,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[<>{}\[\]\\/]')),
                ],
                decoration: InputDecoration(
                  labelText: 'E-Mail',
                  errorText: (emailEmpty || (_showErrors && !_emailController.text.contains('@'))) ? '' : null,
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.white),
                cursorColor: AppTheme.white,
                maxLength: 64,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[<>{}\[\]\\/]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  errorText: passwordEmpty ? '' : null,
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator(color: AppTheme.active)
              else 
                AppPrimaryButton(
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
