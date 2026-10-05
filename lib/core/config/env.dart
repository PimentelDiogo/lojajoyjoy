/// Configuração de ambiente injetada via `--dart-define-from-file=env/<ambiente>.json`.
///
/// A classe é instanciável (não só constantes) para poder ser testada e
/// injetada pelo `InitialBinding`.
final class Env {
  const Env({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.appBaseUrl,
  });

  /// Lê os valores definidos em tempo de compilação.
  factory Env.fromEnvironment() => const Env(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    appBaseUrl: String.fromEnvironment(
      'APP_BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String appBaseUrl;

  /// Chaves obrigatórias que não foram informadas.
  List<String> get missingKeys => [
    if (supabaseUrl.trim().isEmpty) 'SUPABASE_URL',
    if (supabaseAnonKey.trim().isEmpty) 'SUPABASE_ANON_KEY',
  ];

  bool get isSupabaseConfigured => missingKeys.isEmpty;

  /// URL absoluta de um caminho do app (ex.: link do pedido na mensagem do
  /// WhatsApp). Preserva o subcaminho da base — no GitHub Pages a base é
  /// `https://<user>.github.io/lojajoyjoy` e `Uri.resolve('/pedido/X')`
  /// descartaria o `/lojajoyjoy`.
  Uri absoluteUri(String path) {
    final base = Uri.parse(appBaseUrl);
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final relative = path.startsWith('/') ? path : '/$path';
    return base.replace(path: '$basePath$relative');
  }
}
