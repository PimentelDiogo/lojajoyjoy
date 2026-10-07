import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/utils/currency.dart';
import 'package:joyjoy/features/admin/products/data/admin_product_models.dart';
import 'package:joyjoy/features/admin/products/domain/admin_products.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

ProductDraft draft({
  String name = 'Saia Plissada',
  num? price = 159.9,
  num? compareAtPrice,
  List<DraftImage> images = const [],
  List<DraftColor> colors = const [DraftColor(key: 'a', name: 'Rosa')],
  List<String> sizes = const ['P', 'M'],
  Map<String, DraftCell> cells = const {'a|P': DraftCell(stock: 2)},
  List<String> removed = const [],
}) => ProductDraft(
  id: 'id-1',
  isNew: true,
  name: name,
  gender: Gender.feminino,
  price: price,
  compareAtPrice: compareAtPrice,
  images: images,
  colors: colors,
  sizes: sizes,
  cells: cells,
  removedImagePaths: removed,
);

void main() {
  group('Currency.parse (preço digitado pela Ana)', () {
    test('aceita formatos comuns', () {
      expect(Currency.parse('189,90'), 189.9);
      expect(Currency.parse('1.299,90'), 1299.9);
      expect(Currency.parse(r'R$ 59'), 59);
      expect(Currency.parse('59.9'), 59.9);
      expect(Currency.parse('1.299'), 1299);
      expect(Currency.parse(brl('189,90')), 189.9);
    });

    test('recusa valores inválidos', () {
      for (final bad in ['', 'abc', '10,999', '1,2,3', '-5', null]) {
        expect(Currency.parse(bad), isNull, reason: '$bad');
      }
    });

    test('formatInput volta para o campo com vírgula', () {
      expect(Currency.formatInput(189.9), '189,90');
    });
  });

  group('ProductDraft', () {
    test('variantes = células com estoque (vazio = não existe)', () {
      final d = draft(
        colors: const [
          DraftColor(key: 'a', name: ' Rosa ', hex: '#F4A7B9'),
          DraftColor(key: 'b', name: 'Areia'),
        ],
        cells: const {
          'a|P': DraftCell(variantId: 'v1', stock: 3, baseStock: 1),
          'a|M': DraftCell(stock: 0),
          'b|M': DraftCell(stock: 4),
        },
      );

      expect(d.variants, const [
        DraftVariant(
          id: 'v1',
          size: 'P',
          colorName: 'Rosa',
          colorHex: '#F4A7B9',
          stock: 3,
          baseStock: 1,
        ),
        DraftVariant(
          size: 'M',
          colorName: 'Rosa',
          colorHex: '#F4A7B9',
          stock: 0,
        ),
        DraftVariant(size: 'M', colorName: 'Areia', stock: 4),
      ]);
      expect(d.totalStock, 7);
    });

    test('peça válida não tem erros', () {
      expect(draft().validate(), isEmpty);
    });

    test('valida nome, preço, preço "de" e grade', () {
      expect(draft(name: '  ').validate(), contains(ProductField.name));
      expect(draft(name: 'x' * 121).validate(), contains(ProductField.name));
      expect(draft(price: null).validate(), contains(ProductField.price));
      expect(draft(price: 0).validate(), contains(ProductField.price));
      expect(
        draft(compareAtPrice: 100).validate(),
        contains(ProductField.compareAtPrice),
      );
      expect(draft(compareAtPrice: 199.9).validate(), isEmpty);
      expect(
        draft(colors: const []).validate()[ProductField.variants],
        'Adicione ao menos uma cor e um tamanho.',
      );
      expect(
        draft(cells: const {}).validate()[ProductField.variants],
        startsWith('Informe o estoque'),
      );
      expect(
        draft(
          colors: const [
            DraftColor(key: 'a', name: 'Rosa'),
            DraftColor(key: 'b', name: 'rosa'),
          ],
        ).validate()[ProductField.variants],
        'Tem duas cores com o mesmo nome.',
      );
      expect(
        draft(
          images: List.generate(
            9,
            (i) => DraftImage(key: '$i', storagePath: 'id-1/$i.webp'),
          ),
        ).validate(),
        contains(ProductField.images),
      );
    });

    test('fitWithin reduz o lado maior sem ampliar', () {
      expect(fitWithin(4000, 3000, 1600), (width: 1600, height: 1200));
      expect(fitWithin(3000, 4000, 1600), (width: 1200, height: 1600));
      expect(fitWithin(800, 600, 1600), (width: 800, height: 600));
    });
  });

  group('SaveProduct', () {
    late FakeAdminProductRepository repo;
    late SaveProduct save;

    setUp(() {
      repo = FakeAdminProductRepository();
      save = SaveProduct(repo);
    });

    final withPhotos = draft(
      images: [
        const DraftImage(key: 'old', storagePath: 'id-1/old.webp'),
        DraftImage(key: 'n1', picked: fakePickedImage()),
      ],
      removed: const ['id-1/tirada.webp'],
    );

    test('com erro de validação não envia nada', () async {
      final result = await save(draft(name: '', images: withPhotos.images));

      expect(
        (result as Failed).failure,
        isA<ProductValidationFailure>().having(
          (f) => f.errors.keys,
          'campos',
          contains(ProductField.name),
        ),
      );
      expect(repo.uploads, isEmpty);
      expect(repo.saved, isEmpty);
    });

    test(
      'envia as fotos novas, salva com os caminhos e apaga as removidas',
      () async {
        final result = await save(withPhotos);

        expect(result.isSuccess, isTrue);
        expect(repo.uploads, ['id-1/foto-0.webp']);
        expect(
          repo.saved.single.images.map((i) => i.storagePath),
          ['id-1/old.webp', 'id-1/foto-0.webp'],
        );
        expect(repo.removed, [
          ['id-1/tirada.webp'],
        ]);
      },
    );

    test('se salvar falhar, apaga as fotos que acabou de enviar', () async {
      repo.saveFailure = const ServerFailure('falhou');

      final result = await save(withPhotos);

      expect((result as Failed).failure.message, 'falhou');
      expect(repo.removed, [
        ['id-1/foto-0.webp'],
      ]);
    });

    test('se o envio de uma foto falhar, nem chama o salvar', () async {
      repo.uploadFailure = const ServerFailure('sem rede');

      final result = await save(withPhotos);

      expect(result.isFailure, isTrue);
      expect(repo.saved, isEmpty);
      expect(repo.removed, isEmpty);
    });
  });

  test('CreateCategory recusa nome vazio', () async {
    final result = await CreateCategory(FakeAdminProductRepository())((
      name: '  ',
      gender: Gender.feminino,
    ));
    expect((result as Failed).failure, isA<ValidationFailure>());
  });

  group('AdminProductModels', () {
    String url(String path) => 'https://cdn/$path';

    test('monta a grade a partir das variantes ativas', () {
      final d = AdminProductModels.draftFromJson({
        'id': 'p1',
        'name': 'Vestido',
        'slug': 'vestido',
        'description': null,
        'gender': 'feminino',
        'category_id': null,
        'base_price': '189.90',
        'compare_at_price': null,
        'is_active': true,
        'is_featured': false,
        'product_images': [
          {'storage_path': 'p1/b.webp', 'position': 1},
          {'storage_path': 'p1/a.webp', 'position': 0},
        ],
        'product_variants': [
          {
            'id': 'v2',
            'size': 'G',
            'color_name': 'Rosa',
            'color_hex': '#F4A7B9',
            'stock_qty': 0,
            'is_active': true,
            'created_at': '2026-10-01T10:00:01Z',
          },
          {
            'id': 'v1',
            'size': 'P',
            'color_name': 'Rosa',
            'color_hex': '#F4A7B9',
            'stock_qty': 3,
            'is_active': true,
            'created_at': '2026-10-01T10:00:00Z',
          },
          {
            'id': 'v3',
            'size': 'M',
            'color_name': 'Areia',
            'color_hex': null,
            'stock_qty': 2,
            'is_active': false,
            'created_at': '2026-10-01T10:00:02Z',
          },
        ],
      }, imageUrl: url);

      expect(d.price, 189.9);
      expect(d.images.map((i) => i.url), [
        'https://cdn/p1/a.webp',
        'https://cdn/p1/b.webp',
      ]);
      expect(d.colors.map((c) => c.name), ['Rosa'], reason: 'Areia inativa');
      expect(d.sizes, ['P', 'G']);
      expect(
        d.cell('c0', 'P'),
        const DraftCell(variantId: 'v1', stock: 3, baseStock: 3),
      );
    });

    test('parâmetros do save_product: só o necessário', () {
      final params = AdminProductModels.saveParams(
        fakeDraft().copyWith(
          images: const [DraftImage(key: 'x', storagePath: 'p1/x.webp')],
        ),
      );

      expect(params['p_images'], ['p1/x.webp']);
      expect(params['p_variants'], [
        {
          'id': 'v1',
          'size': 'P',
          'color_name': 'Rosa',
          'color_hex': '#F4A7B9',
          'stock': 3,
          'base_stock': 3,
        },
        {
          'id': 'v2',
          'size': 'M',
          'color_name': 'Rosa',
          'color_hex': '#F4A7B9',
          'stock': 1,
          'base_stock': 1,
        },
      ]);
      final product = params['p_product'] as Map<String, dynamic>;
      expect(product['base_price'], 189.9);
      expect(product.containsKey('slug'), isFalse, reason: 'slug é do banco');
    });
  });
}
