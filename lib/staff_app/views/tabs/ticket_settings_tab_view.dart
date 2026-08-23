import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/services/sync_service.dart';
import '../../../../shared/services/sumup_service.dart';

class TicketSettingsTabView extends StatefulWidget {
  const TicketSettingsTabView({super.key});

  @override
  State<TicketSettingsTabView> createState() => _TicketSettingsTabViewState();
}

class _TicketSettingsTabViewState extends State<TicketSettingsTabView> {
  final _syncService = SyncService();
  final _sumUpService = SumUpService();
  final _priceController = TextEditingController();
  bool _isLoading = true;
  bool _showErrors = false;
  String? _currentReaderId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _currentReaderId = _sumUpService.getSelectedReaderId();
    if (_currentReaderId != null) {
      final price = await _syncService.getTicketPrice(_currentReaderId!);
      _priceController.text = price.toStringAsFixed(2);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _savePrice() async {
    setState(() => _showErrors = true);
    if (_currentReaderId == null || _priceController.text.isEmpty) return;
    
    final newPrice = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (newPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Ungültiger Preis'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _syncService.updateTicketPrice(_currentReaderId!, newPrice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Preis gespeichert', isError: false));
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
    if (_currentReaderId == null) {
      return const Center(
        child: Text(
          'Bitte wählen Sie zuerst einen Arbeitsplatz aus.',
          style: TextStyle(color: AppTheme.white, fontSize: AppTheme.small),
        ),
      );
    }

    return Column(
      children: [
        const AppHeader(icon: Icons.confirmation_number),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ticket-Preis konfigurieren',
                  style: TextStyle(color: AppTheme.white, fontSize: AppTheme.medium, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Legen Sie fest, wie viel ein Ticket für diesen Arbeitsplatz kostet.',
                  style: TextStyle(color: AppTheme.free, fontSize: AppTheme.small),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.white, fontSize: AppTheme.medium),
                  cursorColor: AppTheme.white,
                  decoration: InputDecoration(
                    labelText: 'Preis in EUR',
                    errorText: (_showErrors && _priceController.text.isEmpty) ? '' : null,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                    suffixText: '€',
                    suffixStyle: const TextStyle(color: AppTheme.white),
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: AppTheme.active)
                    : AppPrimaryButton(
                        text: 'Preis speichern',
                        color: AppTheme.active,
                        onTap: _savePrice,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
