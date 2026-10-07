@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/admin/products/data/admin_product_repository_impl.dart';
import 'package:joyjoy/features/admin/products/domain/admin_products.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../helpers/fakes.dart';

/// Cadastro real contra o Supabase local (seed: ana@joyjoy.com.br):
/// upload no Storage → save_product → leitura da grade → limpeza.
void main() {
  late Map<String, dynamic> env;

  setUpAll(() {
    env =
        jsonDecode(File('env/local.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  SupabaseClient newClient() => SupabaseClient(
    env['SUPABASE_URL'] as String,
    env['SUPABASE_ANON_KEY'] as String,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

  Future<SupabaseClient> signedIn() async {
    final client = newClient();
    await client.auth.signInWithPassword(
      email: 'ana@joyjoy.com.br',
      password: 'joy123',
    );
    return client;
  }

  final png = PickedImage(
    bytes: fakePickedImage().bytes,
    contentType: 'image/png',
  );

  test('Ana cadastra, edita e oculta uma peça com foto', () async {
    final client = await signedIn();
    final repo = AdminProductRepositoryImpl(client);
    final id = const Uuid().v4();
    final save = SaveProduct(repo);

    final category = await repo.createCategory(
      'Teste Integração',
      Gender.feminino,
    );
    final categoryId = (category as Success<Category>).value.id;

    final created = await save(
      ProductDraft(
        id: id,
        isNew: true,
        name: 'Saia Teste Integração',
        gender: Gender.feminino,
        categoryId: categoryId,
        price: 99.9,
        images: [DraftImage(key: 'n', picked: png)],
        colors: const [DraftColor(key: 'a', name: 'Rosa', hex: '#F4A7B9')],
        sizes: const ['P', 'M'],
        cells: const {'a|P': DraftCell(stock: 2), 'a|M': DraftCell(stock: 0)},
      ),
    );
    final slug = (created as Success<SavedProduct>).value.slug;
    expect(slug, startsWith('saia-teste-integracao'));

    final draft = (await repo.getDraft(id) as Success<ProductDraft>).value;
    expect(draft.images.single.storagePath, startsWith('$id/'));
    expect(draft.variants.map((v) => '${v.size}:${v.stock}'), ['P:2', 'M:0']);

    // A foto sobe com URL pública (vitrine).
    final photo = await HttpClient()
        .getUrl(Uri.parse(draft.images.single.url!))
        .then((r) => r.close());
    expect(photo.statusCode, 200);
    await photo.drain<void>();

    // Edição: estoque por diferença, tira o M e troca a foto.
    final p = draft.variants.firstWhere((v) => v.size == 'P');
    final edited = await save(
      ProductDraft(
        id: id,
        isNew: false,
        name: 'Saia Teste Integração',
        gender: Gender.feminino,
        price: 89.9,
        images: [DraftImage(key: 'n2', picked: png)],
        colors: draft.colors,
        sizes: const ['P'],
        cells: {
          'c0|P': DraftCell(variantId: p.id, stock: 5, baseStock: p.stock),
        },
        removedImagePaths: [draft.images.single.storagePath!],
      ),
    );
    expect(edited.isSuccess, isTrue);
    final after = (await repo.getDraft(id) as Success<ProductDraft>).value;
    expect(after.variants.single.stock, 5);
    expect(
      after.images.single.storagePath,
      isNot(draft.images.single.storagePath),
    );

    expect(await repo.setActive(id, active: false), isA<Success<void>>());
    final list =
        (await repo.listProducts() as Success<List<AdminProductSummary>>).value;
    expect(list.firstWhere((x) => x.id == id).isActive, isFalse);

    // Visitante não vê a peça oculta.
    final anon = newClient();
    final visible = await anon.from('products').select('id').eq('id', id);
    expect(visible, isEmpty);
    await anon.dispose();

    // Limpeza.
    await repo.removeImages([after.images.single.storagePath!]);
    await client.from('products').delete().eq('id', id);
    await client.from('categories').delete().eq('id', categoryId);
    await client.auth.signOut();
    await client.dispose();
  });

  test('sem login não envia foto nem salva', () async {
    final client = newClient();
    final repo = AdminProductRepositoryImpl(client);
    final id = const Uuid().v4();

    final upload = await repo.uploadImage(id, png);
    expect(upload.isFailure, isTrue);

    final saved = await repo.save(
      ProductDraft(
        id: id,
        isNew: true,
        name: 'Invasora',
        gender: Gender.feminino,
        price: 1,
        colors: const [DraftColor(key: 'a', name: 'Preto')],
        sizes: const ['U'],
        cells: const {'a|U': DraftCell(stock: 1)},
      ),
    );
    expect((saved as Failed).failure, isA<UnauthorizedFailure>());
    await client.dispose();
  });
}
