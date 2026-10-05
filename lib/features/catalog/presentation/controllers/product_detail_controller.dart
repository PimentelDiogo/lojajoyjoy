import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/core/services/link_launcher.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/utils/whatsapp_link.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_detail.dart';
import 'package:joyjoy/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';

/// Página do produto: seleção de cor → tamanho → quantidade (limitada ao estoque).
class ProductDetailController extends GetxController {
  ProductDetailController({
    required this.slug,
    required this.getProductBySlug,
    required this.store,
    required this.launcher,
  });

  final String slug;
  final GetProductBySlug getProductBySlug;
  final StoreController store;
  final LinkLauncher launcher;

  /// Teto por item no carrinho, mesmo com muito estoque (anti-erro de digitação).
  static const maxPerItem = 10;

  final Rx<UiState<ProductDetail>> state = Rx<UiState<ProductDetail>>(
    const UiIdle(),
  );
  final RxnString selectedColor = RxnString();
  final RxnString selectedSize = RxnString();
  final RxInt quantity = 1.obs;

  ProductDetail? get detail => switch (state.value) {
    UiSuccess(:final data) => data,
    _ => null,
  };

  List<ProductVariant> get sizesForSelectedColor {
    final color = selectedColor.value;
    return (detail == null || color == null)
        ? const []
        : detail!.variantsOf(color);
  }

  ProductVariant? get selectedVariant {
    final color = selectedColor.value;
    final size = selectedSize.value;
    if (detail == null || color == null || size == null) return null;
    return detail!.variantFor(colorName: color, size: size);
  }

  /// Escolheu uma combinação que está sem estoque → mostra "Avise-me".
  bool get isSelectionSoldOut => selectedVariant?.inStock == false;

  bool get isProductSoldOut => (detail?.totalStock ?? 0) <= 0;

  int get maxQuantity {
    final stock = selectedVariant?.stock ?? 0;
    return stock < maxPerItem ? stock : maxPerItem;
  }

  bool get canAddToCart =>
      selectedVariant != null &&
      selectedVariant!.inStock &&
      quantity.value >= 1 &&
      quantity.value <= maxQuantity;

  num get price => selectedVariant?.price ?? detail?.price ?? 0;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    state.value = const UiLoading();
    final result = await getProductBySlug(slug);
    state.value = UiState.fromResult(result);
    final product = detail;
    if (product != null) _selectDefaults(product);
  }

  /// Primeira cor com estoque e seu primeiro tamanho disponível.
  void _selectDefaults(ProductDetail product) {
    final colors = product.colors;
    if (colors.isEmpty) return;
    final withStock = colors.where(
      (c) => product.variantsOf(c.name).any((v) => v.inStock),
    );
    selectColor((withStock.isEmpty ? colors.first : withStock.first).name);
  }

  void selectColor(String colorName) {
    selectedColor.value = colorName;
    final sizes = sizesForSelectedColor;
    final keep = sizes.any((v) => v.size == selectedSize.value && v.inStock);
    if (!keep) {
      final firstInStock = sizes.where((v) => v.inStock);
      selectedSize.value = firstInStock.isEmpty
          ? null
          : firstInStock.first.size;
    }
    _clampQuantity();
  }

  void selectSize(String size) {
    selectedSize.value = size;
    _clampQuantity();
  }

  void increment() {
    if (quantity.value < maxQuantity) quantity.value++;
  }

  void decrement() {
    if (quantity.value > 1) quantity.value--;
  }

  void _clampQuantity() {
    final max = maxQuantity;
    quantity.value = max == 0 ? 1 : quantity.value.clamp(1, max);
  }

  /// Mensagem do "Avise-me" (A8) — pede à Ana para avisar quando chegar.
  String notifyMeMessage() {
    final product = detail!;
    final parts = [
      product.name,
      if (selectedSize.value != null) 'Tam: ${selectedSize.value}',
      if (selectedColor.value != null) 'Cor: ${selectedColor.value}',
    ];
    return 'Olá! Pode me avisar quando chegar? ${parts.join(' — ')}';
  }

  /// Abre o WhatsApp da Ana. Retorna false se a loja ainda não carregou o número.
  Future<bool> notifyMe() async {
    final number = store.settings.value?.whatsappNumber;
    final uri = number == null
        ? null
        : WhatsAppLink.tryBuild(number, message: notifyMeMessage());
    if (uri == null) return false;
    return launcher.open(uri);
  }
}
