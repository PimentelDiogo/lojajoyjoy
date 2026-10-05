/// Situação de estoque exibida na vitrine.
enum StockStatus {
  available,

  /// "Últimas unidades": total ≤ limite configurado pela Ana.
  low,

  /// "Esgotado".
  soldOut;

  static StockStatus from({
    required int totalStock,
    required int lowThreshold,
  }) {
    if (totalStock <= 0) return StockStatus.soldOut;
    if (totalStock <= lowThreshold) return StockStatus.low;
    return StockStatus.available;
  }
}
