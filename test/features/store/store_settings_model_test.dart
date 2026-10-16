import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/features/store/data/models/store_settings_model.dart';

void main() {
  const base = {
    'store_name': 'JOYJOY',
    'whatsapp_number': '5581986323686',
    'greeting_message': 'Olá!',
    'is_open': true,
    'low_stock_threshold': 2,
  };

  test('stock_audit_ends_at ausente vira null (não está em auditoria)', () {
    final settings = StoreSettingsModel.fromJson(base);
    expect(settings.stockAuditEndsAt, isNull);
    expect(settings.inStockAudit, isFalse);
  });

  test('stock_audit_ends_at presente vira DateTime e liga inStockAudit', () {
    final settings = StoreSettingsModel.fromJson({
      ...base,
      'is_open': false,
      'stock_audit_ends_at': '2026-10-16T15:30:00+00:00',
    });
    expect(
      settings.stockAuditEndsAt,
      DateTime.utc(2026, 10, 16, 15, 30),
    );
    expect(settings.inStockAudit, isTrue);
  });

  test('is_open=false sem stock_audit_ends_at não conta como auditoria', () {
    final settings = StoreSettingsModel.fromJson({
      ...base,
      'is_open': false,
      'closed_message': 'Fechado por hoje.',
    });
    expect(settings.inStockAudit, isFalse);
  });
}
