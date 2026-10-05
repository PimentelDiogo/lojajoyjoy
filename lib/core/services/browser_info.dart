import 'package:joyjoy/core/services/browser_info_stub.dart'
    if (dart.library.js_interop) 'package:joyjoy/core/services/browser_info_web.dart'
    as impl;

/// Dados do navegador usados para descobrir a origem do acesso (ADR-0007).
class BrowserInfo {
  const BrowserInfo({
    required this.url,
    required this.userAgent,
    required this.referrer,
  });

  /// Lê do navegador atual (no VM/testes devolve valores vazios).
  factory BrowserInfo.current() => impl.currentBrowserInfo();

  final Uri url;
  final String userAgent;
  final String referrer;
}
