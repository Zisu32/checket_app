import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandedWalletButton extends StatelessWidget {
  final bool isIOS;
  final VoidCallback onTap;

  const BrandedWalletButton({
    super.key,
    required this.isIOS,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/DE_Add_to_Apple_Wallet_RGB_101421.png',
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
      );
    } else {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: SvgPicture.asset(
            'assets/images/de_add_to_google_wallet_add-wallet-badge.svg',
            height: 50,
          ),
        ),
      );
    }
  }
}
