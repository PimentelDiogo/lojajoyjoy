import 'package:flutter_test/flutter_test.dart';
import 'package:ondas_que_faltam/app/routes/app_routes.dart';
import 'package:ondas_que_faltam/app/routes/route_pattern.dart';

void main() {
  group('RoutePattern', () {
    test('raiz só aceita "/"', () {
      final root = RoutePattern(AppRoutes.landing);

      expect(root.matches('/'), isTrue);
      expect(root.matches(''), isTrue);
      expect(root.matches('/?src=instagram'), isTrue);
      expect(root.matches('/rota-que-nao-existe'), isFalse);
    });

    test('rota fixa ignora barra final e query string', () {
      final feminino = RoutePattern(AppRoutes.feminino);

      expect(feminino.matches('/feminino'), isTrue);
      expect(feminino.matches('/feminino/'), isTrue);
      expect(feminino.matches('/feminino?src=whatsapp'), isTrue);
      expect(feminino.matches('/feminino/extra'), isFalse);
      expect(feminino.matches('/masculino'), isFalse);
    });

    test('parâmetro aceita exatamente um segmento', () {
      final order = RoutePattern(AppRoutes.order);

      expect(order.matches('/pedido/K7P2QX'), isTrue);
      expect(order.matches('/pedido'), isFalse);
      expect(order.matches('/pedido/K7P2QX/extra'), isFalse);
    });

    test('caracteres especiais do padrão não viram regex', () {
      final pattern = RoutePattern('/a.b');

      expect(pattern.matches('/a.b'), isTrue);
      expect(pattern.matches('/axb'), isFalse);
    });
  });
}
