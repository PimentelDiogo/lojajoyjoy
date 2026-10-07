/// Nomes das rotas (URLs reais no navegador, via `usePathUrlStrategy`).
///
/// As rotas são registradas em `AppPages` à medida que cada feature é entregue.
abstract final class AppRoutes {
  static const landing = '/';
  static const feminino = '/feminino';
  static const masculino = '/masculino';
  static const product = '/produto/:slug';
  static const cart = '/carrinho';
  static const checkout = '/finalizar';
  static const order = '/pedido/:code';

  static const adminLogin = '/admin/login';
  static const admin = '/admin';

  static const notFound = '/404';

  /// Vitrine do design system — registrada só em debug.
  static const designSystem = '/design';

  static String adminLoginPath({String? next}) => next == null
      ? adminLogin
      : '$adminLogin?next=${Uri.encodeComponent(next)}';

  static String productPath(String slug) =>
      '/produto/${Uri.encodeComponent(slug)}';
  static String orderPath(String code) =>
      '/pedido/${Uri.encodeComponent(code)}';
}
