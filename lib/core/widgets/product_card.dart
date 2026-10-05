import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_button.dart';
import 'package:joyjoy/core/widgets/price_text.dart';
import 'package:joyjoy/core/widgets/stock_badge.dart';

/// Card de produto do grid/carrossel. Foto 3:4, nome, preço e "Comprar".
///
/// Use [ProductCard.extentFor] para calcular a altura no grid e nunca
/// estourar (problema E2 das referências).
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.name,
    required this.price,
    required this.onTap,
    this.compareAtPrice,
    this.imageUrl,
    this.discountPercent = 0,
    this.stockBadge = StockBadgeKind.none,
    super.key,
  });

  static const double imageAspectRatio = 3 / 4;

  /// Altura da área de texto + botão abaixo da foto.
  static const double infoHeight = 152;

  /// Altura total do card para uma largura [width].
  static double extentFor(double width) =>
      width / imageAspectRatio + infoHeight;

  final String name;
  final num price;
  final num? compareAtPrice;
  final String? imageUrl;
  final int discountPercent;
  final StockBadgeKind stockBadge;
  final VoidCallback onTap;

  bool get _soldOut => stockBadge == StockBadgeKind.soldOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final badge = StockBadge.forKind(context, stockBadge);

    return Semantics(
      button: true,
      label: name,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: imageAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: _soldOut ? 0.55 : 1,
                      child: _ProductImage(url: imageUrl),
                    ),
                    Positioned(
                      top: AppSpacing.xs,
                      left: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: Wrap(
                        spacing: AppSpacing.xxs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          ?badge,
                          if (discountPercent > 0 && !_soldOut)
                            StockBadge.discount(context, discountPercent),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: infoHeight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      PriceText(
                        price: price,
                        compareAtPrice: compareAtPrice,
                        size: PriceTextSize.small,
                      ),
                      const Spacer(),
                      ExcludeSemantics(
                        child: AppButton(
                          label: _soldOut ? 'Ver peça' : 'Comprar',
                          onPressed: onTap,
                          variant: AppButtonVariant.secondary,
                          expand: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.checkroom_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
    if (url == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}
