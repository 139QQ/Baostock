/// 基金持仓信息模型
class FundHolding {
  final String fundCode;
  final String reportDate;
  final String holdingType;
  final String? stockCode;
  final String? stockName;
  final int? holdingQuantity;
  final double? holdingValue;
  final double? holdingPercentage;
  final double? marketValue;
  final String? sector;

  FundHolding({
    required this.fundCode,
    required this.reportDate,
    required this.holdingType,
    this.stockCode,
    this.stockName,
    this.holdingQuantity,
    this.holdingValue,
    this.holdingPercentage,
    this.marketValue,
    this.sector,
  });

  /// 复制构造函数
  FundHolding copyWith({
    String? fundCode,
    String? reportDate,
    String? holdingType,
    String? stockCode,
    String? stockName,
    int? holdingQuantity,
    double? holdingValue,
    double? holdingPercentage,
    double? marketValue,
    String? sector,
  }) {
    return FundHolding(
      fundCode: fundCode ?? this.fundCode,
      reportDate: reportDate ?? this.reportDate,
      holdingType: holdingType ?? this.holdingType,
      stockCode: stockCode ?? this.stockCode,
      stockName: stockName ?? this.stockName,
      holdingQuantity: holdingQuantity ?? this.holdingQuantity,
      holdingValue: holdingValue ?? this.holdingValue,
      holdingPercentage: holdingPercentage ?? this.holdingPercentage,
      marketValue: marketValue ?? this.marketValue,
      sector: sector ?? this.sector,
    );
  }

  @override
  String toString() {
    return 'FundHolding(fundCode: $fundCode, stockName: $stockName, holdingPercentage: $holdingPercentage%, sector: $sector)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FundHolding &&
        other.fundCode == fundCode &&
        other.stockCode == stockCode &&
        other.reportDate == reportDate;
  }

  @override
  int get hashCode =>
      fundCode.hashCode ^ stockCode.hashCode ^ reportDate.hashCode;
}
