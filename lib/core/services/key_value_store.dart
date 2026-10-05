import 'package:shared_preferences/shared_preferences.dart';

/// Armazenamento chave-valor local (localStorage no web).
///
/// Abstração para que controllers não dependam do pacote de storage
/// diretamente e possam ser testados com [InMemoryKeyValueStore].
abstract interface class KeyValueStore {
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// Implementação com `shared_preferences` (compatível com o build `--wasm`;
/// o `get_storage` usa `dart:html` e não compila para WebAssembly).
final class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore(this._prefs);

  /// Carrega o cache uma vez (no `main`) para leituras síncronas.
  static Future<SharedPreferencesKeyValueStore> create() async =>
      SharedPreferencesKeyValueStore(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(),
        ),
      );

  final SharedPreferencesWithCache _prefs;

  @override
  String? read(String key) {
    final value = _prefs.get(key);
    return value is String ? value : null;
  }

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

final class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, String>? initial]) : _data = {...?initial};

  final Map<String, String> _data;

  @override
  String? read(String key) => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);
}
