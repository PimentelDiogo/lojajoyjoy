import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/services/browser_info.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/features/tracking/domain/traffic_source.dart';
import 'package:joyjoy/features/tracking/presentation/session_tracker.dart';

import '../../helpers/fakes.dart';

void main() {
  group('SourceDetector', () {
    TrafficSource detect(String url, {String ua = '', String ref = ''}) =>
        SourceDetector.detect(
          url: Uri.parse(url),
          userAgent: ua,
          referrer: ref,
        ).source;

    test('?src= dos links oficiais tem prioridade sobre tudo', () {
      expect(
        detect('https://joyjoy.com.br/?src=whatsapp', ua: 'Instagram 300.0'),
        TrafficSource.whatsapp,
      );
      expect(detect('https://joyjoy.com.br/?src=ig'), TrafficSource.instagram);
      expect(detect('https://joyjoy.com.br/?src=qr'), TrafficSource.qrcode);
      expect(
        detect('https://joyjoy.com.br/?src=parceira'),
        TrafficSource.outro,
      );
    });

    test('utm_source também vale e guarda a campanha', () {
      final d = SourceDetector.detect(
        url: Uri.parse(
          'https://joyjoy.com.br/?utm_source=ig&utm_campaign=verao',
        ),
        userAgent: '',
        referrer: '',
      );
      expect(d.source, TrafficSource.instagram);
      expect(d.campaign, 'verao');
    });

    test('navegador embutido do Instagram / Facebook', () {
      expect(
        detect(
          'https://joyjoy.com.br/',
          ua: 'Mozilla/5.0 ... Instagram 312.0.0',
        ),
        TrafficSource.instagram,
      );
      expect(
        detect(
          'https://joyjoy.com.br/',
          ua: 'Mozilla/5.0 [FBAN/FBIOS;FBAV/450.0]',
        ),
        TrafficSource.facebook,
      );
    });

    test('referrer', () {
      expect(
        detect('https://joyjoy.com.br/', ref: 'https://l.instagram.com/?u=x'),
        TrafficSource.instagram,
      );
      expect(
        detect('https://joyjoy.com.br/', ref: 'https://web.whatsapp.com/'),
        TrafficSource.whatsapp,
      );
      expect(
        detect('https://joyjoy.com.br/', ref: 'https://www.google.com.br/'),
        TrafficSource.busca,
      );
      expect(
        detect('https://joyjoy.com.br/', ref: 'https://blog.qualquer.com/'),
        TrafficSource.outro,
      );
    });

    test('sem pistas ou vindo do próprio site = site (direto)', () {
      expect(detect('https://joyjoy.com.br/'), TrafficSource.site);
      expect(
        detect(
          'https://joyjoy.com.br/x',
          ref: 'https://joyjoy.com.br/feminino',
        ),
        TrafficSource.site,
      );
    });

    test('domínio parecido não engana (evilinstagram.com)', () {
      expect(
        detect('https://joyjoy.com.br/', ref: 'https://evilinstagram.com/'),
        TrafficSource.outro,
      );
    });
  });

  group('SessionTracker', () {
    setUp(() => Get.testMode = true);
    tearDown(Get.reset);

    SessionTracker create(
      InMemoryKeyValueStore kv,
      FakeTrackingRepository repo, {
      DateTime? now,
      String url = 'https://x.com/feminino?src=instagram',
    }) => Get.put(
      SessionTracker(
        store: kv,
        repository: repo,
        browserInfo: () =>
            BrowserInfo(url: Uri.parse(url), userAgent: '', referrer: ''),
        deviceType: () => 'desktop',
        now: () => now ?? DateTime(2026, 10, 5, 12),
      ),
    );

    test(
      'primeira visita: cria sessão, detecta origem e registra 1 visita',
      () async {
        final kv = InMemoryKeyValueStore();
        final repo = FakeTrackingRepository();

        final tracker = create(kv, repo);
        await Future<void>.delayed(Duration.zero);

        expect(tracker.source, TrafficSource.instagram);
        expect(tracker.sessionId, hasLength(36));
        expect(repo.visits.single.$3, '/feminino');
        expect(repo.visits.single.$4, 'desktop');
        expect(kv.read(SessionTracker.storageKey), contains(tracker.sessionId));
      },
    );

    test(
      'sessão salva e recente é reaproveitada (first-touch, sem nova visita)',
      () async {
        final kv = InMemoryKeyValueStore({
          SessionTracker.storageKey: jsonEncode({
            'id': '6b1f5e7a-9c2d-4e3f-8a1b-2c3d4e5f6a7b',
            'source': 'whatsapp',
            'started_at': DateTime(2026, 10, 5, 9).toIso8601String(),
          }),
        });
        final repo = FakeTrackingRepository();

        final tracker = create(kv, repo, url: 'https://x.com/?src=instagram');

        expect(tracker.sessionId, '6b1f5e7a-9c2d-4e3f-8a1b-2c3d4e5f6a7b');
        expect(tracker.source, TrafficSource.whatsapp);
        expect(repo.visits, isEmpty);
      },
    );

    test('sessão com mais de 12h vira nova', () {
      final kv = InMemoryKeyValueStore({
        SessionTracker.storageKey: jsonEncode({
          'id': '6b1f5e7a-9c2d-4e3f-8a1b-2c3d4e5f6a7b',
          'source': 'whatsapp',
          'started_at': DateTime(2026, 10, 4, 8).toIso8601String(),
        }),
      });

      final tracker = create(kv, FakeTrackingRepository());

      expect(tracker.sessionId, isNot('6b1f5e7a-9c2d-4e3f-8a1b-2c3d4e5f6a7b'));
      expect(tracker.source, TrafficSource.instagram);
    });

    test('dado salvo corrompido ou adulterado vira sessão nova', () {
      for (final raw in [
        '{x',
        jsonEncode({
          'id': 'nao-e-uuid',
          'source': 'site',
          'started_at': '2026-10-05T11:00:00',
        }),
      ]) {
        final kv = InMemoryKeyValueStore({SessionTracker.storageKey: raw});
        final tracker = create(kv, FakeTrackingRepository());
        expect(tracker.sessionId, hasLength(36), reason: raw);
        Get
          ..reset()
          ..testMode = true;
      }
    });
  });
}
