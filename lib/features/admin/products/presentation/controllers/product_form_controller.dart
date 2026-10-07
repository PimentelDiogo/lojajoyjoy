import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/core/utils/currency.dart';
import 'package:joyjoy/features/admin/products/domain/admin_products.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_detail.dart';

/// Formulário de peça (nova ou edição). Rota com parâmetro → `tag` = id
/// (ou `nova`), como os outros controllers por rota.
class ProductFormController extends GetxController {
  ProductFormController({
    required this.getProductDraft,
    required this.saveProduct,
    required this.listCategories,
    required this.createCategoryUseCase,
    required this.imagePicker,
    required this.newId,
    this.productId,
  });

  final GetProductDraft getProductDraft;
  final SaveProduct saveProduct;
  final ListAdminCategories listCategories;
  final CreateCategory createCategoryUseCase;
  final ProductImagePicker imagePicker;

  /// Gera o UUID da peça nova (as fotos sobem em `<id>/…` antes de salvar).
  final String Function() newId;

  /// Null = peça nova.
  final String? productId;

  bool get isNew => productId == null;

  /// Tamanhos sugeridos (um toque adiciona).
  static const sizePresets = [
    ['PP', 'P', 'M', 'G', 'GG'],
    ['36', '38', '40', '42', '44', '46'],
    ['U'],
  ];

  final Rx<UiState<void>> loadState = Rx<UiState<void>>(const UiIdle());

  final name = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final compareAtPrice = TextEditingController();

  final Rx<Gender> gender = Gender.feminino.obs;
  final RxnString categoryId = RxnString();
  final RxBool isActive = true.obs;
  final RxBool isFeatured = false.obs;
  final RxList<DraftImage> images = <DraftImage>[].obs;
  final RxList<DraftColor> colors = <DraftColor>[].obs;
  final RxList<String> sizes = <String>[].obs;
  final RxMap<String, DraftCell> cells = <String, DraftCell>{}.obs;
  final RxList<Category> categories = <Category>[].obs;

  final Rx<Map<ProductField, String>> errors = Rx(const {});
  final RxBool isSaving = false.obs;
  final RxBool isPicking = false.obs;

  late String _id;
  String? _slug;
  final List<String> _removedPaths = [];
  var _colorSeq = 0;
  var _imageSeq = 0;

  String? get slug => _slug;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  @override
  void onClose() {
    name.dispose();
    description.dispose();
    price.dispose();
    compareAtPrice.dispose();
    super.onClose();
  }

  Future<void> load() async {
    loadState.value = const UiLoading();
    final categoriesResult = await listCategories(const NoParams());
    if (categoriesResult case Success(:final value)) {
      categories.assignAll(value);
    }

    if (isNew) {
      _id = newId();
      loadState.value = const UiSuccess(null);
      return;
    }
    switch (await getProductDraft(productId!)) {
      case Success(:final value):
        _fill(value);
        loadState.value = const UiSuccess(null);
      case Failed(:final failure):
        loadState.value = UiFailure(failure);
    }
  }

  void _fill(ProductDraft draft) {
    _id = draft.id;
    _slug = draft.slug;
    name.text = draft.name;
    description.text = draft.description;
    price.text = draft.price == null ? '' : Currency.formatInput(draft.price!);
    compareAtPrice.text = draft.compareAtPrice == null
        ? ''
        : Currency.formatInput(draft.compareAtPrice!);
    gender.value = draft.gender;
    categoryId.value = draft.categoryId;
    isActive.value = draft.isActive;
    isFeatured.value = draft.isFeatured;
    images.assignAll(List.of(draft.images));
    colors.assignAll(List.of(draft.colors));
    _colorSeq = draft.colors.length;
    sizes.assignAll(List.of(draft.sizes));
    // Cópias: o rascunho pode vir com coleções imutáveis (const).
    cells.assignAll(Map.of(draft.cells));
  }

  // --- Seção e categoria -----------------------------------------------------

  /// Categorias que combinam com a seção escolhida (unissex aparece em todas).
  List<Category> get categoriesForGender => categories
      .where(
        (c) =>
            c.gender == gender.value ||
            c.gender == Gender.unissex ||
            gender.value == Gender.unissex,
      )
      .toList();

  void setGender(Gender value) {
    gender.value = value;
    final current = categoryId.value;
    if (current != null && !categoriesForGender.any((c) => c.id == current)) {
      categoryId.value = null;
    }
  }

  Future<Failure?> createCategory(String name) async {
    final result = await createCategoryUseCase((
      name: name,
      gender: gender.value,
    ));
    switch (result) {
      case Success(:final value):
        if (!categories.any((c) => c.id == value.id)) categories.add(value);
        categoryId.value = value.id;
        return null;
      case Failed(:final failure):
        return failure;
    }
  }

  // --- Cores e tamanhos ------------------------------------------------------

