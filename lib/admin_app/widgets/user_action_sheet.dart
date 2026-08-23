import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_action_sheet.dart';

class UserActionSheet extends StatefulWidget {
  final dynamic user; // null for new user
  final List<dynamic> tenants;
  final VoidCallback onSaved;

  const UserActionSheet({super.key, this.user, required this.tenants, required this.onSaved});

  @override
  State<UserActionSheet> createState() => _UserActionSheetState();
}

class _UserActionSheetState extends State<UserActionSheet> {
  final _supabase = Supabase.instance.client;
  int _step = 1;
  bool _isLoading = false;
  bool _showErrors = false;

  // Step 1: User Info
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String _selectedRole = 'staff';

  // Step 2: Tenant Assignment
  String? _selectedSchema;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?['email']);
    _passwordController = TextEditingController();
    _selectedRole = widget.user?['role'] ?? 'staff';
    _selectedSchema = widget.user?['tenantSchema'];
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    setState(() => _showErrors = true);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || (_passwordController.text.isEmpty && widget.user == null)) {
      return;
    }
    setState(() {
      _step = 2;
      _showErrors = false;
    });
  }

  Future<void> _saveUser() async {
    setState(() => _showErrors = true);
    if (_selectedSchema == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _supabase.functions.invoke('manage-users', body: {
        'action': widget.user == null ? 'create' : 'update',
        'email': _emailController.text.trim(),
        'password': _passwordController.text.isEmpty ? null : _passwordController.text.trim(),
        'role': _selectedRole,
        'schemaName': _selectedSchema,
        'userId': widget.user?['id'],
      });

      if (response.status != 200) {
        throw response.data['error'] ?? 'Unbekannter Fehler';
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Fehler: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: msg));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _step == 1 ? _buildStep1() : _buildStep2(),
    );
  }

  Widget _buildStep1() {
    return AppActionSheet(
      key: const ValueKey(1),
      title: widget.user == null ? 'Neuer User' : widget.user['email'],
      subtitle: widget.user == null ? 'User anlegen' : 'User bearbeiten',
      body: Column(
        children: [
          _buildInput('E-Mail', _emailController, enabled: widget.user == null),
          _buildInput(widget.user == null ? 'Passwort' : 'Neues Passwort (optional)', _passwordController, obscure: true),
          _buildRoleDropdown(),
          const SizedBox(height: 24),
          AppPrimaryButton(
            text: 'Weiter',
            color: AppTheme.active,
            onTap: _nextStep,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return AppActionSheet(
      key: const ValueKey(2),
      title: 'Tenant-Zuweisung',
      subtitle: 'Zuweisung für ${_emailController.text}',
      body: Column(
        children: [
          _buildTenantDropdown(),
          const SizedBox(height: 24),
          _isLoading 
            ? const CircularProgressIndicator(color: AppTheme.active)
            : AppPrimaryButton(
                text: 'Speichern',
                color: AppTheme.active,
                onTap: _saveUser,
              ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool obscure = false, bool enabled = true}) {
    final bool isEmpty = _showErrors && controller.text.isEmpty;
    final bool isEmailInvalid = _showErrors && label.contains('E-Mail') && !controller.text.contains('@');
    // Password is only mandatory for new users
    final bool isMandatory = label.contains('E-Mail') || (label == 'Passwort' && widget.user == null);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        maxLength: 64,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'[<>{}\[\]\\/]')),
        ],
        style: const TextStyle(color: AppTheme.white),
        decoration: InputDecoration(
          labelText: label,
          errorText: (isMandatory && (isEmpty || isEmailInvalid)) ? '' : null,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.surface),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedRole,
        dropdownColor: AppTheme.surface,
        style: const TextStyle(color: AppTheme.white),
        isExpanded: true,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'staff', child: Text('Mitarbeiter (Staff)')),
          DropdownMenuItem(value: 'admin', child: Text('Administrator')),
        ],
        onChanged: (val) => setState(() => _selectedRole = val!),
      ),
    );
  }

  Widget _buildTenantDropdown() {
    final bool isError = _showErrors && _selectedSchema == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isError ? AppTheme.unpaid : AppTheme.surface),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedSchema,
        hint: const Text('Tenant wählen', style: TextStyle(color: AppTheme.free)),
        dropdownColor: AppTheme.surface,
        style: const TextStyle(color: AppTheme.white),
        isExpanded: true,
        underline: const SizedBox(),
        items: widget.tenants.map((t) => DropdownMenuItem<String>(
          value: t['schema_name'],
          child: Text(t['name']),
        )).toList(),
        onChanged: (val) => setState(() => _selectedSchema = val),
      ),
    );
  }
}
