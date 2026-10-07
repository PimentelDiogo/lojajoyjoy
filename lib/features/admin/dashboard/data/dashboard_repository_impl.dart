import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/supabase_error_mapper.dart';
import 'package:joyjoy/features/admin/dashboard/domain/dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Leituras do admin. Só funcionam logada como admin: o RLS de `orders` e
/// `visits` libera SELECT apenas para `is_admin()`.
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<AdminStats>> getStats({required DateTime since}) async {
    try {
      final (pending, products, visits) = await (
        _client.from('orders').count().eq('status', 'pending'),
        _client.from('products').count().eq('is_active', true),
        _client
            .from('visits')
            .select('source')
            .gte('created_at', since.toUtc().toIso8601String()),
      ).wait;

      final bySource = <String, int>{};
      for (final row in visits) {
        final source = row['source'] as String;
        bySource[source] = (bySource[source] ?? 0) + 1;
      }
      final sorted = bySource.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Success(
        AdminStats(
          pendingOrders: pending,
          activeProducts: products,
          visitsBySource: {for (final e in sorted) e.key: e.value},
        ),
      );
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }
}
