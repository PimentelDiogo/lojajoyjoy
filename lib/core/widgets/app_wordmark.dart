import 'package:flutter/material.dart';
import 'package:joyjoy/core/config/app_constants.dart';
import 'package:joyjoy/core/theme/app_typography.dart';

/// Nome da marca escrito como no logo (serifa espaçada, terracota).
class AppWordmark extends StatelessWidget {
  const AppWordmark({this.fontSize = 22, super.key});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = (Theme.of(context).textTheme.titleLarge ?? const TextStyle())
        .copyWith(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.primary,
        );
    return Semantics(
      header: true,
      label: AppConstants.storeName,
      excludeSemantics: true,
      child: Text(
        AppConstants.storeName,
        style: AppTypography.wordmark(base),
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
    );
  }
}
