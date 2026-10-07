import 'dart:math' as math;
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';

/// Peça na lista do admin (inclui as inativas).
class AdminProductSummary extends Equatable {
  const AdminProductSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.gender,
    required this.price,
    required this.totalStock,
    required this.isActive,
    this.isFeatured = false,
    this.coverImageUrl,
    this.categoryName,
  });

  final String id;
  final String name;
  final String slug;
  final Gender gender;
  final num price;
  final int totalStock;
  final bool isActive;
  final bool isFeatured;
  final String? coverImageUrl;
  final String? categoryName;

  AdminProductSummary copyWith({bool? isActive}) => AdminProductSummary(
    id: id,
    name: name,
    slug: slug,
    gender: gender,
    price: price,
    totalStock: totalStock,
    isActive: isActive ?? this.isActive,
    isFeatured: isFeatured,
    coverImageUrl: coverImageUrl,
    categoryName: categoryName,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    gender,
    price,
    totalStock,
    isActive,
    isFeatured,
    coverImageUrl,
    categoryName,
  ];
}

/// Foto escolhida no aparelho, já comprimida (pronta para enviar).
class PickedImage extends Equatable {
  const PickedImage({required this.bytes, required this.contentType});

  final Uint8List bytes;

  /// `image/webp` ou `image/jpeg`.
  final String contentType;

  String get extension => switch (contentType) {
    'image/webp' => 'webp',
    'image/png' => 'png',
    _ => 'jpg',
  };

  @override
  List<Object?> get props => [bytes.length, contentType];
}

/// Foto no formulário: já salva ([storagePath]) ou nova ([picked]).
class DraftImage extends Equatable {
  const DraftImage({
    required this.key,
    this.storagePath,
    this.url,
    this.picked,
  }) : assert(storagePath != null || picked != null, 'foto sem origem');

  /// Identificador local (para a lista reordenável).
  final String key;
  final String? storagePath;

  /// URL pública da foto já salva.
  final String? url;
  final PickedImage? picked;

  bool get isNew => storagePath == null;

  DraftImage withStoragePath(String path) =>
      DraftImage(key: key, storagePath: path, url: url, picked: picked);

  @override
  List<Object?> get props => [key, storagePath, url, picked];
}

/// Cor da peça (nome que a cliente vê + amostra opcional).
class DraftColor extends Equatable {
  const DraftColor({required this.key, required this.name, this.hex});

  /// Identificador local estável (a Ana pode renomear a cor).
  final String key;
  final String name;

  /// `#RRGGBB` ou null.
  final String? hex;

  @override
  List<Object?> get props => [key, name, hex];
}

/// Célula da grade cor × tamanho. [stock] null = essa combinação não existe.
class DraftCell extends Equatable {
  const DraftCell({this.variantId, this.stock, this.baseStock});

  /// Variante já salva (edição).
  final String? variantId;
  final int? stock;

  /// Estoque quando o formulário abriu — o banco aplica a diferença.
  final int? baseStock;

  DraftCell withStock(int? value) =>
      DraftCell(variantId: variantId, stock: value, baseStock: baseStock);

  @override
  List<Object?> get props => [variantId, stock, baseStock];
}

/// Variante que vai para o banco (derivada da grade).
class DraftVariant extends Equatable {
  const DraftVariant({
    required this.size,
    required this.colorName,
    required this.stock,
    this.colorHex,
    this.id,
    this.baseStock,
  });

  final String? id;
  final String size;
  final String colorName;
  final String? colorHex;
  final int stock;
  final int? baseStock;

  @override
  List<Object?> get props => [id, size, colorName, colorHex, stock, baseStock];
}

/// Campos do formulário com mensagem de erro.
enum ProductField { name, description, price, compareAtPrice, images, variants }

/// Peça sendo criada/editada pela Ana. Regras de validação vivem aqui.
class ProductDraft extends Equatable {
  const ProductDraft({
    required this.id,
    required this.isNew,
    required this.name,
    required this.gender,
    this.description = '',
    this.categoryId,
    this.price,
    this.compareAtPrice,
    this.isActive = true,
    this.isFeatured = false,
    this.images = const [],
    this.colors = const [],
    this.sizes = const [],
    this.cells = const {},
    this.removedImagePaths = const [],
    this.slug,
  });

  static const maxImages = 8;
  static const maxVariants = 100;
  static const maxStock = 99999;
  static const maxPrice = 99999.99;

  /// UUID gerado no app para peça nova (as fotos sobem em `<id>/…`).
  final String id;
  final bool isNew;
  final String? slug;
  final String name;
  final String description;
  final Gender gender;
  final String? categoryId;
  final num? price;
  final num? compareAtPrice;
  final bool isActive;
  final bool isFeatured;

