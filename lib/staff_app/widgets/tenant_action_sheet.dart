import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_theme.dart';

class TenantActionSheet extends StatefulWidget {
  final dynamic tenant; // null for new tenant
  final VoidCallback onSaved;

  const TenantActionSheet({super.key, this.tenant, required this.onSaved});

  @override
  State<TenantActionSheet> createState() => _TenantActionSheetState();
}

class _TenantActionSheetState extends State<TenantActionSheet> {
  final _supabase = Supabase.instance.client;
  int _step = 1;
  bool _isLoading = false;

  // Step 1 Controllers
  late TextEditingController _nameController;
  late TextEditingController _schemaController;

  // Step 2 Controllers
  final _sumupKeyController = TextEditingController();
  final _merchantCodeController = TextEditingController();
  final _affiliateKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tenant?['name']);
    _schemaController = TextEditingController(text: widget.tenant?['schema_name']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schemaController.dispose();
    _sumupKeyController.dispose();
    _merchantCodeController.dispose();
    _affiliateKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveTenant() async {
    if (_nameController.text.isEmpty || _schemaController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await _supabase.rpc('create_new_tenant', params: {
        'tenant_name': _nameController.text.trim(),
        'target_schema': _schemaController.text.trim().toLowerCase(),
      });
      setState(() {
        _step = 2;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Provisioning fehlgeschlagen: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSecrets() async {
    final schema = _schemaController.text.trim().toLowerCase();
    setState(() => _isLoading = true);
    try {
      final secrets = {
        'SUMUP_API_KEY': _sumupKeyController.text.trim(),
        'SUMUP_MERCHANT_CODE': _merchantCodeController.text.trim(),
        'SUMUP_AFFILIATE_KEY': _affiliateKeyController.text.trim(),
      };

      for (var entry in secrets.entries) {
        if (entry.value.isNotEmpty) {
          await _supabase.rpc('store_tenant_secret', params: {
            'p_schema': schema,
            'p_key_name': entry.key,
            'p_secret_value': entry.value,
          });
        }
      }
      
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Fehler beim Speichern der Secrets: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.unpaid));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _step == 1 ? _buildStep1() : _buildStep2(),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.tenant == null ? 'Neuen Mandanten anlegen' : 'Mandanten bearbeiten',
          style: const TextStyle(color: AppTheme.white, fontSize: AppTheme.medium, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppTheme.surface),
        const SizedBox(height: 24),
        _buildInput('Anzeigename (z.B. Club Saphir)', _nameController),
        _buildInput('Schema-Name (z.B. tenant_saphir)', _schemaController, enabled: widget.tenant == null),
        const SizedBox(height: 24),
        _isLoading 
          ? const CircularProgressIndicator(color: AppTheme.active)
          : AppTheme.buildPrimaryButton(
              text: 'Speichern & Weiter',
              color: AppTheme.active,
              onTap: _saveTenant,
            ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'SumUp Secrets',
          style: TextStyle(color: AppTheme.white, fontSize: AppTheme.medium, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppTheme.surface),
        const SizedBox(height: 24),
        _buildInput('SumUp API Key (sk_live...)', _sumupKeyController, obscure: true),
        _buildInput('Merchant Code', _merchantCodeController),
        _buildInput('Affiliate Key', _affiliateKeyController),
        const SizedBox(height: 24),
        _isLoading 
          ? const CircularProgressIndicator(color: AppTheme.active)
          : AppTheme.buildPrimaryButton(
              text: 'Abschließen',
              color: AppTheme.active,
              onTap: _saveSecrets,
            ),
      ],
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool obscure = false, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        style: const TextStyle(color: AppTheme.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.free),
          disabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.surface)),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.surface)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.active)),
        ),
      ),
    );
  }
}
