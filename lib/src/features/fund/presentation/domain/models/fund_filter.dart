/// 基金筛选模型
class FundFilter {
  final String fundType;
  final String company;
  final double minReturn1Y;
  final double maxReturn1Y;
  final double minScale;
  final double maxScale;
  final String riskLevel;
  final String sortBy;
  final bool ascending;
  final int pageSize;

  const FundFilter({
    this.fundType = '',
    this.company = '',
    this.minReturn1Y = -100.0,
    this.maxReturn1Y = 100.0,
    this.minScale = 0.0,
    this.maxScale = double.maxFinite,
    this.riskLevel = '',
    this.sortBy = 'return1Y',
    this.ascending = false,
    this.pageSize = 20,
  });

  FundFilter copyWith({
    String? fundType,
    String? company,
    double? minReturn1Y,
    double? maxReturn1Y,
    double? minScale,
    double? maxScale,
    String? riskLevel,
    String? sortBy,
    bool? ascending,
    int? pageSize,
  }) {
    return FundFilter(
      fundType: fundType ?? this.fundType,
      company: company ?? this.company,
      minReturn1Y: minReturn1Y ?? this.minReturn1Y,
      maxReturn1Y: maxReturn1Y ?? this.maxReturn1Y,
      minScale: minScale ?? this.minScale,
      maxScale: maxScale ?? this.maxScale,
      riskLevel: riskLevel ?? this.riskLevel,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  bool get isEmpty =>
      fundType.isEmpty &&
      company.isEmpty &&
      minReturn1Y == -100.0 &&
      maxReturn1Y == 100.0 &&
      minScale == 0.0 &&
      maxScale == double.maxFinite &&
      riskLevel.isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FundFilter &&
        other.fundType == fundType &&
        other.company == company &&
        other.minReturn1Y == minReturn1Y &&
        other.maxReturn1Y == maxReturn1Y &&
        other.minScale == minScale &&
        other.maxScale == maxScale &&
        other.riskLevel == riskLevel &&
        other.sortBy == sortBy &&
        other.ascending == ascending &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode {
    return fundType.hashCode ^
        company.hashCode ^
        minReturn1Y.hashCode ^
        maxReturn1Y.hashCode ^
        minScale.hashCode ^
        maxScale.hashCode ^
        riskLevel.hashCode ^
        sortBy.hashCode ^
        ascending.hashCode ^
        pageSize.hashCode;
  }
}
