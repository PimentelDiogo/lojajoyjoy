import 'package:flutter/material.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';

/// − 1 + com limites (ex.: máximo = estoque da variante).
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.min = 1,
    this.max = 99,
    super.key,
  });

  final int value;
  final int min;
  final int max;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Diminuir quantidade',
            onPressed: value > min ? onDecrement : null,
            icon: const Icon(Icons.remove),
          ),
          Semantics(
            label: 'Quantidade $value',
            excludeSemantics: true,
            child: SizedBox(
              width: 32,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Aumentar quantidade',
            onPressed: value < max ? onIncrement : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
