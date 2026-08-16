import 'package:flutter/material.dart';
import '../../shared/database/database.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/services/sumup_service.dart';
import '../../shared/theme/app_theme.dart';

class WardrobeActionSheet extends StatefulWidget {
  final WardrobeSlot initialSlot;
  final SyncService syncService;
  final Function(int id, String secret) onSyncMonitor;
  final String Function() onGenerateSecret;

  const WardrobeActionSheet({
    super.key,
    required this.initialSlot,
    required this.syncService,
    required this.onSyncMonitor,
    required this.onGenerateSecret,
  });

  @override
  State<WardrobeActionSheet> createState() => _WardrobeActionSheetState();
}

class _WardrobeActionSheetState extends State<WardrobeActionSheet> {
  bool _isProcessingSumUp = false;
  String _sumUpStatusText = 'Warte auf Terminal...';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WardrobeSlot>>(
      stream: widget.syncService.watchSlots(),
      builder: (context, snapshot) {
        final slots = snapshot.data ?? [];
        final slot = slots.firstWhere((s) => s.id == widget.initialSlot.id, orElse: () => widget.initialSlot);

        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bügel ${slot.id}',
                style: const TextStyle(
                  fontSize: AppTheme.medium,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 24, indent: 20, endIndent: 20, color: AppTheme.surface),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    if (slot.status == 'free')
                      ListTile(
                        leading: const Icon(Icons.add_box, color: AppTheme.active),
                        title: const Text('Jacke einchecken', style: TextStyle(fontSize: AppTheme.small, color: AppTheme.white)),
                        onTap: () async {
                          final secret = widget.onGenerateSecret();
                          final updated = slot.copyWith(
                            status: 'unpaid',
                            secret: secret,
                            isPaid: false,
                            paymentMethod: 'none',
                            updatedAt: DateTime.now(),
                          );

                          widget.onSyncMonitor(slot.id, secret);
                          await widget.syncService.updateSlot(updated);
                        },
                      ),
                    if (slot.status == 'unpaid') ...[
                      ListTile(
                        leading: _isProcessingSumUp 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.active))
                          : const Icon(Icons.contactless_outlined, color: AppTheme.active),
                        title: Text(
                          _isProcessingSumUp ? _sumUpStatusText : 'Kontaktloses bezahlen', 
                          style: const TextStyle(fontSize: AppTheme.small, color: AppTheme.white)
                        ),
                        onTap: _isProcessingSumUp ? null : () async {
                          setState(() {
                            _isProcessingSumUp = true;
                            _sumUpStatusText = 'Warte auf Terminal...';
                          });
                          
                          try {
                            final checkoutId = await SumUpService().triggerTerminalPayment(
                              slotId: slot.id,
                              secret: slot.secret,
                            );
                            
                            if (checkoutId != null) {
                              // Polling loop
                              bool isPaid = false;
                              int attempts = 0;
                              const maxAttempts = 90; // 3 minutes with 2s delay

                              while (!isPaid && attempts < maxAttempts && mounted) {
                                setState(() => _sumUpStatusText = 'Warte auf Zahlung...');
                                
                                final status = await SumUpService().checkPaymentStatus(checkoutId);
                                
                                if (status == 'PAID') {
                                  isPaid = true;
                                  final updated = slot.copyWith(
                                    status: 'active', 
                                    isPaid: true, 
                                    paymentMethod: 'nfc', 
                                    updatedAt: DateTime.now()
                                  );
                                  await widget.syncService.updateSlot(updated);
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                } else if (status == 'FAILED' || status == 'CANCELLED') {
                                  throw 'Zahlung wurde abgebrochen oder ist fehlgeschlagen.';
                                }
                                
                                if (!isPaid) {
                                  await Future.delayed(const Duration(seconds: 2));
                                  attempts++;
                                }
                              }

                              if (!isPaid && mounted) throw 'Zeitüberschreitung beim Bezahlen.';
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text ('Fehler: $e', style: TextStyle(fontSize: AppTheme.small, color: AppTheme.white)),
                                backgroundColor: AppTheme.unpaid
                              )
                            );
                          } finally {
                            if (mounted) setState(() => _isProcessingSumUp = false);
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.euro, color: AppTheme.secret),
                        title: const Text('Bar bezahlen', style: TextStyle(fontSize: AppTheme.small, color: AppTheme.white)),
                        onTap: () async {
                          final updated = slot.copyWith(status: 'active', isPaid: true, paymentMethod: 'bar', updatedAt: DateTime.now());
                          await widget.syncService.updateSlot(updated);
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                      ),
                    ],
                    if (slot.status == 'active' || slot.status == 'temporary') ...[
                      if (slot.status == 'active')
                        ListTile(
                          leading: const Icon(Icons.pause, color: AppTheme.temporary),
                          title: const Text('Temporärer Ausgang', style: TextStyle(fontSize: AppTheme.small, color: AppTheme.white)),
                          onTap: () async {
                            final updated = slot.copyWith(status: 'temporary', updatedAt: DateTime.now());
                            await widget.syncService.updateSlot(updated);
                            if (!mounted) return;
                            Navigator.pop(context);
                          },
                        )
                      else
                        ListTile(
                          leading: const Icon(Icons.play_arrow, color: AppTheme.active),
                          title: const Text('Wieder zurück', style: TextStyle(fontSize: AppTheme.small, color: AppTheme.white)),
                          onTap: () async {
                            final updated = slot.copyWith(status: 'active', updatedAt: DateTime.now());
                            await widget.syncService.updateSlot(updated);
                            if (!mounted) return;
                            Navigator.pop(context);
                          },
                        ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: AppTheme.free),
                        title: const Text('Endgültig auschecken', style: TextStyle(fontSize: AppTheme.small, color: AppTheme.white)),
                        onTap: () async {
                          final updated = slot.copyWith(
                            status: 'free',
                            isPaid: false,
                            secret: '',
                            paymentMethod: 'none',
                            updatedAt: DateTime.now(),
                          );
                          await widget.syncService.updateSlot(updated);
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
