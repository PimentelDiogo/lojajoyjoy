import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/tracking/domain/traffic_source.dart';

abstract interface class TrackingRepository {
  Future<Result<void>> trackVisit({
    required String sessionId,
    required SourceDetection detection,
    required String landingPath,
    required String deviceType,
  });
}
