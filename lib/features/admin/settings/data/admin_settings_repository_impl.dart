import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/admin/settings/domain/admin_settings.dart';
import 'package:joyjoy/features/store/data/models/store_settings_model.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// O RLS ("admin altera configuração") e o `is_admin()` das RPCs são a
/// proteção real — este código só chama a API.
class AdminSettingsRepositoryImpl implements AdminSettingsRepository {
  AdminSettingsRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<StoreSettings>> startStockAudit(int minutes) => _guard(
    () => _client.rpc<Map<String, dynamic>>(
      'start_stock_audit',
      params: {'p_minutes': minutes},
    ),
  );

  @override
  Future<Result<StoreSettings>> stopStockAudit() =>
      _guard(() => _client.rpc<Map<String, dynamic>>('stop_stock_audit'));

  Future<Result<StoreSettings>> _guard(
    Future<Map<String, dynamic>> Function() run,
  ) async {
    try {
      return Success(StoreSettingsModel.fromJson(await run()));
    } on PostgrestException catch (error) {
      return Failed(_failureFor(error));
    } on Object {
      return const Failed(NetworkFailure());
    }
  }

  Failure _failureFor(PostgrestException error) => switch (error.message) {
    'forbidden' => const UnauthorizedFailure(
      'Sua sessão expirou. Entre de novo.',
    ),
    'invalid_minutes' => const ValidationFailure(
      'Escolha 15, 30 ou 60 minutos.',
    ),
    _ => const ServerFailure('Não foi possível salvar agora. Tente de novo.'),
  };
}
