import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:joyjoy/app/app.dart';
import 'package:joyjoy/app/bindings/initial_binding.dart';
import 'package:joyjoy/app/config_error_app.dart';
import 'package:joyjoy/core/config/env.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/core/theme/app_typography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // URLs limpas (/pedido/K7P2QX) em vez de /#/pedido/K7P2QX — ADR-0001.
  usePathUrlStrategy();
  AppTypography.configure();

  final env = Env.fromEnvironment();
  if (!env.isSupabaseConfigured) {
    runApp(ConfigErrorApp(missingKeys: env.missingKeys));
    return;
  }

  final (store, _) = await (
    SharedPreferencesKeyValueStore.create(),
    AppTypography.preload(),
  ).wait;
  await Supabase.initialize(
    url: env.supabaseUrl,
    publishableKey: env.supabaseAnonKey,
    // Implicit: o link de "nova senha" funciona mesmo aberto em outro
    // navegador (ex.: pedido no Instagram, e-mail aberto no Gmail). O PKCE
    // exigiria o mesmo navegador. O login por senha não usa esse fluxo.
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  InitialBinding(
    env: env,
    store: store,
    supabase: Supabase.instance.client,
  ).dependencies();
  runApp(const JoyJoyApp());
}
