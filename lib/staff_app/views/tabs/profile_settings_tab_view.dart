import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';

class ProfileSettingsTabView extends StatefulWidget {
  const ProfileSettingsTabView({super.key});

  @override
  State<ProfileSettingsTabView> createState() => _ProfileSettingsTabViewState();
}

class _ProfileSettingsTabViewState extends State<ProfileSettingsTabView> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showErrors = false;

  Future<void> _updatePassword() async {
    setState(() => _showErrors = true);
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty || password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Passwörter stimmen nicht überein'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Passwort erfolgreich aktualisiert', isError: false));
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
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
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'Unbekannt';

    return Column(
      children: [
        const AppHeader(icon: Icons.person_rounded),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormRow('User', Text(email, style: const TextStyle(color: AppTheme.white, fontSize: AppTheme.small))),
                const SizedBox(height: 24),
                _buildFormRow(
                  'Neues Passwort',
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.white, fontSize: AppTheme.small),
                    cursorColor: AppTheme.white,
                    decoration: InputDecoration(
                      labelText: 'Neues Passwort',
                      errorText: (_showErrors && _passwordController.text.isEmpty) ? '' : null,
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildFormRow(
                  'Passwort bestätigen',
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.white, fontSize: AppTheme.small),
                    cursorColor: AppTheme.white,
                    decoration: InputDecoration(
                      labelText: 'Passwort bestätigen',
                      errorText: (_showErrors && (_confirmPasswordController.text.isEmpty || _confirmPasswordController.text != _passwordController.text)) ? '' : null,
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: AppTheme.active)
                    : AppPrimaryButton(
                        text: 'Speichern',
                        color: AppTheme.active,
                        onTap: _updatePassword,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormRow(String label, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.free,
            fontSize: AppTheme.xsmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }
}
