import 'package:flutter/material.dart';
import 'package:joyjoy/core/config/app_constants.dart';

/// Logo circular da marca (`assets/brand/logo.png`).
class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 40, super.key});

  static const assetPath = 'assets/brand/logo.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo ${AppConstants.storeName}',
      image: true,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        // Decodifica no tamanho exibido (economiza memória no celular).
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        excludeFromSemantics: true,
      ),
    );
  }
}
