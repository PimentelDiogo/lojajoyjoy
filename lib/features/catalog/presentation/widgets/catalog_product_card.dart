import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/widgets/product_card.dart';
import 'package:joyjoy/core/widgets/stock_badge.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/domain/entities/stock_status.dart';

/// Liga a entidade [Product] ao [ProductCard] puro do core.
class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    required this.product,
    required this.lowStockThreshold,
    super.key,
  });

  final Product product;
  final int lowStockThreshold;

  @override
  Widget build(BuildContext context) => ProductCard(
    name: product.name,
    price: product.price,
    compareAtPrice: product.compareAtPrice,
    imageUrl: product.coverImageUrl,
    discountPercent: product.discountPercent,
    stockBadge: badgeFor(product.stockStatus(lowStockThreshold)),
    onTap: () =>
        unawaited(Get.toNamed<void>(AppRoutes.productPath(product.slug))),
  );

  static StockBadgeKind badgeFor(StockStatus status) => switch (status) {
    StockStatus.available => StockBadgeKind.none,
    StockStatus.low => StockBadgeKind.lowStock,
    StockStatus.soldOut => StockBadgeKind.soldOut,
  };
}

/// Cores de destaque por seção (ADR-0009): Feminino rosa, Masculino azul.
extension GenderStyle on Gender {
  Color sectionColor(ColorScheme scheme) => switch (this) {
    Gender.feminino => scheme.tertiaryContainer,
    Gender.masculino => scheme.secondaryContainer,
    Gender.unissex => scheme.primaryContainer,
  };

  Color onSectionColor(ColorScheme scheme) => switch (this) {
    Gender.feminino => scheme.onTertiaryContainer,
    Gender.masculino => scheme.onSecondaryContainer,
    Gender.unissex => scheme.onPrimaryContainer,
  };
}
