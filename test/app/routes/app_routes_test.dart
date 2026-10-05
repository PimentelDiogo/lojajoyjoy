import 'package:flutter_test/flutter_test.dart';
import 'package:ondas_que_faltam/app/routes/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('monta caminhos com parâmetros', () {
      expect(AppRoutes.productPath('vestido-midi'), '/produto/vestido-midi');
      expect(AppRoutes.orderPath('K7P2QX'), '/pedido/K7P2QX');
    });

    test('codifica parâmetros para não quebrar a URL', () {
      expect(AppRoutes.orderPath('A B/C'), '/pedido/A%20B%2FC');
    });
  });
}
