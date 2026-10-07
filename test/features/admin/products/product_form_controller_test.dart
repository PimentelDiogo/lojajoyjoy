import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/features/admin/products/domain/admin_products.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';
import 'package:joyjoy/features/admin/products/presentation/controllers/product_form_controller.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';

import '../../../helpers/fakes.dart';

void main() {
  late FakeAdminProductRepository repo;
  late FakeImagePicker picker;

  ProductFormController build({String? id}) {
    final c = ProductFormController(
      productId: id,
      getProductDraft: GetProductDraft(repo),
      saveProduct: SaveProduct(repo),
      listCategories: ListAdminCategories(repo),
      createCategoryUseCase: CreateCategory(repo),
      imagePicker: picker,
      newId: () => 'novo-id',
    );
    addTearDown(c.onClose);
    return c;
  }

  setUp(() {
    repo = FakeAdminProductRepository();
    picker = FakeImagePicker();
  });

  test('peça nova usa o id gerado no app', () async {
    final c = build();
    await c.load();
    c.name.text = 'Blusa';
    c.price.text = '79,90';
    c
      ..addColor('Preto', '#1F1F1F')
      ..addSize('u')
      ..setStock('n0', 'U', '2');

    expect(await c.save(), isNull);
    expect(repo.saved.single.id, 'novo-id');
    expect(repo.saved.single.sizes, ['U'], reason: 'tamanho em maiúsculas');
  });

  test('tamanhos ficam em ordem e não repetem', () async {
    final c = build();
    await c.load();

    expect(c.addSize('G'), isNull);
    expect(c.addSize('pp'), isNull);
    expect(c.addSize('M'), isNull);
    expect(c.addSize('m'), 'Esse tamanho já está na peça.');
    expect(c.addSize('x' * 11), 'Tamanho: até 10 letras.');
    expect(c.sizes, ['PP', 'M', 'G']);
  });

  test(
    'remover cor/tamanho apaga as células e estoque vazio = não existe',
    () async {
      final c = build(id: 'p1');
      await c.load();
      expect(c.totalStock, 4);

      c.setStock('c0', 'P', '');
      expect(c.totalStock, 1);
      c.removeSize('M');
      expect(c.cells.keys, ['c0|P']);
      c.removeColor('c0');
      expect(c.cells, isEmpty);
    },
  );

  test('renomear cor mantém a variante (mesmo id)', () async {
    final c = build(id: 'p1');
    await c.load();

    expect(c.updateColor('c0', 'Rosa chá', '#F4A7B9'), isNull);
    await c.save();

    expect(
      repo.saved.single.variants.map((v) => '${v.id}:${v.colorName}'),
      ['v1:Rosa chá', 'v2:Rosa chá'],
    );
  });

  test('fotos: limite de 8, capa e remoção', () async {
    final c = build(id: 'p1');
    await c.load();
    picker.next = List.generate(10, (_) => fakePickedImage());

    await c.pickImages();
    expect(picker.lastMax, 6, reason: 'já tinha 2');
    expect(c.images, hasLength(ProductDraft.maxImages));
    expect(await c.pickImages(), 'Máximo de 8 fotos por peça.');

    c
      ..makeCover(1)
      ..removeImage(0);
    expect(c.images.first.storagePath, 'p1/capa.webp');
  });

  test('foto que não abre vira aviso', () async {
    final c = build();
    await c.load();
    picker
      ..next = []
      ..skipped = 2;

    expect(await c.pickImages(), startsWith('2 fotos não puderam'));
  });

  test('trocar a seção limpa categoria que não combina', () async {
    final c = build(id: 'p1');
    await c.load();
    expect(c.categoryId.value, 'c1');

    c.setGender(Gender.masculino);
    expect(c.categoryId.value, isNull);
    expect(c.categoriesForGender.map((x) => x.name), ['Camisas', 'Calças']);
  });

  test('preço "de" inválido é apontado antes de salvar', () async {
    final c = build(id: 'p1');
    await c.load();
    c.compareAtPrice.text = 'abc';

    expect(await c.save(), isA<ProductValidationFailure>());
    expect(c.errors.value, contains(ProductField.compareAtPrice));
    expect(repo.saved, isEmpty);
  });
}
