/// Caminho de retorno depois do login (`?next=`), só se for interno e esperado.
///
/// Evita open redirect: `//evil.com`, `https://…`, `javascript:` e caminhos
/// fora das áreas permitidas são descartados.
String? safeNextPath(
  String? next, {
  List<String> allowedPrefixes = const ['/admin', '/pedido/'],
}) {
  final value = next?.trim();
  if (value == null || value.isEmpty) return null;
  final external =
      !value.startsWith('/') || value.startsWith('//') || value.contains(r'\');
  if (external) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  final path = uri.path;
  bool allowed(String prefix) => prefix.endsWith('/')
      ? path.startsWith(prefix)
      : path == prefix || path.startsWith('$prefix/');
  if (!allowedPrefixes.any(allowed)) return null;
  if (path == '/admin/login' || path.startsWith('/admin/login/')) {
    return null;
  }
  return value;
}
