import 'package:flutter/material.dart';

/// Ícone da sacola com a quantidade de peças (header).
class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({
    required this.count,
    required this.onPressed,
    super.key,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = switch (count) {
      0 => 'Carrinho vazio',
      1 => 'Carrinho, 1 peça',
      _ => 'Carrinho, $count peças',
    };
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}
