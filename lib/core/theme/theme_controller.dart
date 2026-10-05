import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/services/key_value_store.dart';

/// Tema escolhido pela pessoa: Automático (sistema) → Claro → Escuro.
/// Persistido no navegador para valer na próxima visita.
class ThemeController extends GetxController {
  ThemeController(this._store);

  static const storageKey = 'theme_mode';

  final KeyValueStore _store;
  final Rx<ThemeMode> mode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    mode.value = _parse(_store.read(storageKey));
  }

  Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    await _store.write(storageKey, value.name);
  }

  /// Ordem do botão: Automático → Claro → Escuro → Automático.
  Future<void> cycle() => setMode(switch (mode.value) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });

  static ThemeMode _parse(String? raw) => ThemeMode.values.firstWhere(
    (m) => m.name == raw,
    orElse: () => ThemeMode.system,
  );
}
