import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:ondas_que_faltam/app/app.dart';
import 'package:ondas_que_faltam/core/config/env.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // URLs limpas (/pedido/K7P2QX) em vez de /#/pedido/K7P2QX — ADR-0001.
  usePathUrlStrategy();

  final env = Env.fromEnvironment();
  if (kDebugMode && !env.isSupabaseConfigured) {
    debugPrint(
      '[Env] Faltando ${env.missingKeys.join(', ')}. '
      'Rode com --dart-define-from-file=env/local.json',
    );
  }

  runApp(OndasApp(env: env));
}