  /// Erro para mostrar, ou null se adicionou.
  String? addColor(String name, String? hex) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Informe o nome da cor.';
    if (trimmed.length > 40) return 'Nome da cor: até 40 letras.';
    if (_colorExists(trimmed)) return 'Essa cor já está na peça.';
    colors.add(DraftColor(key: 'n${_colorSeq++}', name: trimmed, hex: hex));
    _clearError(ProductField.variants);
    return null;
  }

  String? updateColor(String key, String name, String? hex) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Informe o nome da cor.';
    if (trimmed.length > 40) return 'Nome da cor: até 40 letras.';
    if (_colorExists(trimmed, except: key)) return 'Essa cor já está na peça.';
    final index = colors.indexWhere((c) => c.key == key);
    if (index >= 0) {
      colors[index] = DraftColor(key: key, name: trimmed, hex: hex);
    }
    return null;
  }

  void removeColor(String key) {
    colors.removeWhere((c) => c.key == key);
    cells.removeWhere((cellKey, _) => cellKey.startsWith('$key|'));
  }

  bool _colorExists(String name, {String? except}) => colors.any(
    (c) => c.key != except && c.name.toLowerCase() == name.toLowerCase(),
  );

  String? addSize(String label) {
    final size = label.trim().toUpperCase();
    if (size.isEmpty) return 'Informe o tamanho.';
    if (size.length > 10) return 'Tamanho: até 10 letras.';
    if (sizes.contains(size)) return 'Esse tamanho já está na peça.';
    sizes
      ..add(size)
      ..sort(SizeOrder.compare);
    _clearError(ProductField.variants);
    return null;
  }

  void removeSize(String size) {
    sizes.remove(size);
    cells.removeWhere((cellKey, _) => cellKey.endsWith('|$size'));
  }

  DraftCell cell(String colorKey, String size) =>
      cells[ProductDraft.cellKey(colorKey, size)] ?? const DraftCell();

  /// Texto do campo de estoque: vazio = combinação não existe.
  void setStock(String colorKey, String size, String text) {
    final key = ProductDraft.cellKey(colorKey, size);
    final value = text.trim().isEmpty ? null : int.tryParse(text.trim());
    cells[key] = (cells[key] ?? const DraftCell()).withStock(value);
    _clearError(ProductField.variants);
  }

  int get totalStock => _draft().totalStock;

  // --- Fotos -----------------------------------------------------------------

  int get remainingImages => ProductDraft.maxImages - images.length;

  /// Mensagem para a Ana (ex.: fotos que não deu para abrir), ou null.
  Future<String?> pickImages() async {
    if (remainingImages <= 0 || isPicking.value) {
      return 'Máximo de ${ProductDraft.maxImages} fotos por peça.';
    }
    isPicking.value = true;
    final (:images, :skipped) = await imagePicker.pick(max: remainingImages);
    isPicking.value = false;
    this.images.addAll([
      for (final picked in images)
        DraftImage(key: 'new-${_imageSeq++}', picked: picked),
    ]);
    if (images.isNotEmpty) _clearError(ProductField.images);
    if (skipped > 0) {
      return skipped == 1
          ? 'Uma foto não pôde ser aberta. Use JPG, PNG ou WebP.'
          : '$skipped fotos não puderam ser abertas. Use JPG, PNG ou WebP.';
    }
    return null;
  }

  void moveImage(int from, int to) {
    if (from < 0 || from >= images.length || to < 0 || to >= images.length) {
      return;
    }
    final image = images.removeAt(from);
    images.insert(to, image);
  }

  void makeCover(int index) => moveImage(index, 0);

  void removeImage(int index) {
    if (index < 0 || index >= images.length) return;
    final image = images.removeAt(index);
    final path = image.storagePath;
    if (path != null) _removedPaths.add(path);
  }

  // --- Salvar ----------------------------------------------------------------

  ProductDraft _draft() => ProductDraft(
    id: _id,
    isNew: isNew,
    slug: _slug,
    name: name.text,
    description: description.text,
    gender: gender.value,
    categoryId: categoryId.value,
    price: Currency.parse(price.text),
    compareAtPrice: Currency.parse(compareAtPrice.text),
    isActive: isActive.value,
    isFeatured: isFeatured.value,
    images: images.toList(),
    colors: colors.toList(),
    sizes: sizes.toList(),
    cells: Map.of(cells),
    removedImagePaths: List.of(_removedPaths),
  );

  /// Salva. Devolve a falha (para a View mostrar) ou null se deu certo.
  Future<Failure?> save() async {
    if (isSaving.value) return null;
    if (compareAtPrice.text.trim().isNotEmpty &&
        Currency.parse(compareAtPrice.text) == null) {
      errors.value = {
        ProductField.compareAtPrice: 'Valor inválido (ex.: 199,90).',
      };
      return const ProductValidationFailure({});
    }
    isSaving.value = true;
    final result = await saveProduct(_draft());
    isSaving.value = false;
    switch (result) {
      case Success(:final value):
        _slug = value.slug;
        _removedPaths.clear();
        errors.value = const {};
        return null;
      case Failed(:final ProductValidationFailure failure):
        errors.value = failure.errors;
        return failure;
      case Failed(:final failure):
        return failure;
    }
  }

  void clearError(ProductField field) => _clearError(field);

  void _clearError(ProductField field) {
    if (errors.value.containsKey(field)) {
      errors.value = {...errors.value}..remove(field);
    }
  }
}
