import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/core/theme/theme_controller.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  ThemeController create([Map<String, String>? stored]) =>
      Get.put(ThemeController(InMemoryKeyValueStore(stored)));

  test('sem preferência salva usa o tema do sistema', () {
    expect(create().mode.value, ThemeMode.system);
  });

  test('restaura a preferência salva', () {
    final controller = create({ThemeController.storageKey: 'dark'});

    expect(controller.mode.value, ThemeMode.dark);
  });

  test('valor salvo inválido volta para o sistema', () {
    final controller = create({ThemeController.storageKey: 'roxo'});

    expect(controller.mode.value, ThemeMode.system);
  });

  test('setMode atualiza e persiste', () async {
    final store = InMemoryKeyValueStore();
    final controller = Get.put(ThemeController(store));

    await controller.setMode(ThemeMode.light);

    expect(controller.mode.value, ThemeMode.light);
    expect(store.read(ThemeController.storageKey), 'light');
  });

  test('cycle: automático → claro → escuro → automático', () async {
    final controller = create();
    final seen = <ThemeMode>[];

    for (var i = 0; i < 3; i++) {
      await controller.cycle();
      seen.add(controller.mode.value);
    }

    expect(seen, [ThemeMode.light, ThemeMode.dark, ThemeMode.system]);
  });
}
