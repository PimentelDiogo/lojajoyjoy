import 'package:flutter/material.dart';
import 'package:joyjoy/core/theme/app_colors.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';

enum StockBadgeKind { none, lowStock, soldOut }

/// Selo de estoque/promoção sobre a foto do produto.
class StockBadge extends StatelessWidget {
  const StockBadge({
    required this.label,
    required this.background,
    required this.foreground,
    super.key,
  });

  /// "-23%" para produtos com preço riscado.
  factory StockBadge.discount(BuildContext context, int percent) {
    final scheme = Theme.of(context).colorScheme;
    return StockBadge(
      label: '-$percent%',
      background: scheme.primary,
      foreground: scheme.onPrimary,
    );
  }

  /// "Esgotado" / "Últimas unidades". Null para [StockBadgeKind.none].
  static StockBadge? forKind(BuildContext context, StockBadgeKind kind) {
    final scheme = Theme.of(context).colorScheme;
    final brand = context.appColors;
    return switch (kind) {
      StockBadgeKind.none => null,
      StockBadgeKind.lowStock => StockBadge(
        label: 'Últimas unidades',
        background: brand.peach,
        foreground: brand.onPeach,
      ),
      StockBadgeKind.soldOut => StockBadge(
        label: 'Esgotado',
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
    };
  }

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
