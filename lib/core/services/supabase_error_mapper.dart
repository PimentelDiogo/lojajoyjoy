import 'package:joyjoy/core/errors/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Converte exceções do Supabase/rede em [Failure] (usado na camada `data`).
///
/// Mensagens técnicas não vão para a tela: a pessoa vê um texto amigável e o
/// código técnico fica em [Failure.code] para decisões da UI.
Failure mapSupabaseError(Object error) => switch (error) {
  PostgrestException(:final code) => ServerFailure(
    'Não foi possível carregar agora. Tente novamente.',
    code,
  ),
  AuthException(:final code) => UnauthorizedFailure.withCode(code),
  StorageException() => const ServerFailure(
    'Não foi possível carregar as imagens.',
  ),
  FormatException() => const ServerFailure('Resposta inesperada do servidor.'),
  _ => const NetworkFailure(),
};
