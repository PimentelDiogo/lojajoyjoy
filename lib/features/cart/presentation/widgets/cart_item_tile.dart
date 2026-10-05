import 'package:flutter/material.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/utils/color_hex.dart';
import 'package:joyjoy/core/widgets/price_text.dart';
import 'package:joyjoy/core/widgets/product_card.dart';
import 'package:joyjoy/core/widgets/product_image.dart';
import 'package:joyjoy/core/widgets/quantity_stepper.dart';
import 'package:joyjoy/features/cart/domain/entities/cart.dart';

/// Uma peça do carrinho: foto, variante, quantidade, observação e remover.
class CartItemTile extends StatefulWidget {
  const CartItemTile({
    required this.item,
    required this.onQuantityChanged,
    required this.onNoteChanged,
    required this.onRemove,
    required this.onOpenProduct,
    super.key,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onRemove;
  final VoidCallback onOpenProduct;

  @override
  State<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<CartItemTile> {
  late final TextEditingController _note = TextEditingController(
    text: widget.item.note,
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final swatch = colorFromHex(item.colorHex);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  button: true,
                  label: 'Ver ${item.productName}',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: widget.onOpenProduct,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: SizedBox(
                        width: 72,
                        child: AspectRatio(
                          aspectRatio: ProductCard.imageAspectRatio,
                          child: ProductImage(url: item.imageUrl),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remover ${item.productName}',
                            visualDensity: VisualDensity.compact,
                            onPressed: widget.onRemove,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (swatch != null) ...[
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: swatch,
                                shape: BoxShape.circle,
                                border: Border.all(color: scheme.outline),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                          ],
                          Flexible(
                            child: Text(
                              'Tam ${item.size} · ${item.colorName}',
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          QuantityStepper(
                            value: item.quantity,
                            max: item.maxQuantity < Cart.maxPerItem
                                ? item.maxQuantity
                                : Cart.maxPerItem,
                            onIncrement: () =>
                                widget.onQuantityChanged(item.quantity + 1),
                            onDecrement: () =>
                                widget.onQuantityChanged(item.quantity - 1),
                          ),
                          PriceText(
                            price: item.subtotal,
                            size: PriceTextSize.small,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _note,
              maxLength: Cart.maxNoteLength,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: widget.onNoteChanged,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Observação (opcional)',
                hintText: 'Ex.: fazer barra de 2 cm',
                counterText: '',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
