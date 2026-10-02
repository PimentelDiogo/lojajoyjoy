import 'package:joyjoy/features/store/domain/entities/store_settings.dart';

abstract final class StoreSettingsModel {
  static StoreSettings fromJson(Map<String, dynamic> json) => StoreSettings(
    storeName: json['store_name'] as String,
    whatsappNumber: json['whatsapp_number'] as String,
    greetingMessage: json['greeting_message'] as String,
    announcement: json['announcement'] as String?,
    isOpen: json['is_open'] as bool? ?? true,
    closedMessage: json['closed_message'] as String?,
    lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 2,
  );
}
