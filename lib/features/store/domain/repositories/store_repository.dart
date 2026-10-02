import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';

abstract interface class StoreRepository {
  Future<Result<StoreSettings>> getSettings();
}
