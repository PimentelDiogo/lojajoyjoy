import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_detail.dart';

typedef JsonMap = Map<String, dynamic>;

/// Conversões JSON (PostgREST/RPC) ↔ entidades do cadastro de peças.
abstract final class AdminProductModels {
  static const listColumns =
      'id, name, slug, gender, base_price, is_active, is_featured, created_at, '
      'categories(name), '
      'product_images(storage_path, position), '
      'product_variants(stock_qty, is_active)';

  static const draftColumns =
      'id, name, slug, description, gender, category_id, base_price, '
      'compare_at_price, is_active, is_featured, '
      'product_images(storage_path, position), '
      'product_variants(id, size, color_name, color_hex, stock_qty, '
      'is_active, created_at)';

  static AdminProductSummary summaryFromJson(
    JsonMap json, {
    required String Function(String storagePath) imageUrl,
  }) {
    final images = _sorted(json['product_images']);
    final stock = _list(json['product_variants'])
        .where((v) => v['is_active'] != false)
        .fold<int>(0, (sum, v) => sum + _int(v['stock_qty']));
    final category = json['categories'];
    return AdminProductSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      gender: Gender.fromName(json['gender'] as String),
      price: _num(json['base_price'])!,
      totalStock: stock,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      coverImageUrl: images.isEmpty
          ? null
          : imageUrl(images.first['storage_path'] as String),
      categoryName: category is Map ? category['name'] as String? : null,
    );
  }

  /// Monta a grade a partir das variantes **ativas** (as desativadas por
  /// terem pedido não aparecem; readicionar a combinação reativa no banco).
  static ProductDraft draftFromJson(
    JsonMap json, {
    required String Function(String storagePath) imageUrl,
  }) {
    final variants =
        _list(
          json['product_variants'],
        ).where((v) => v['is_active'] != false).toList()..sort(
          (a, b) => (a['created_at'] as String? ?? '').compareTo(
            b['created_at'] as String? ?? '',
          ),
        );

    final colors = <DraftColor>[];
    final colorKeyByName = <String, String>{};
    final sizes = <String>{};
    final cells = <String, DraftCell>{};
    for (final v in variants) {
      final colorName = v['color_name'] as String;
      final key = colorKeyByName.putIfAbsent(colorName, () {
        final key = 'c${colors.length}';
        colors.add(
          DraftColor(
            key: key,
            name: colorName,
            hex: v['color_hex'] as String?,
          ),
        );
        return key;
      });
      final size = v['size'] as String;
      sizes.add(size);
      final stock = _int(v['stock_qty']);
      cells[ProductDraft.cellKey(key, size)] = DraftCell(
        variantId: v['id'] as String,
        stock: stock,
        baseStock: stock,
      );
    }

    return ProductDraft(
      id: json['id'] as String,
      isNew: false,
      slug: json['slug'] as String?,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      gender: Gender.fromName(json['gender'] as String),
      categoryId: json['category_id'] as String?,
      price: _num(json['base_price']),
      compareAtPrice: _num(json['compare_at_price']),
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      images: [
        for (final image in _sorted(json['product_images']))
          DraftImage(
            key: image['storage_path'] as String,
            storagePath: image['storage_path'] as String,
            url: imageUrl(image['storage_path'] as String),
          ),
      ],
      colors: colors,
      sizes: sizes.toList()..sort(SizeOrder.compare),
      cells: cells,
    );
  }

  /// Parâmetros da RPC `save_product`. Toda foto já tem `storagePath`.
  static JsonMap saveParams(ProductDraft draft) => {
    'p_product': {
      'id': draft.id,
      'name': draft.name.trim(),
      'description': draft.description.trim(),
      'gender': draft.gender.name,
      'category_id': draft.categoryId,
      'base_price': draft.price,
      'compare_at_price': draft.compareAtPrice,
      'is_active': draft.isActive,
      'is_featured': draft.isFeatured,
    },
    'p_variants': [
      for (final v in draft.variants)
        {
          if (v.id != null) 'id': v.id,
          'size': v.size,
          'color_name': v.colorName,
          'color_hex': v.colorHex,
          'stock': v.stock,
          if (v.baseStock != null) 'base_stock': v.baseStock,
        },
    ],
    'p_images': [
      for (final image in draft.images)
        if (image.storagePath case final String path) path,
    ],
  };

  static List<JsonMap> _list(Object? value) =>
      (value as List<dynamic>? ?? const []).cast<JsonMap>();

  static List<JsonMap> _sorted(Object? value) =>
      _list(value).toList()
        ..sort((a, b) => _int(a['position']).compareTo(_int(b['position'])));

  static num? _num(Object? value) => switch (value) {
    null => null,
    final num n => n,
    final String s => num.parse(s),
    _ => throw FormatException('Valor numérico inválido: $value'),
  };

  static int _int(Object? value) => _num(value)?.toInt() ?? 0;
}
