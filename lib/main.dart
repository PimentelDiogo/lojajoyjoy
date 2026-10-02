import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:ondas_que_faltam/app/app.dart';
import 'package:ondas_que_faltam/app/bindings/initial_binding.dart';
import 'package:ondas_que_faltam/core/config/env.dart';
import 'package:ondas_que_faltam/core/services/key_value_store.dart';

Future<void> main() async {
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

  final store = await SharedPreferencesKeyValueStore.create();
  InitialBinding(env: env, store: store).dependencies();
  runApp(const OndasApp());
}
