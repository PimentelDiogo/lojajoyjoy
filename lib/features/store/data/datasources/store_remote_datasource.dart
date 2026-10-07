import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class StoreRemoteDataSource {
  Future<Map<String, dynamic>> fetchSettings();
}

class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  StoreRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> fetchSettings() => _client
      .from('store_settings')
      .select(
        'store_name, whatsapp_number, greeting_message, announcement, '
        'is_open, closed_message, low_stock_threshold, '
        'instagram_handle, pickup_address, payment_methods',
      )
      .eq('id', 1)
      .single();
}
