/// 指数基金信息数据传输对象
class FundIndexInfoDto {
  final String? fundCode;
  final String? fundName;
  final String? fundType;
  final String? fundCompany;
  final double? unitNav;
  final double? accumulatedNav;
  final double? dailyReturn;
  final double? return1Y;
  final double? return2Y;
  final double? return3Y;
  final double? returnYTD;
  final String? establishDate;
  final double? fundScale;
  final String? trackingIndex;
  final double? trackingError;
  final String? lastUpdate;

  FundIndexInfoDto({
    this.fundCode,
    this.fundName,
    this.fundType,
    this.fundCompany,
    this.unitNav,
    this.accumulatedNav,
    this.dailyReturn,
    this.return1Y,
    this.return2Y,
    this.return3Y,
    this.returnYTD,
    this.establishDate,
    this.fundScale,
    this.trackingIndex,
    this.trackingError,
    this.lastUpdate,
  });

  factory FundIndexInfoDto.fromJson(Map<String, dynamic> json) {
    return FundIndexInfoDto(
      fundCode: json['fund_code']?.toString(),
      fundName: json['fund_name']?.toString(),
      fundType: json['fund_type']?.toString(),
      fundCompany: json['fund_company']?.toString(),
      unitNav: json['unit_nav'] != null
          ? double.tryParse(json['unit_nav'].toString())
          : null,
      accumulatedNav: json['accumulated_nav'] != null
          ? double.tryParse(json['accumulated_nav'].toString())
          : null,
      dailyReturn: json['daily_return'] != null
          ? double.tryParse(json['daily_return'].toString())
          : null,
      return1Y: json['return_1y'] != null
          ? double.tryParse(json['return_1y'].toString())
          : null,
      return2Y: json['return_2y'] != null
          ? double.tryParse(json['return_2y'].toString())
          : null,
      return3Y: json['return_3y'] != null
          ? double.tryParse(json['return_3y'].toString())
          : null,
      returnYTD: json['return_ytd'] != null
          ? double.tryParse(json['return_ytd'].toString())
          : null,
      establishDate: json['establish_date']?.toString(),
      fundScale: json['fund_scale'] != null
          ? double.tryParse(json['fund_scale'].toString())
          : null,
      trackingIndex: json['tracking_index']?.toString(),
      trackingError: json['tracking_error'] != null
          ? double.tryParse(json['tracking_error'].toString())
          : null,
      lastUpdate: json['last_update']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fund_code': fundCode,
      'fund_name': fundName,
      'fund_type': fundType,
      'fund_company': fundCompany,
      'unit_nav': unitNav,
      'accumulated_nav': accumulatedNav,
      'daily_return': dailyReturn,
      'return_1y': return1Y,
      'return_2y': return2Y,
      'return_3y': return3Y,
      'return_ytd': returnYTD,
      'establish_date': establishDate,
      'fund_scale': fundScale,
      'tracking_index': trackingIndex,
      'tracking_error': trackingError,
      'last_update': lastUpdate,
    };
  }
}
