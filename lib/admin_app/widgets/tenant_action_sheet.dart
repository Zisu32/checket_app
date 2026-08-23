import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_action_sheet.dart';

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
  bool _showErrors = false;

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
    setState(() => _showErrors = true);
    
    if (_nameController.text.isEmpty || 
        _schemaController.text.isEmpty ||
        _sumupKeyController.text.isEmpty ||
        _merchantCodeController.text.isEmpty ||
        _affiliateKeyController.text.isEmpty) {
      _showError('Bitte alle Felder ausfüllen');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final schema = _schemaController.text.trim().toLowerCase();
      
      // 1. Create Tenant (Schema)
      if (widget.tenant == null) {
        await _supabase.rpc('create_new_tenant', params: {
          'tenant_name': _nameController.text.trim(),
          'target_schema': schema,
        });
      }

      // 2. Store Secrets
      final secrets = {
        'SUMUP_API_KEY': _sumupKeyController.text.trim(),
        'SUMUP_MERCHANT_CODE': _merchantCodeController.text.trim(),
        'SUMUP_AFFILIATE_KEY': _affiliateKeyController.text.trim(),
      };

      for (var entry in secrets.entries) {
        await _supabase.rpc('store_tenant_secret', params: {
          'p_schema': schema,
          'p_key_name': entry.key,
          'p_secret_value': entry.value,
        });
      }
      
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Fehler beim Speichern: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: msg));
  }

  @override
  Widget build(BuildContext context) {
    return AppActionSheet(
      title: widget.tenant == null ? 'Neuer Tenant' : widget.tenant['name'],
      subtitle: widget.tenant == null ? 'Tenant anlegen' : 'Tenant bearbeiten',
      body: Column(
        children: [
          _buildInput('Anzeigename (z.B. Club Saphir)', _nameController),
          _buildInput('Schema-Name (z.B. tenant_saphir)', _schemaController, enabled: widget.tenant == null),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.surface),
          const SizedBox(height: 16),
          _buildInput('SumUp API Key (sk_live...)', _sumupKeyController, obscure: true),
          _buildInput('Merchant Code', _merchantCodeController),
          _buildInput('Affiliate Key', _affiliateKeyController),
          const SizedBox(height: 24),
          _isLoading 
            ? const CircularProgressIndicator(color: AppTheme.active)
            : AppPrimaryButton(
                text: widget.tenant == null ? 'Tenant erstellen' : 'Speichern',
                color: AppTheme.active,
                onTap: _saveTenant,
              ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool obscure = false, bool enabled = true}) {
    final bool isEmpty = _showErrors && controller.text.isEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        style: const TextStyle(color: AppTheme.white),
        decoration: InputDecoration(
          labelText: label,
          errorText: isEmpty ? '' : null,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
        ),
      ),
    );
  }
}
