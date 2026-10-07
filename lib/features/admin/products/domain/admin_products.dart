import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';

/// Erros do formulário campo a campo (o controller mostra cada um no seu campo).
final class ProductValidationFailure extends Failure {
  const ProductValidationFailure(this.errors)
    : super('Confira os campos destacados.', code: 'validation');

  final Map<ProductField, String> errors;

  @override
  List<Object?> get props => [...super.props, errors];
}

/// Cadastro de peças pela Ana. Só funciona logada como admin (RLS + RPC).
abstract interface class AdminProductRepository {
  Future<Result<List<AdminProductSummary>>> listProducts();

  /// Peça com fotos e grade cor × tamanho, pronta para editar.
  Future<Result<ProductDraft>> getDraft(String id);

  Future<Result<void>> setActive(String id, {required bool active});

  /// Todas as categorias ativas (de todas as seções).
  Future<Result<List<Category>>> listCategories();

  /// Cria (ou reaproveita, se o nome já existe na seção) uma categoria.
  Future<Result<Category>> createCategory(String name, Gender gender);

  /// Envia a foto para `<productId>/<arquivo>` e devolve o caminho.
  Future<Result<String>> uploadImage(String productId, PickedImage image);

  /// Grava produto + variantes + fotos numa transação (`save_product`).
  /// Toda foto de [draft] já precisa ter `storagePath`.
  Future<Result<SavedProduct>> save(ProductDraft draft);

  /// Apaga arquivos do Storage. Melhor esforço: falha não desfaz o salvar.
  Future<void> removeImages(List<String> storagePaths);
}

/// Escolhe fotos no aparelho e comprime no navegador (lado maior ≤ 1600 px).
abstract interface class ProductImagePicker {
  /// Lista vazia se a Ana cancelar. `skipped` = arquivos que não deu para ler
  /// (ex.: HEIC no Chrome).
  Future<({List<PickedImage> images, int skipped})> pick({required int max});
}

class ListAdminProducts
    implements UseCase<List<AdminProductSummary>, NoParams> {
  ListAdminProducts(this._repository);
  final AdminProductRepository _repository;

  @override
  Future<Result<List<AdminProductSummary>>> call(NoParams params) =>
      _repository.listProducts();
}

class GetProductDraft implements UseCase<ProductDraft, String> {
  GetProductDraft(this._repository);
  final AdminProductRepository _repository;

  @override
  Future<Result<ProductDraft>> call(String id) => _repository.getDraft(id);
}

class SetProductActive implements UseCase<void, ({String id, bool active})> {
  SetProductActive(this._repository);
  final AdminProductRepository _repository;

  @override
  Future<Result<void>> call(({String id, bool active}) params) =>
      _repository.setActive(params.id, active: params.active);
}

class ListAdminCategories implements UseCase<List<Category>, NoParams> {
  ListAdminCategories(this._repository);
  final AdminProductRepository _repository;

  @override
  Future<Result<List<Category>>> call(NoParams params) =>
      _repository.listCategories();
}

class CreateCategory
    implements UseCase<Category, ({String name, Gender gender})> {
  CreateCategory(this._repository);
  final AdminProductRepository _repository;

  @override
  Future<Result<Category>> call(({String name, Gender gender}) params) {
    final name = params.name.trim();
    if (name.isEmpty || name.length > 60) {
      return Future.value(
        const Failed(ValidationFailure('Nome da categoria: 1 a 60 letras.')),
      );
    }
    return _repository.createCategory(name, params.gender);
  }
}

/// Salvar a peça:
/// 1. valida (mesmas regras do banco) — nada sobe se houver erro;
/// 2. envia as fotos novas;
/// 3. grava tudo numa transação (`save_product`);
/// 4. apaga do Storage as fotos que a Ana removeu.
///
/// Se o passo 3 falhar, as fotos do passo 2 são apagadas (não ficam órfãs).
class SaveProduct implements UseCase<SavedProduct, ProductDraft> {
  SaveProduct(this._repository);
  final AdminProductRepository _repository;

  @override
  Future<Result<SavedProduct>> call(ProductDraft draft) async {
    final errors = draft.validate();
    if (errors.isNotEmpty) return Failed(ProductValidationFailure(errors));

    final uploaded = <String>[];
    final images = <DraftImage>[];
    for (final image in draft.images) {
      final picked = image.picked;
      if (!image.isNew || picked == null) {
        images.add(image);
        continue;
      }
      final result = await _repository.uploadImage(draft.id, picked);
      switch (result) {
        case Success(:final value):
          uploaded.add(value);
          images.add(image.withStoragePath(value));
        case Failed(:final failure):
          await _cleanup(uploaded);
          return Failed(failure);
      }
    }

    final saved = await _repository.save(draft.copyWith(images: images));
    if (saved.isFailure) {
      await _cleanup(uploaded);
      return saved;
    }
    await _cleanup(draft.removedImagePaths);
    return saved;
  }

  Future<void> _cleanup(List<String> paths) async {
    if (paths.isNotEmpty) await _repository.removeImages(paths);
  }
}
