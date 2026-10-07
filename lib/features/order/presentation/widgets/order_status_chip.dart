import 'package:flutter/material.dart';
import 'package:joyjoy/core/theme/app_colors.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';

/// Selo do status do pedido (página do pedido e lista da Ana).
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({required this.status, super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = context.appColors;
    final (background, foreground) = switch (status) {
      OrderStatus.pending => (brand.peach, brand.onPeach),
      OrderStatus.confirmed => (brand.mint, brand.onMint),
      OrderStatus.cancelled ||
      OrderStatus.expired => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}
