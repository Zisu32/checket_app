import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _focusNode = FocusNode();
  bool _isLoading = true;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _formatInput();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _formatInput() {
    String text = _priceController.text.replaceAll(',', '.').trim();
    if (text.isEmpty) return;
    
    double? val = double.tryParse(text);
    if (val != null) {
      _priceController.text = val.toStringAsFixed(2);
    }
  }

  Future<void> _loadData() async {
    try {
      final price = await _syncService.getGlobalTicketPrice();
      _priceController.text = price.toStringAsFixed(2);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar(message: 'Fehler beim Laden des Preises: $e', isError: true),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrice() async {
    _formatInput();
    setState(() => _showErrors = true);
    if (_priceController.text.isEmpty) return;
    
    final newPrice = double.tryParse(_priceController.text);
    if (newPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Ungültiger Preis'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _syncService.updateGlobalTicketPrice(newPrice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Gespeichert', isError: false));
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
    return Column(
      children: [
        const AppHeader(
          icon: Icons.confirmation_number,
          title: 'Ticket',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: AppTheme.white,
                  maxLength: 5,
                  onEditingComplete: _formatInput,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Ticket-Preis in EUR',
                    errorText: (_showErrors && _priceController.text.isEmpty) ? '' : null,
                    errorStyle: const TextStyle(height: 0),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppTheme.active)
                      : AppPrimaryButton(
                          text: 'Speichern',
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
