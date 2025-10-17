/// 基金个人基础信息数据传输对象
class FundIndividualBasicDto {
  final String fundCode;
  final String fundName;
  final String? fundNameAbbr;
  final String? fundType;
  final String? fundCompany;
  final String? companyCode;
  final String? fundManager;
  final String? managerCode;
  final String? establishDate;
  final String? listingDate;
  final double? fundScale;
  final String? currency;
  final String? status;
  final double? unitNav;
  final double? accumulatedNav;
  final double? dailyReturn;
  final String? lastUpdate;

  FundIndividualBasicDto({
    required this.fundCode,
    required this.fundName,
    this.fundNameAbbr,
    this.fundType,
    this.fundCompany,
    this.companyCode,
    this.fundManager,
    this.managerCode,
    this.establishDate,
    this.listingDate,
    this.fundScale,
    this.currency,
    this.status,
    this.unitNav,
    this.accumulatedNav,
    this.dailyReturn,
    this.lastUpdate,
  });

  factory FundIndividualBasicDto.fromJson(Map<String, dynamic> json) {
    return FundIndividualBasicDto(
      fundCode: json['fund_code']?.toString() ?? '',
      fundName: json['fund_name']?.toString() ?? '',
      fundNameAbbr: json['fund_name_abbr']?.toString(),
      fundType: json['fund_type']?.toString(),
      fundCompany: json['fund_company']?.toString(),
      companyCode: json['company_code']?.toString(),
      fundManager: json['fund_manager']?.toString(),
      managerCode: json['manager_code']?.toString(),
      establishDate: json['establish_date']?.toString(),
      listingDate: json['listing_date']?.toString(),
      fundScale: json['fund_scale'] != null
          ? double.tryParse(json['fund_scale'].toString())
          : null,
      currency: json['currency']?.toString(),
      status: json['status']?.toString(),
      unitNav: json['unit_nav'] != null
          ? double.tryParse(json['unit_nav'].toString())
          : null,
      accumulatedNav: json['accumulated_nav'] != null
          ? double.tryParse(json['accumulated_nav'].toString())
          : null,
      dailyReturn: json['daily_return'] != null
          ? double.tryParse(json['daily_return'].toString())
          : null,
      lastUpdate: json['last_update']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fund_code': fundCode,
      'fund_name': fundName,
      'fund_name_abbr': fundNameAbbr,
      'fund_type': fundType,
      'fund_company': fundCompany,
      'company_code': companyCode,
      'fund_manager': fundManager,
      'manager_code': managerCode,
      'establish_date': establishDate,
      'listing_date': listingDate,
      'fund_scale': fundScale,
      'currency': currency,
      'status': status,
      'unit_nav': unitNav,
      'accumulated_nav': accumulatedNav,
      'daily_return': dailyReturn,
      'last_update': lastUpdate,
    };
  }
}
