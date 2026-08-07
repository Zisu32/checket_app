import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/database/database.dart';
import '../../shared/services/platform_hints_service.dart';
import '../../shared/theme/brand_colors.dart';
import 'branded_wallet_button.dart';

class TicketInfoArea extends StatelessWidget {
  final WardrobeSlot? slot;
  final bool isShort;
  final VoidCallback onAddToWallet;

  const TicketInfoArea({
    super.key,
    required this.slot,
    required this.isShort,
    required this.onAddToWallet,
  });

  @override
  Widget build(BuildContext context) {
    if (slot == null) return const SizedBox(height: 100);

    String text = '';
    Widget? extra;
    bool iconAbove = false;

    final isIOS = PlatformHintsService.isIOS;

    switch (slot!.status) {
      case 'unpaid':
        text = 'Bitte an das Lesegerät halten';
        extra = _buildPayWithPhoneIcon();
        iconAbove = true;
        break;
      case 'active':
        text = 'für Abholerinnerung der Jacke';
        extra = Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: BrandedWalletButton(isIOS: isIOS, onTap: onAddToWallet),
        );
        iconAbove = true;
        break;
      case 'temporary':
        text = 'Jacke wieder einchecken';
        break;
      case 'forgotten':
        text = 'Jacke kann im Fundbüro abgeholt werden';
        break;
      case 'free':
      case 'picked_up':
      case 'wrong_secret':
        text = 'Sie können die Seite schließen';
        break;
      default:
        return const SizedBox(height: 100);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (extra != null && iconAbove) ...[
            extra,
            const SizedBox(height: 12),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BrandColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (extra != null && !iconAbove) ...[
            const SizedBox(height: 16),
            extra,
          ],
        ],
      ),
    );
  }

  Widget _buildPayWithPhoneIcon() {
    return SvgPicture.asset(
      'assets/images/pay_with_phone.svg',
      height: 50,
    );
  }
}
