import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/store/data/datasources/store_remote_datasource.dart';
import 'package:joyjoy/features/store/data/models/store_settings_model.dart';
import 'package:joyjoy/features/store/data/repositories/store_repository_impl.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';
import 'package:joyjoy/features/store/domain/usecases/get_store_settings.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';

import '../../helpers/fakes.dart';

class _Remote implements StoreRemoteDataSource {
  _Remote(this.row);
  final Map<String, dynamic>? row;

  @override
  Future<Map<String, dynamic>> fetchSettings() async =>
      row ?? (throw Exception('offline'));
}

void main() {
  const row = {
    'store_name': 'JOYJOY',
    'whatsapp_number': '5581986323686',
    'greeting_message': 'Olá!',
    'announcement': 'Entregas em Recife',
    'is_open': false,
    'closed_message': 'Voltamos segunda',
    'low_stock_threshold': 3,
  };

  test('StoreSettingsModel lê todos os campos', () {
    final settings = StoreSettingsModel.fromJson(row);

    expect(settings.whatsappNumber, '5581986323686');
    expect(settings.isOpen, isFalse);
    expect(settings.closedMessage, 'Voltamos segunda');
    expect(settings.lowStockThreshold, 3);
    expect(settings.hasAnnouncement, isTrue);
  });

  test('recado só com espaços não conta como recado', () {
    const settings = StoreSettings(
      storeName: 'x',
      whatsappNumber: '5581986323686',
      greetingMessage: 'x',
      isOpen: true,
      lowStockThreshold: 2,
      announcement: '   ',
    );

    expect(settings.hasAnnouncement, isFalse);
  });

  test('StoreRepositoryImpl: sucesso e falha de rede', () async {
    expect(
      await StoreRepositoryImpl(_Remote(row)).getSettings(),
      isA<Success<StoreSettings>>(),
    );
    final failed = await StoreRepositoryImpl(_Remote(null)).getSettings();
    expect((failed as Failed).failure, isA<NetworkFailure>());
  });

  group('StoreController', () {
    setUp(() => Get.testMode = true);
    tearDown(Get.reset);

    test('carrega a configuração ao iniciar', () async {
      final controller = Get.put(
        StoreController(
          getStoreSettings: GetStoreSettings(FakeStoreRepository()),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.settings.value?.whatsappNumber, '5581986323686');
      expect(controller.lowStockThreshold, 2);
      expect(controller.isOpen, isTrue);
    });

    test(
      'se falhar, segue com padrões seguros (loja aberta, limite 2)',
      () async {
        final controller = Get.put(
          StoreController(
            getStoreSettings: GetStoreSettings(FakeStoreRepository(null)),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(controller.settings.value, isNull);
        expect(controller.isOpen, isTrue);
        expect(
          controller.lowStockThreshold,
          StoreController.defaultLowStockThreshold,
        );
      },
    );
  });
}
