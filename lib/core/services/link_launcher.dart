import 'package:url_launcher/url_launcher.dart';

/// Abre links externos (WhatsApp, Instagram). Abstração para testes.
abstract interface class LinkLauncher {
  Future<bool> open(Uri uri);
}

class UrlLauncherLinkLauncher implements LinkLauncher {
  const UrlLauncherLinkLauncher();

  /// Mesma aba (`_self`): no navegador do Instagram, `_blank` costuma ser
  /// bloqueado (ADR-0001).
  @override
  Future<bool> open(Uri uri) => launchUrl(uri, webOnlyWindowName: '_self');
}
