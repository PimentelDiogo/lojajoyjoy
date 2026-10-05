import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:joyjoy/core/services/browser_info.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/features/tracking/domain/tracking_repository.dart';
import 'package:joyjoy/features/tracking/domain/traffic_source.dart';
import 'package:uuid/uuid.dart';

/// Sessão anônima + origem do acesso (first-touch), ADR-0007.
///
/// Na primeira abertura (ou depois de [sessionTtl]) cria um `session_id`
/// aleatório, detecta a origem e registra a visita **uma vez**. A mesma
/// origem acompanha o pedido no `create_order`. Nenhum dado pessoal.
class SessionTracker extends GetxController {
  SessionTracker({
    required this.store,
    required this.repository,
    required this.browserInfo,
    required this.deviceType,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const storageKey = 'session_v1';
  static const sessionTtl = Duration(hours: 12);

  final KeyValueStore store;
  final TrackingRepository repository;
  final BrowserInfo Function() browserInfo;
  final String Function() deviceType;
  final DateTime Function() _now;

  late String sessionId;
  late TrafficSource source;

  @override
  void onInit() {
    super.onInit();
    final saved = _readSaved();
    if (saved != null) {
      sessionId = saved.$1;
      source = saved.$2;
      return;
    }
    _startNewSession();
  }

  (String, TrafficSource)? _readSaved() {
    try {
      final raw = store.read(storageKey);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final started = DateTime.parse(json['started_at'] as String);
      if (_now().difference(started) > sessionTtl) return null;
      final id = json['id'] as String;
      if (!Uuid.isValidUUID(fromString: id)) return null;
      final src = TrafficSource.values.byName(json['source'] as String);
      return (id, src);
    } on Object {
      return null; // dado inválido → sessão nova
    }
  }

  void _startNewSession() {
    final info = browserInfo();
    final detection = SourceDetector.detect(
      url: info.url,
      userAgent: info.userAgent,
      referrer: info.referrer,
    );
    sessionId = const Uuid().v4();
    source = detection.source;

    unawaited(
      store.write(
        storageKey,
        jsonEncode({
          'id': sessionId,
          'source': source.name,
          'started_at': _now().toIso8601String(),
        }),
      ),
    );
    // Falha ao registrar a visita não atrapalha a compra.
    unawaited(
      repository.trackVisit(
        sessionId: sessionId,
        detection: detection,
        landingPath: info.url.path,
        deviceType: deviceType(),
      ),
    );
  }
}
