import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/supabase_error_mapper.dart';
import 'package:joyjoy/features/store/data/datasources/store_remote_datasource.dart';
import 'package:joyjoy/features/store/data/models/store_settings_model.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';
import 'package:joyjoy/features/store/domain/repositories/store_repository.dart';

class StoreRepositoryImpl implements StoreRepository {
  StoreRepositoryImpl(this._remote);

  final StoreRemoteDataSource _remote;

  @override
  Future<Result<StoreSettings>> getSettings() async {
    try {
      return Success(
        StoreSettingsModel.fromJson(await _remote.fetchSettings()),
      );
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }
}
