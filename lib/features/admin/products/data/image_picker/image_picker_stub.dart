import 'package:joyjoy/features/admin/products/domain/admin_products.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';

ProductImagePicker createProductImagePicker() => const _NoopImagePicker();

/// Fora do navegador (VM/testes) não há seletor de arquivos.
class _NoopImagePicker implements ProductImagePicker {
  const _NoopImagePicker();

  @override
  Future<({List<PickedImage> images, int skipped})> pick({
    required int max,
  }) async => (images: const <PickedImage>[], skipped: 0);
}
