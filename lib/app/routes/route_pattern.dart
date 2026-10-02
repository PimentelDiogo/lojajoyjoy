/// Compara um caminho real (`/produto/vestido-midi`) com o padrão de rota
/// do GetX (`/produto/:slug`) exigindo correspondência **exata**.
///
/// Necessário porque o GetX resolve rotas como árvore de prefixos: sem isso,
/// qualquer URL desconhecida cairia em `/` (landing) em vez do 404.
final class RoutePattern {
  RoutePattern(this.pattern) : _regex = _compile(pattern);

  final String pattern;
  final RegExp _regex;

  bool matches(String route) =>
      _regex.hasMatch(_normalize(Uri.parse(route).path));

  static RegExp _compile(String pattern) {
    final segments = _normalize(pattern)
        .split('/')
        .where((s) => s.isNotEmpty)
        .map((s) => s.startsWith(':') ? '[^/]+' : RegExp.escape(s));
    return RegExp('^/${segments.join('/')}\$');
  }

  /// Remove barra final (exceto na raiz) para `/feminino/` == `/feminino`.
  static String _normalize(String path) {
    if (path.isEmpty) return '/';
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }
}
