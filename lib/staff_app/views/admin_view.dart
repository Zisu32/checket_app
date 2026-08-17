import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_theme.dart';
import '../widgets/top_bar.dart';
import '../../shared/services/sync_service.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _tenants = [];
  
  // Provisioning Controllers
  final _nameController = TextEditingController();
  final _schemaController = TextEditingController();
  
  // Secret Controllers
  String? _selectedSchema;
  final _sumupKeyController = TextEditingController();
  final _merchantCodeController = TextEditingController();
  final _affiliateKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('tenants').select().order('name');
      setState(() {
        _tenants = data as List;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Fehler beim Laden: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _provisionTenant() async {
    if (_nameController.text.isEmpty || _schemaController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await _supabase.rpc('create_new_tenant', params: {
        'tenant_name': _nameController.text.trim(),
        'target_schema': _schemaController.text.trim().toLowerCase(),
      });
      _nameController.clear();
      _schemaController.clear();
      await _loadTenants();
      _showSuccess('Mandant erfolgreich erstellt!');
    } catch (e) {
      _showError('Provisioning fehlgeschlagen: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSecrets() async {
    if (_selectedSchema == null) return;
    
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
            'p_schema': _selectedSchema,
            'p_key_name': entry.key,
            'p_secret_value': entry.value,
          });
        }
      }
      
      _sumupKeyController.clear();
      _merchantCodeController.clear();
      _affiliateKeyController.clear();
      _showSuccess('Secrets für $_selectedSchema gespeichert.');
    } catch (e) {
      _showError('Fehler beim Speichern der Secrets: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: TopBar(
        syncService: SyncService(),
        pulseAnimation: const AlwaysStoppedAnimation(1.0),
        showSettings: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.active))
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle('Mandanten-Verzeichnis'),
              ..._tenants.map((t) => _buildTenantCard(t)),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Neuen Mandanten anlegen'),
              _buildInput('Anzeigename (z.B. Club Saphir)', _nameController),
              _buildInput('Schema-Name (z.B. tenant_saphir)', _schemaController),
              const SizedBox(height: 16),
              AppTheme.buildPrimaryButton(
                text: 'Mandant erstellen',
                color: AppTheme.active,
                onTap: _provisionTenant,
              ),

              const SizedBox(height: 48),
              _buildSectionTitle('SumUp Secrets verwalten'),
              _buildSchemaDropdown(),
              const SizedBox(height: 16),
              _buildInput('SumUp API Key (sk_live...)', _sumupKeyController, obscure: true),
              _buildInput('Merchant Code', _merchantCodeController),
              _buildInput('Affiliate Key', _affiliateKeyController),
              const SizedBox(height: 16),
              AppTheme.buildPrimaryButton(
                text: 'Secrets speichern',
                color: AppTheme.active,
                onTap: _saveSecrets,
              ),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTenantCard(dynamic t) {
    return Card(
      color: AppTheme.surface,
      child: ListTile(
        title: Text(t['name'], style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
        subtitle: Text(t['schema_name'], style: const TextStyle(color: AppTheme.free)),
        trailing: const Icon(Icons.verified_user, color: AppTheme.active, size: 20),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: AppTheme.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.free),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.surface)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.active)),
        ),
      ),
    );
  }

  Widget _buildSchemaDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.surface),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _selectedSchema,
        hint: const Text('Ziel-Mandant wählen', style: TextStyle(color: AppTheme.free)),
        dropdownColor: AppTheme.surface,
        style: const TextStyle(color: AppTheme.white),
        isExpanded: true,
        underline: const SizedBox(),
        items: _tenants.map((t) => DropdownMenuItem<String>(
          value: t['schema_name'],
          child: Text(t['name']),
        )).toList(),
        onChanged: (val) => setState(() => _selectedSchema = val),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.unpaid));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.active));
  }
}
