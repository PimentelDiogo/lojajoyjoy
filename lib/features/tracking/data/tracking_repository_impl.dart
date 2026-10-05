import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/supabase_error_mapper.dart';
import 'package:joyjoy/features/tracking/domain/tracking_repository.dart';
import 'package:joyjoy/features/tracking/domain/traffic_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  TrackingRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<void>> trackVisit({
    required String sessionId,
    required SourceDetection detection,
    required String landingPath,
    required String deviceType,
  }) async {
    try {
      await _client.rpc<void>(
        'track_visit',
        params: {
          'p_session_id': sessionId,
          'p_source': detection.source.name,
          'p_utm_campaign': detection.campaign,
          'p_referrer_host': detection.referrerHost,
          'p_landing_path': landingPath,
          'p_device_type': deviceType,
        },
      );
      return const Success(null);
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }
}
