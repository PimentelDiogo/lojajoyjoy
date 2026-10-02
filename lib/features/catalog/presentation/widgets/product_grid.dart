import 'package:flutter/material.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/loading_skeleton.dart';
import 'package:joyjoy/core/widgets/product_card.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/presentation/widgets/catalog_product_card.dart';

/// Grid de produtos em sliver. A altura de cada card é calculada a partir da
/// largura real da coluna — nunca estoura em nenhum tamanho de tela.
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({
    required this.products,
    required this.lowStockThreshold,
    super.key,
  });

  final List<Product> products;
  final int lowStockThreshold;

  @override
  Widget build(BuildContext context) => _ResponsiveSliverGrid(
    itemCount: products.length,
    itemBuilder: (_, index) => CatalogProductCard(
      product: products[index],
      lowStockThreshold: lowStockThreshold,
    ),
  );
}

/// Esqueleto do grid enquanto carrega.
class ProductSliverGridSkeleton extends StatelessWidget {
  const ProductSliverGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _ResponsiveSliverGrid(
    itemCount: context.responsive.gridColumns * 2,
    itemBuilder: (_, _) => const ProductCardSkeleton(),
  );
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: ProductCard.imageAspectRatio,
          child: LoadingSkeleton(radius: 0),
        ),
        Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingSkeleton(width: double.infinity),
              SizedBox(height: AppSpacing.xs),
              LoadingSkeleton(width: 72),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ResponsiveSliverGrid extends StatelessWidget {
  const _ResponsiveSliverGrid({
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = r.gridColumns;
        final spacing = r.gridSpacing;
        final itemWidth =
            (constraints.crossAxisExtent - spacing * (columns - 1)) / columns;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: ProductCard.extentFor(itemWidth),
          ),
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: itemCount,
          ),
        );
      },
    );
  }
}
