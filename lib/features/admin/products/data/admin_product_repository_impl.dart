import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/supabase_error_mapper.dart';
import 'package:joyjoy/features/admin/products/data/admin_product_models.dart';
import 'package:joyjoy/features/admin/products/domain/admin_products.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';
import 'package:joyjoy/features/catalog/data/models/catalog_models.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Cadastro de peças no Supabase. O RLS ("admin gerencia …") e o
/// `is_admin()` das RPCs são a proteção real — este código só chama a API.
class AdminProductRepositoryImpl implements AdminProductRepository {
  AdminProductRepositoryImpl(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  static const bucket = 'product-images';

  /// Catálogo da Ana é pequeno: a lista vem inteira e a busca é local.
  static const listLimit = 500;

  String _publicUrl(String path) =>
      _client.storage.from(bucket).getPublicUrl(path);

  @override
  Future<Result<List<AdminProductSummary>>> listProducts() => _guard(() async {
    final rows = await _client
        .from('products')
        .select(AdminProductModels.listColumns)
        .order('created_at', ascending: false)
        .order('id')
        .limit(listLimit);
    return [
      for (final row in rows)
        AdminProductModels.summaryFromJson(row, imageUrl: _publicUrl),
    ];
  }, isWrite: false);

  @override
  Future<Result<ProductDraft>> getDraft(String id) async {
    final result = await _guard(
      () => _client
          .from('products')
          .select(AdminProductModels.draftColumns)
          .eq('id', id)
          .maybeSingle(),
      isWrite: false,
    );
    return switch (result) {
      Success(value: null) => const Failed(
        NotFoundFailure('Peça não encontrada.'),
      ),
      Success(:final value?) => Success(
        AdminProductModels.draftFromJson(value, imageUrl: _publicUrl),
      ),
      Failed(:final failure) => Failed(failure),
    };
  }

  @override
  Future<Result<void>> setActive(String id, {required bool active}) => _guard(
    () => _client.from('products').update({'is_active': active}).eq('id', id),
  );

  @override
  Future<Result<List<Category>>> listCategories() => _guard(() async {
    final rows = await _client
        .from('categories')
        .select('id, name, slug, gender')
        .eq('is_active', true)
        .order('position');
    return rows.map(CatalogModels.categoryFromJson).toList();
  }, isWrite: false);

  @override
  Future<Result<Category>> createCategory(String name, Gender gender) =>
      _guard(() async {
        final json = await _client.rpc<dynamic>(
          'create_category',
          params: {'p_name': name, 'p_gender': gender.name},
        );
        return CatalogModels.categoryFromJson(json as Map<String, dynamic>);
      });

  @override
  Future<Result<String>> uploadImage(String productId, PickedImage image) =>
      _guard(
        () async {
          final path = '$productId/${_uuid.v4()}.${image.extension}';
          await _client.storage
              .from(bucket)
              .uploadBinary(
                path,
                image.bytes,
                fileOptions: FileOptions(
                  contentType: image.contentType,
                  // Nome único por foto: pode ficar em cache "para sempre".
                  cacheControl: '31536000',
                ),
              );
          return path;
        },
        storageMessage: 'Não foi possível enviar uma das fotos. Tente de novo.',
      );

  @override
  Future<Result<SavedProduct>> save(ProductDraft draft) => _guard(() async {
    final json =
        await _client.rpc<dynamic>(
              'save_product',
              params: AdminProductModels.saveParams(draft),
            )
            as Map<String, dynamic>;
    return SavedProduct(id: json['id'] as String, slug: json['slug'] as String);
  });

  @override
  Future<void> removeImages(List<String> storagePaths) async {
    try {
      await _client.storage.from(bucket).remove(storagePaths);
    } on Object {
      // Arquivo órfão no bucket não afeta a vitrine (não há listagem pública).
    }
  }

  Future<Result<T>> _guard<T>(
    Future<T> Function() run, {
    String? storageMessage,
    bool isWrite = true,
  }) async {
    try {
      return Success(await run());
    } on PostgrestException catch (error) {
      return Failed(isWrite ? saveFailure(error) : mapSupabaseError(error));
    } on StorageException {
      return Failed(
        ServerFailure(storageMessage ?? 'Não foi possível acessar as fotos.'),
      );
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }

  /// Mensagens amigáveis para os erros das RPCs (`raise exception '<código>'`).
  static Failure saveFailure(PostgrestException error) {
    final reason = error.message;
    final message = switch (reason) {
      'forbidden' => 'Sua sessão expirou. Entre de novo.',
      'duplicate_variant' => 'Tem cor e tamanho repetidos na grade.',
      'invalid_stock' => 'Estoque inválido (use números de 0 a 99999).',
      'invalid_variants' => 'Informe o estoque de ao menos uma combinação.',
      'too_many_images' => 'Máximo de 8 fotos por peça.',
      'image_not_found' || 'invalid_image' =>
        'Uma foto não terminou de enviar. Tente salvar de novo.',
      'invalid_category' => 'Nome da categoria: 1 a 60 letras.',
      _ when error.code == '23514' => 'Confira o preço e os campos da peça.',
      _ when error.code == '23505' => 'Tem cor e tamanho repetidos na grade.',
      _ => 'Não foi possível salvar agora. Tente novamente.',
    };
    if (reason == 'forbidden' || error.code == '42501') {
      return UnauthorizedFailure(message);
    }
    return ServerFailure(message, reason);
  }
}