  /// Em ordem: a primeira é a capa.
  final List<DraftImage> images;
  final List<DraftColor> colors;

  /// Tamanhos na ordem em que aparecem (PP → GG, 36 → 48).
  final List<String> sizes;

  /// Chave: [cellKey].
  final Map<String, DraftCell> cells;

  /// Fotos salvas que a Ana tirou — apagadas do Storage depois de salvar.
  final List<String> removedImagePaths;

  static String cellKey(String colorKey, String size) => '$colorKey|$size';

  DraftCell cell(String colorKey, String size) =>
      cells[cellKey(colorKey, size)] ?? const DraftCell();

  /// Combinações que existem (estoque informado), na ordem da grade.
  List<DraftVariant> get variants => [
    for (final color in colors)
      for (final size in sizes)
        if (cell(color.key, size) case DraftCell(:final int stock) && final c)
          DraftVariant(
            id: c.variantId,
            size: size,
            colorName: color.name.trim(),
            colorHex: color.hex,
            stock: stock,
            baseStock: c.variantId == null ? null : c.baseStock,
          ),
  ];

  int get totalStock => variants.fold(0, (sum, v) => sum + v.stock);

  /// Erros por campo (vazio = pode salvar). Mesmas regras do banco.
  Map<ProductField, String> validate() {
    final errors = <ProductField, String>{};
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      errors[ProductField.name] = 'Informe o nome da peça.';
    } else if (trimmed.length > 120) {
      errors[ProductField.name] = 'Nome muito longo (máximo 120 letras).';
    }
    if (description.trim().length > 4000) {
      errors[ProductField.description] =
          'Descrição muito longa (máximo 4.000 letras).';
    }
    final p = price;
    if (p == null || p <= 0 || p > maxPrice) {
      errors[ProductField.price] = 'Informe um preço válido (ex.: 129,90).';
    }
    final compare = compareAtPrice;
    if (compare != null && p != null && compare <= p) {
      errors[ProductField.compareAtPrice] =
          'O preço "de" precisa ser maior que o preço de venda.';
    }
    if (images.length > maxImages) {
      errors[ProductField.images] = 'Máximo de $maxImages fotos por peça.';
    }

    final list = variants;
    if (colors.isEmpty || sizes.isEmpty) {
      errors[ProductField.variants] = 'Adicione ao menos uma cor e um tamanho.';
    } else if (list.isEmpty) {
      errors[ProductField.variants] =
          'Informe o estoque de ao menos uma combinação (pode ser 0).';
    } else if (list.length > maxVariants) {
      errors[ProductField.variants] =
          'Máximo de $maxVariants combinações de cor e tamanho.';
    } else if (list.any((v) => v.stock < 0 || v.stock > maxStock)) {
      errors[ProductField.variants] = 'Estoque inválido.';
    } else if (colors.any((c) => c.name.trim().isEmpty)) {
      errors[ProductField.variants] = 'Toda cor precisa de um nome.';
    } else if (_hasDuplicateColor()) {
      errors[ProductField.variants] = 'Tem duas cores com o mesmo nome.';
    }
    return errors;
  }

  bool _hasDuplicateColor() {
    final seen = <String>{};
    return colors.any((c) => !seen.add(c.name.trim().toLowerCase()));
  }

  ProductDraft copyWith({List<DraftImage>? images}) => ProductDraft(
    id: id,
    isNew: isNew,
    slug: slug,
    name: name,
    description: description,
    gender: gender,
    categoryId: categoryId,
    price: price,
    compareAtPrice: compareAtPrice,
    isActive: isActive,
    isFeatured: isFeatured,
    images: images ?? this.images,
    colors: colors,
    sizes: sizes,
    cells: cells,
    removedImagePaths: removedImagePaths,
  );

  @override
  List<Object?> get props => [
    id,
    isNew,
    slug,
    name,
    description,
    gender,
    categoryId,
    price,
    compareAtPrice,
    isActive,
    isFeatured,
    images,
    colors,
    sizes,
    cells,
    removedImagePaths,
  ];
}

/// Resultado de salvar: o slug é o endereço da peça na vitrine.
class SavedProduct extends Equatable {
  const SavedProduct({required this.id, required this.slug});

  final String id;
  final String slug;

  @override
  List<Object?> get props => [id, slug];
}

/// Tamanho final da foto: o lado maior vira no máximo [maxSide] (sem ampliar).
({int width, int height}) fitWithin(int width, int height, int maxSide) {
  final longest = math.max(width, height);
  if (longest <= maxSide) return (width: width, height: height);
  final scale = maxSide / longest;
  return (
    width: math.max(1, (width * scale).round()),
    height: math.max(1, (height * scale).round()),
  );
}
