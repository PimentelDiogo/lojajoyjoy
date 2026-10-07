import 'package:equatable/equatable.dart';

/// Canal de onde o cliente veio (enum `traffic_source` do banco).
enum TrafficSource {
  instagram('Instagram'),
  whatsapp('WhatsApp'),
  facebook('Facebook'),
  busca('Busca (Google)'),
  qrcode('QR code'),
  site('Direto no site'),
  outro('Outros');

  const TrafficSource(this.label);

  /// Como a Ana vê no painel.
  final String label;

  /// Rótulo pelo nome do banco (`instagram`…); o próprio texto se desconhecido.
  static String labelOf(String name) {
    for (final source in values) {
      if (source.name == name) return source.label;
    }
    return name;
  }
}

/// Resultado da detecção de origem.
class SourceDetection extends Equatable {
  const SourceDetection({
    required this.source,
    this.campaign,
    this.referrerHost,
  });

  final TrafficSource source;
  final String? campaign;
  final String? referrerHost;

  @override
  List<Object?> get props => [source, campaign, referrerHost];
}

/// Descobre a origem do acesso (ADR-0007). Prioridade:
/// 1. `?src=` / `?utm_source=` (links oficiais da Ana — o mais confiável);
/// 2. navegador embutido (User-Agent do Instagram / Facebook);
/// 3. `document.referrer`;
/// 4. senão, `site` (acesso direto).
abstract final class SourceDetector {
  static SourceDetection detect({
    required Uri url,
    required String userAgent,
    required String referrer,
  }) {
    final params = url.queryParameters;
    final campaign = _clean(params['utm_campaign']);
    final referrerHost = _host(referrer);

    final explicit = _fromParam(params['src'] ?? params['utm_source']);
    if (explicit != null) {
      return SourceDetection(
        source: explicit,
        campaign: campaign,
        referrerHost: referrerHost,
      );
    }

    final fromAgent = _fromUserAgent(userAgent);
    if (fromAgent != null) {
      return SourceDetection(
        source: fromAgent,
        campaign: campaign,
        referrerHost: referrerHost,
      );
    }

    return SourceDetection(
      source: _fromReferrer(referrerHost, ownHost: url.host),
      campaign: campaign,
      referrerHost: referrerHost,
    );
  }

  static TrafficSource? _fromParam(String? value) {
    final v = value?.trim().toLowerCase();
    if (v == null || v.isEmpty) return null;
    return switch (v) {
      'instagram' || 'ig' => TrafficSource.instagram,
      'whatsapp' || 'wa' || 'zap' => TrafficSource.whatsapp,
      'facebook' || 'fb' => TrafficSource.facebook,
      'qrcode' || 'qr' => TrafficSource.qrcode,
      'google' || 'bing' || 'busca' => TrafficSource.busca,
      'site' || 'direto' => TrafficSource.site,
      _ => TrafficSource.outro,
    };
  }

  static TrafficSource? _fromUserAgent(String userAgent) {
    if (userAgent.contains('Instagram')) return TrafficSource.instagram;
    if (userAgent.contains('FBAN') || userAgent.contains('FBAV')) {
      return TrafficSource.facebook;
    }
    if (userAgent.contains('WhatsApp')) return TrafficSource.whatsapp;
    return null;
  }

  static TrafficSource _fromReferrer(String? host, {required String ownHost}) {
    if (host == null || host == ownHost) return TrafficSource.site;
    bool endsWithAny(List<String> domains) =>
        domains.any((d) => host == d || host.endsWith('.$d'));
    if (endsWithAny(['instagram.com'])) return TrafficSource.instagram;
    if (endsWithAny(['wa.me', 'whatsapp.com'])) return TrafficSource.whatsapp;
    if (endsWithAny(['facebook.com', 'fb.com'])) return TrafficSource.facebook;
    if (RegExp(r'(^|\.)(google|bing|duckduckgo|yahoo)\.').hasMatch(host)) {
      return TrafficSource.busca;
    }
    return TrafficSource.outro;
  }

  static String? _host(String referrer) {
    if (referrer.trim().isEmpty) return null;
    final host = Uri.tryParse(referrer)?.host.toLowerCase();
    return (host == null || host.isEmpty) ? null : host;
  }

  static String? _clean(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    return v.length > 80 ? v.substring(0, 80) : v;
  }
}
