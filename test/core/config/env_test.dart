import 'package:flutter_test/flutter_test.dart';
import 'package:ondas_que_faltam/core/config/env.dart';

void main() {
  group('Env', () {
    test('considera o Supabase configurado quando URL e anon key existem', () {
      const env = Env(
        supabaseUrl: 'http://127.0.0.1:54321',
        supabaseAnonKey: 'anon',
        appBaseUrl: 'http://localhost:8080',
      );

      expect(env.isSupabaseConfigured, isTrue);
      expect(env.missingKeys, isEmpty);
    });

    test('lista as chaves ausentes (vazias ou só espaços)', () {
      const env = Env(
        supabaseUrl: '  ',
        supabaseAnonKey: '',
        appBaseUrl: 'http://localhost:8080',
      );

      expect(env.isSupabaseConfigured, isFalse);
      expect(env.missingKeys, ['SUPABASE_URL', 'SUPABASE_ANON_KEY']);
    });

    test('fromEnvironment sem dart-define usa a URL base local', () {
      final env = Env.fromEnvironment();

      expect(env.appBaseUrl, 'http://localhost:8080');
    });

    test('absoluteUri monta o link completo a partir da URL base', () {
      const env = Env(
        supabaseUrl: 'x',
        supabaseAnonKey: 'y',
        appBaseUrl: 'https://ondasquefaltam.com.br',
      );

      expect(
        env.absoluteUri('/pedido/K7P2QX').toString(),
        'https://ondasquefaltam.com.br/pedido/K7P2QX',
      );
    });
  });
}
