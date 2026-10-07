@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/admin/auth/data/auth_repository_impl.dart';
import 'package:joyjoy/features/admin/auth/domain/auth.dart';
import 'package:joyjoy/features/admin/dashboard/data/dashboard_repository_impl.dart';
import 'package:joyjoy/features/admin/dashboard/domain/dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Login real (seed local: ana@joyjoy.com.br) e leituras de admin via RLS.
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

  test('Ana entra e o banco confirma is_admin', () async {
    final client = newClient();
    final repo = AuthRepositoryImpl(client);

    final result = await repo.signIn(
      const SignInParams(email: 'ana@joyjoy.com.br', password: 'joy123'),
    );

    expect((result as Success<AdminUser>).value.email, 'ana@joyjoy.com.br');
    expect(repo.hasSession, isTrue);

    final stats = await DashboardRepositoryImpl(
      client,
    ).getStats(since: DateTime.now().subtract(const Duration(days: 7)));
    expect((stats as Success<AdminStats>).value.activeProducts, greaterThan(0));

    await repo.signOut();
    expect(repo.hasSession, isFalse);
    await client.dispose();
  });

  test('senha errada: mensagem genérica', () async {
    final client = newClient();
    final result = await AuthRepositoryImpl(client).signIn(
      const SignInParams(email: 'ana@joyjoy.com.br', password: 'errada'),
    );

    final failure = (result as Failed).failure;
    expect(failure, isA<UnauthorizedFailure>());
    expect(failure.message, 'E-mail ou senha incorretos.');
    await client.dispose();
  });

  test('sem login, o RLS esconde pedidos e visitas (contagem 0)', () async {
    final client = newClient();
    final stats = await DashboardRepositoryImpl(
      client,
    ).getStats(since: DateTime(2000));

    final value = (stats as Success<AdminStats>).value;
    expect(value.pendingOrders, 0);
    expect(value.totalVisits, 0);
    await client.dispose();
  });
}
