import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';
import 'package:joyjoy/features/store/domain/repositories/store_repository.dart';

class GetStoreSettings implements UseCase<StoreSettings, NoParams> {
  GetStoreSettings(this._repository);
  final StoreRepository _repository;

  @override
  Future<Result<StoreSettings>> call(NoParams params) =>
      _repository.getSettings();
}
