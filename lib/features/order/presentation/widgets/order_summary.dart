import 'package:flutter/material.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/price_text.dart';

/// Linha do resumo: "2× Vestido Midi · Tam M · Rosa ........ R$ 379,80".
class SummaryLine extends StatelessWidget {
  const SummaryLine({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.note,
    super.key,
  });

  final String title;
  final String subtitle;
  final num amount;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyMedium),
                Text(subtitle, style: muted),
                if (note != null && note!.isNotEmpty)
                  Text('Obs: $note', style: muted),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PriceText(price: amount, size: PriceTextSize.small),
        ],
      ),
    );
  }
}

/// "Total ........ R$ 449,70".
class TotalLine extends StatelessWidget {
  const TotalLine({required this.total, super.key});

  final num total;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text('Total', style: Theme.of(context).textTheme.titleMedium),
      ),
      PriceText(price: total, size: PriceTextSize.large),
    ],
  );
}
