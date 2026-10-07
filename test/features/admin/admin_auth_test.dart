import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/middlewares/admin_guard.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/core/utils/safe_redirect.dart';
import 'package:joyjoy/features/admin/auth/domain/auth.dart';
import 'package:joyjoy/features/admin/auth/presentation/controllers/auth_controller.dart';
import 'package:joyjoy/features/admin/dashboard/domain/dashboard.dart';

import '../../helpers/fakes.dart';

void main() {
  group('safeNextPath (sem open redirect)', () {
    test('aceita caminhos internos das áreas permitidas', () {
      expect(safeNextPath('/admin'), '/admin');
      expect(safeNextPath('/admin/produtos?x=1'), '/admin/produtos?x=1');
      expect(safeNextPath('/pedido/K7P2QX'), '/pedido/K7P2QX');
    });

    test(
      'rejeita externos, protocolo, barras duplas e áreas fora da lista',
      () {
        for (final bad in [
          null,
          '',
          'https://evil.com',
          '//evil.com/admin',
          r'/\evil.com',
          'javascript:alert(1)',
          'admin',
          '/carrinho',
          '/adminxyz',
          '/pedido',
          '/admin/login',
          '/admin/login?next=/admin',
        ]) {
          expect(safeNextPath(bad), isNull, reason: '$bad');
        }
      },
    );
  });

  group('AuthController', () {
    setUp(() => Get.testMode = true);
    tearDown(Get.reset);

    AuthController create(FakeAuthRepository repo) => Get.put(
      AuthController(
        repository: repo,
        signInUseCase: SignIn(repo),
        getCurrentAdmin: GetCurrentAdmin(repo),
        signOutUseCase: SignOut(repo),
      ),
    );

    test('login certo vira admin; errado devolve a mensagem', () async {
      final auth = create(FakeAuthRepository());

      expect(
        (await auth.signIn(email: 'ana@joyjoy.com.br', password: 'x'))!.message,
        'E-mail ou senha incorretos.',
      );
      expect(auth.isAdmin, isFalse);

      expect(
        await auth.signIn(email: 'ana@joyjoy.com.br', password: 'senha-certa'),
        isNull,
      );
      expect(auth.admin.value, fakeAdmin);
    });

    test(
      'usuário que não é admin não entra (e a sessão é encerrada)',
      () async {
        final repo = FakeAuthRepository(isAdmin: false);
        final auth = create(repo);

        final failure = await auth.signIn(
          email: 'x@x.com',
          password: 'senha-certa',
        );

        expect(failure!.message, contains('não tem acesso'));
        expect(auth.isAdmin, isFalse);
        expect(repo.hasSession, isFalse);
      },
    );

    test('ensureAdmin confirma a sessão salva; signOut limpa', () async {
      final repo = FakeAuthRepository(session: true);
      final auth = create(repo);

      expect(await auth.ensureAdmin(), isTrue);
      await auth.signOut();
      expect(auth.isAdmin, isFalse);
      expect(repo.signOuts, 1);
      expect(await auth.ensureAdmin(), isFalse);
    });
  });

  group('AdminGuard', () {
    setUp(() => Get.testMode = true);
    tearDown(Get.reset);

    test('sem sessão manda para o login com next; com sessão deixa passar', () {
      final repo = FakeAuthRepository();
      Get.put(
        AuthController(
          repository: repo,
          signInUseCase: SignIn(repo),
          getCurrentAdmin: GetCurrentAdmin(repo),
          signOutUseCase: SignOut(repo),
        ),
      );
      final guard = AdminGuard();

      expect(
        guard.redirect('/admin')?.name,
        AppRoutes.adminLoginPath(next: '/admin'),
      );
      repo.session = true;
      expect(guard.redirect('/admin'), isNull);
    });
  });

  test('GetAdminStats pede os últimos 7 dias', () async {
    final repo = FakeDashboardRepository();
    final now = DateTime(2026, 10, 7, 12);

    final result = await GetAdminStats(repo, now: () => now)(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(repo.lastSince, DateTime(2026, 9, 30, 12));
    expect(repo.stats.totalVisits, 19);
  });
}
