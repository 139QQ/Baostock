/// 开放式基金日度数据信息传输对象
class OpenFundDailyDto {
  final String? fundCode;
  final String? fundName;
  final String? fundType;
  final double? unitNav;
  final double? accumulatedNav;
  final double? dailyReturn;
  final double? return1Y;
  final double? return2Y;
  final double? return3Y;
  final double? returnYTD;
  final double? returnSinceInception;
  final String? establishDate;
  final String? lastUpdate;

  OpenFundDailyDto({
    this.fundCode,
    this.fundName,
    this.fundType,
    this.unitNav,
    this.accumulatedNav,
    this.dailyReturn,
    this.return1Y,
    this.return2Y,
    this.return3Y,
    this.returnYTD,
    this.returnSinceInception,
    this.establishDate,
    this.lastUpdate,
  });

  factory OpenFundDailyDto.fromJson(Map<String, dynamic> json) {
    return OpenFundDailyDto(
      fundCode: json['fund_code']?.toString(),
      fundName: json['fund_name']?.toString(),
      fundType: json['fund_type']?.toString(),
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
      returnSinceInception: json['return_since_inception'] != null
          ? double.tryParse(json['return_since_inception'].toString())
          : null,
      establishDate: json['establish_date']?.toString(),
      lastUpdate: json['last_update']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fund_code': fundCode,
      'fund_name': fundName,
      'fund_type': fundType,
      'unit_nav': unitNav,
      'accumulated_nav': accumulatedNav,
      'daily_return': dailyReturn,
      'return_1y': return1Y,
      'return_2y': return2Y,
      'return_3y': return3Y,
      'return_ytd': returnYTD,
      'return_since_inception': returnSinceInception,
      'establish_date': establishDate,
      'last_update': lastUpdate,
    };
  }
}
