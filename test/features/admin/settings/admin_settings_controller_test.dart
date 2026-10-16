import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/features/admin/settings/domain/admin_settings.dart';
import 'package:joyjoy/features/admin/settings/presentation/admin_settings_controller.dart';
import 'package:joyjoy/features/store/domain/usecases/get_store_settings.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';

import '../../../helpers/fakes.dart';

void main() {
  late FakeAdminSettingsRepository repo;
  late FakeStoreRepository storeRepo;
  late StoreController store;

  AdminSettingsController build() {
    store = StoreController(getStoreSettings: GetStoreSettings(storeRepo));
    final c = AdminSettingsController(
      store: store,
      startStockAudit: StartStockAudit(repo),
      stopStockAudit: StopStockAudit(repo),
    );
    addTearDown(c.onClose);
    addTearDown(store.onClose);
    return c;
  }

  setUp(() {
    repo = FakeAdminSettingsRepository();
    storeRepo = FakeStoreRepository();
  });

  test('loja aberta: não está em auditoria', () async {
    final c = build();
    await store.load();
    expect(c.inStockAudit, isFalse);
  });

  test('inicia auditoria de 30 min e reflete no StoreController', () async {
    final c = build();
    await store.load();

    expect(await c.start(30), isNull);
    expect(repo.startedWith, [30]);
    expect(c.inStockAudit, isTrue);
    expect(store.isOpen, isFalse);
    expect(
      store.settings.value?.stockAuditEndsAt?.isAfter(DateTime.now().toUtc()),
      isTrue,
    );
  });

  test(
    'minutos fora de 15/30/60 é recusado antes de chamar o servidor',
    () async {
      final c = build();
      await store.load();

      final failure = await c.start(45);
      expect(failure, isA<ValidationFailure>());
      expect(repo.startedWith, isEmpty);
    },
  );

  test('para a auditoria: reabre a loja e limpa o prazo', () async {
    final c = build();
    await store.load();
    await c.start(15);
    expect(c.inStockAudit, isTrue);

    expect(await c.stop(), isNull);
    expect(repo.stopCalls, 1);
    expect(c.inStockAudit, isFalse);
    expect(store.isOpen, isTrue);
    expect(store.settings.value?.stockAuditEndsAt, isNull);
  });

  test('erro do servidor não muda o estado local', () async {
    final c = build();
    await store.load();
    repo.failure = const ServerFailure('Falhou.');

    final failure = await c.start(15);
    expect(failure, isA<ServerFailure>());
    expect(c.inStockAudit, isFalse);
  });

  test('chamada dupla enquanto salva é ignorada', () async {
    final c = build();
    await store.load();

    final first = c.start(15);
    final second = await c.start(30);
    expect(second, isNull);
    await first;
    expect(repo.startedWith, [15]);
  });
}
