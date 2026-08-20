import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
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
    if (_currentReaderId == null) return;
    
    final newPrice = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (newPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ungültiger Preis'), backgroundColor: AppTheme.unpaid),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _syncService.updateTicketPrice(_currentReaderId!, newPrice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preis gespeichert'), backgroundColor: AppTheme.active),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppTheme.unpaid),
        );
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

    return Padding(
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
            decoration: const InputDecoration(
              labelText: 'Preis in EUR',
              labelStyle: TextStyle(color: AppTheme.free),
              suffixText: '€',
              suffixStyle: TextStyle(color: AppTheme.white),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.surface)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.active)),
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
    );
  }
}
