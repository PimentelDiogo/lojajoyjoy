import 'package:equatable/equatable.dart';

/// Configuração pública da loja (tabela `store_settings`).
class StoreSettings extends Equatable {
  const StoreSettings({
    required this.storeName,
    required this.whatsappNumber,
    required this.greetingMessage,
    required this.isOpen,
    required this.lowStockThreshold,
    this.announcement,
    this.closedMessage,
    this.stockAuditEndsAt,
    this.instagramHandle,
    this.pickupAddress,
    this.paymentMethods = const [],
  });

  final String storeName;

  /// Formato wa.me: só dígitos com DDI (ex.: 5581986323686).
  final String whatsappNumber;
  final String greetingMessage;

  /// Recado da loja exibido no topo (A2).
  final String? announcement;

  /// Loja fechada temporariamente (A14): vitrine mostra aviso e
  /// o checkout fica bloqueado.
  final bool isOpen;
  final String? closedMessage;

  /// ADR-0014: horário previsto pra Ana terminar a auditoria de estoque.
  /// Null = não está em auditoria (fechamento, se houver, é por outro motivo).
  final DateTime? stockAuditEndsAt;
  final int lowStockThreshold;

  /// Perfil do Instagram sem @ (ex.: joyjoybrand_).
  final String? instagramHandle;

  /// Endereço para retirada exibido no rodapé.
  final String? pickupAddress;

  /// Nomes do enum `payment_method` do banco (pix, card, cash), na ordem salva.
  final List<String> paymentMethods;

  bool get hasAnnouncement => announcement?.trim().isNotEmpty ?? false;

  /// ADR-0014: fechada especificamente por auditoria de estoque (tem prazo),
  /// diferente de um fechamento comum (`closedMessage` livre).
  bool get inStockAudit => !isOpen && stockAuditEndsAt != null;

  @override
  List<Object?> get props => [
    storeName,
    whatsappNumber,
    greetingMessage,
    announcement,
    isOpen,
    closedMessage,
    stockAuditEndsAt,
    lowStockThreshold,
    instagramHandle,
    pickupAddress,
    paymentMethods,
  ];
}
