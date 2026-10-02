import 'package:flutter_test/flutter_test.dart';
import 'package:ondas_que_faltam/core/services/key_value_store.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('InMemoryKeyValueStore', () {
    test('lê, grava e remove', () async {
      final store = InMemoryKeyValueStore({'a': '1'});

      expect(store.read('a'), '1');
      await store.write('b', '2');
      expect(store.read('b'), '2');
      await store.remove('a');
      expect(store.read('a'), isNull);
    });

    test('não altera o mapa inicial recebido', () async {
      final initial = {'a': '1'};
      final store = InMemoryKeyValueStore(initial);

      await store.write('a', 'x');

      expect(initial['a'], '1');
    });
  });

  group('SharedPreferencesKeyValueStore', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('lê, grava e remove', () async {
      final store = await SharedPreferencesKeyValueStore.create();

      expect(store.read('theme_mode'), isNull);
      await store.write('theme_mode', 'dark');
      expect(store.read('theme_mode'), 'dark');
      await store.remove('theme_mode');
      expect(store.read('theme_mode'), isNull);
    });

    test('persiste entre instâncias (simula recarregar a página)', () async {
      final first = await SharedPreferencesKeyValueStore.create();
      await first.write('theme_mode', 'light');

      final second = await SharedPreferencesKeyValueStore.create();

      expect(second.read('theme_mode'), 'light');
    });
  });
}
