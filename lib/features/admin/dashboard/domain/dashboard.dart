import 'package:equatable/equatable.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/usecase/usecase.dart';

/// Resumo do painel da Ana.
class AdminStats extends Equatable {
  const AdminStats({
    required this.pendingOrders,
    required this.activeProducts,
    required this.visitsBySource,
  });

  final int pendingOrders;
  final int activeProducts;

  /// Visitas dos últimos 7 dias por origem (instagram, whatsapp, site…),
  /// em ordem decrescente.
  final Map<String, int> visitsBySource;

  int get totalVisits => visitsBySource.values.fold(0, (a, b) => a + b);

  @override
  List<Object?> get props => [pendingOrders, activeProducts, visitsBySource];
}

abstract interface class DashboardRepository {
  Future<Result<AdminStats>> getStats({required DateTime since});
}

class GetAdminStats implements UseCase<AdminStats, NoParams> {
  GetAdminStats(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DashboardRepository _repository;
  final DateTime Function() _now;

  static const window = Duration(days: 7);

  @override
  Future<Result<AdminStats>> call(NoParams params) =>
      _repository.getStats(since: _now().subtract(window));
}
