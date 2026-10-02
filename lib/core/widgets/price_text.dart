import 'package:flutter/material.dart';
import 'package:ondas_que_faltam/core/theme/app_spacing.dart';
import 'package:ondas_que_faltam/core/utils/currency.dart';

enum PriceTextSize { small, medium, large }

/// Preço do produto. Com [compareAtPrice] maior que [price], mostra o
/// "de" riscado e o "por" em destaque (referências, item A4).
class PriceText extends StatelessWidget {
  const PriceText({
    required this.price,
    this.compareAtPrice,
    this.size = PriceTextSize.medium,
    super.key,
  });

  final num price;
  final num? compareAtPrice;
  final PriceTextSize size;

  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final priceStyle = switch (size) {
      PriceTextSize.small => textTheme.titleSmall,
      PriceTextSize.medium => textTheme.titleMedium,
      PriceTextSize.large => textTheme.headlineSmall,
    }?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary);

    final current = Currency.format(price);
    final semantics = hasDiscount
        ? 'De ${Currency.format(compareAtPrice!)} por $current'
        : current;

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Wrap(
        spacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(current, style: priceStyle),
          if (hasDiscount)
            Text(
              Currency.format(compareAtPrice!),
              style: textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
              ),
            ),
        ],
      ),
    );
  }
}
