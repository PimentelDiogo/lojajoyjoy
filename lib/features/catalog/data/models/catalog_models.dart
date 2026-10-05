import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';

/// Conversão JSON (PostgREST) → entidades do domain.
abstract final class CatalogModels {
  /// [imageUrl] transforma o `storage_path` da capa em URL pública.
  static Product productFromJson(
    Map<String, dynamic> json, {
    required String Function(String storagePath) imageUrl,
  }) {
    final images =
        (json['product_images'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .toList()
          ..sort((a, b) => _int(a['position']).compareTo(_int(b['position'])));

    final totalStock = (json['product_variants'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .where((v) => v['is_active'] != false)
        .fold<int>(0, (sum, v) => sum + _int(v['stock_qty']));

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      gender: Gender.fromName(json['gender'] as String),
      price: _num(json['base_price'])!,
      compareAtPrice: _num(json['compare_at_price']),
      coverImageUrl: images.isEmpty
          ? null
          : imageUrl(images.first['storage_path'] as String),
      categoryId: json['category_id'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      totalStock: totalStock,
    );
  }

  static Category categoryFromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String,
    gender: Gender.fromName(json['gender'] as String),
  );

  /// PostgREST devolve `numeric` como número ou texto, conforme a config.
  static num? _num(Object? value) => switch (value) {
    null => null,
    final num n => n,
    final String s => num.parse(s),
    _ => throw FormatException('Valor numérico inválido: $value'),
  };

  static int _int(Object? value) => _num(value)?.toInt() ?? 0;
}
