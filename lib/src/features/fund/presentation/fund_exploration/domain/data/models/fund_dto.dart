import 'package:flutter/foundation.dart';

import '../../models/fund.dart';

/// 基金基础信息数据传输对象
class FundDto {
  final String fundCode;
  final String fundName;
  final String? fundNameAbbr;
  final String fundType;
  final String fundCompany;
  final String? companyCode;
  final String? fundManager;
  final String? managerCode;
  final String? riskLevel;
  final String? establishDate;
  final String? listingDate;
  final double? fundScale;
  final double? minimumInvestment;
  final double? managementFee;
  final double? custodyFee;
  final double? purchaseFee;
  final double? redemptionFee;
  final String? performanceBenchmark;
  final String? investmentTarget;
  final String? investmentScope;
  final String? currency;
  final String? status;
  final double? unitNav;
  final double? accumulatedNav;
  final double? dailyReturn;
  final String? lastUpdate;

  FundDto({
    required this.fundCode,
    required this.fundName,
    this.fundNameAbbr,
    required this.fundType,
    required this.fundCompany,
    this.companyCode,
    this.fundManager,
    this.managerCode,
    this.riskLevel,
    this.establishDate,
    this.listingDate,
    this.fundScale,
    this.minimumInvestment,
    this.managementFee,
    this.custodyFee,
    this.purchaseFee,
    this.redemptionFee,
    this.performanceBenchmark,
    this.investmentTarget,
    this.investmentScope,
    this.currency,
    this.status,
    this.unitNav,
    this.accumulatedNav,
    this.dailyReturn,
    this.lastUpdate,
  });

  factory FundDto.fromJson(Map<String, dynamic> json) {
    return FundDto(
      fundCode: json['fund_code']?.toString() ?? '',
      fundName: json['fund_name']?.toString() ?? '',
      fundNameAbbr: json['fund_name_abbr']?.toString(),
      fundType: json['fund_type']?.toString() ?? '混合型',
      fundCompany: json['fund_company']?.toString() ?? '',
      companyCode: json['company_code']?.toString(),
      fundManager: json['fund_manager']?.toString(),
      managerCode: json['manager_code']?.toString(),
      riskLevel: json['risk_level']?.toString(),
      establishDate: json['establish_date']?.toString(),
      listingDate: json['listing_date']?.toString(),
      fundScale: FundDto._parseDouble(json['fund_scale']),
      minimumInvestment: FundDto._parseDouble(json['minimum_investment']),
      managementFee: FundDto._parseDouble(json['management_fee']),
      custodyFee: FundDto._parseDouble(json['custody_fee']),
      purchaseFee: FundDto._parseDouble(json['purchase_fee']),
      redemptionFee: FundDto._parseDouble(json['redemption_fee']),
      performanceBenchmark: json['performance_benchmark']?.toString(),
      investmentTarget: json['investment_target']?.toString(),
      investmentScope: json['investment_scope']?.toString(),
      currency: json['currency']?.toString() ?? 'CNY',
      status: json['status']?.toString() ?? 'active',
      unitNav: FundDto._parseDouble(json['unit_nav']),
      accumulatedNav: FundDto._parseDouble(json['accumulated_nav']),
      dailyReturn: FundDto._parseDouble(json['daily_return']),
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
      'risk_level': riskLevel,
      'establish_date': establishDate,
      'listing_date': listingDate,
      'fund_scale': fundScale,
      'minimum_investment': minimumInvestment,
      'management_fee': managementFee,
      'custody_fee': custodyFee,
      'purchase_fee': purchaseFee,
      'redemption_fee': redemptionFee,
      'performance_benchmark': performanceBenchmark,
      'investment_target': investmentTarget,
      'investment_scope': investmentScope,
      'currency': currency,
      'status': status,
      'unit_nav': unitNav,
      'accumulated_nav': accumulatedNav,
      'daily_return': dailyReturn,
      'last_update': lastUpdate,
    };
  }

  /// 转换为领域模型
  Fund toDomainModel() {
    return Fund(
      code: fundCode,
      name: fundName,
      type: fundType,
      company: fundCompany,
      manager: fundManager ?? '未知',
      return1W: 0.0, // 需要从其他接口获取
      return1M: 0.0, // 需要从其他接口获取
      return3M: 0.0, // 需要从其他接口获取
      return6M: 0.0, // 需要从其他接口获取
      return1Y: 0.0, // 需要从其他接口获取
      return3Y: 0.0, // 需要从其他接口获取
      scale: fundScale ?? 0.0,
      riskLevel: riskLevel ?? 'R3',
      status: status ?? 'active',
      unitNav: unitNav,
      accumulatedNav: accumulatedNav,
      dailyReturn: dailyReturn,
      establishDate:
          establishDate != null ? DateTime.tryParse(establishDate!) : null,
      managementFee: managementFee,
      custodyFee: custodyFee,
      purchaseFee: purchaseFee,
      redemptionFee: redemptionFee,
      minimumInvestment: minimumInvestment,
      performanceBenchmark: performanceBenchmark,
      investmentTarget: investmentTarget,
      investmentScope: investmentScope,
      currency: currency ?? 'CNY',
      listingDate: listingDate != null ? DateTime.tryParse(listingDate!) : null,
      delistingDate: null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

/// 基金净值数据传输对象
class FundNavDto {
  final String fundCode;
  final String navDate;
  final double unitNav;
  final double? accumulatedNav;
  final double? dailyReturn;
  final double? totalNetAssets;
  final String? subscriptionStatus;
  final String? redemptionStatus;

  FundNavDto({
    required this.fundCode,
    required this.navDate,
    required this.unitNav,
    this.accumulatedNav,
    this.dailyReturn,
    this.totalNetAssets,
    this.subscriptionStatus,
    this.redemptionStatus,
  });

  factory FundNavDto.fromJson(Map<String, dynamic> json) {
    return FundNavDto(
      fundCode: json['fund_code']?.toString() ?? '',
      navDate: json['nav_date']?.toString() ?? '',
      unitNav: FundDto._parseDouble(json['unit_nav']) ?? 0.0,
      accumulatedNav: FundDto._parseDouble(json['accumulated_nav']),
      dailyReturn: FundDto._parseDouble(json['daily_return']),
      totalNetAssets: FundDto._parseDouble(json['total_net_assets']),
      subscriptionStatus: json['subscription_status']?.toString(),
      redemptionStatus: json['redemption_status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fund_code': fundCode,
      'nav_date': navDate,
      'unit_nav': unitNav,
      'accumulated_nav': accumulatedNav,
      'daily_return': dailyReturn,
      'total_net_assets': totalNetAssets,
      'subscription_status': subscriptionStatus,
      'redemption_status': redemptionStatus,
    };
  }
}

/// 基金排行数据传输对象 - 基于AKShare fund_open_fund_rank_em API
class FundRankingDto {
  final String fundCode;
  final String fundName;
  final String fundType;
  final String company;
  final int rankingPosition;
  final int totalCount;
  final double unitNav;
  final double accumulatedNav;
  final double dailyReturn;
  final double return1W;
  final double return1M;
  final double return3M;
  final double return6M;
  final double return1Y;
  final double return2Y;
  final double return3Y;
  final double returnYTD;
  final double returnSinceInception;
  final String date;
  final double? fee;

  FundRankingDto({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.company,
    required this.rankingPosition,
    required this.totalCount,
    required this.unitNav,
    required this.accumulatedNav,
    required this.dailyReturn,
    required this.return1W,
    required this.return1M,
    required this.return3M,
    required this.return6M,
    required this.return1Y,
    required this.return2Y,
    required this.return3Y,
    required this.returnYTD,
    required this.returnSinceInception,
    required this.date,
    this.fee,
  });

  factory FundRankingDto.fromJson(Map<String, dynamic> json) {
    try {
      // 完全移除debug日志以提升大数据量处理性能

      // 解析中文字段名
      final fundCode =
          json['基金代码']?.toString() ?? json['fund_code']?.toString() ?? '未知代码';
      final fundName =
          json['基金简称']?.toString() ?? json['fund_name']?.toString() ?? '未知基金';
      final rawDate = json['日期']?.toString() ?? json['date']?.toString();

      // 解析基金类型（优先使用API返回的类型，否则根据基金代码推断）
      String fundType = json['基金类型']?.toString() ??
          json['fund_type']?.toString() ??
          '混合型'; // 默认类型
      if (fundType.isEmpty || fundType == '未知类型') {
        if (fundCode.isNotEmpty) {
          if (fundCode.startsWith('00') || fundCode.startsWith('16')) {
            fundType = '混合型';
          } else if (fundCode.startsWith('11')) {
            fundType = '股票型';
          } else if (fundCode.startsWith('18')) {
            fundType = '股票型';
          } else if (fundCode.startsWith('50') ||
              fundCode.startsWith('51') ||
              fundCode.startsWith('52')) {
            fundType = '债券型';
          } else if (fundCode.startsWith('51') || fundCode.startsWith('52')) {
            fundType = '股票型';
          }
        }
      }

      // 解析净值数据
      final unitNav = FundDto._parseDouble(json['单位净值']) ?? 0.0;
      final accumulatedNav = FundDto._parseDouble(json['累计净值']) ?? unitNav;
      final dailyReturn = FundDto._parseDouble(json['日增长率']) ?? 0.0;

      // 解析各时间段收益率
      final return1W = FundDto._parseDouble(json['近1周']) ?? 0.0;
      final return1M = FundDto._parseDouble(json['近1月']) ?? 0.0;
      final return3M = FundDto._parseDouble(json['近3月']) ?? 0.0;
      final return6M = FundDto._parseDouble(json['近6月']) ?? 0.0;
      final return1Y = FundDto._parseDouble(json['近1年']) ?? 0.0;
      final return2Y = FundDto._parseDouble(json['近2年']) ?? 0.0;
      final return3Y = FundDto._parseDouble(json['近3年']) ?? 0.0;
      final returnYTD = FundDto._parseDouble(json['今年来']) ?? 0.0;
      final returnSinceInception = FundDto._parseDouble(json['成立来']) ?? 0.0;

      // 解析手续费
      String? feeStr = json['手续费']?.toString();
      double? fee;
      if (feeStr != null && feeStr.isNotEmpty && feeStr != 'null') {
        // 处理类似"0.15%"的格式
        final cleanFeeStr = feeStr.replaceAll('%', '').trim();
        fee = double.tryParse(cleanFeeStr);
      }

      // 格式化日期
      String date = DateTime.now().toString().substring(0, 10);
      if (rawDate != null && rawDate.isNotEmpty) {
        try {
          final parsedDate = DateTime.parse(rawDate);
          date = parsedDate.toString().substring(0, 10);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ 日期解析失败: $rawDate');
        }
      }

      // 解析基金公司名称（优先使用API返回的公司名称）
      final company = json['基金公司']?.toString() ??
          json['fund_company']?.toString() ??
          json['管理公司']?.toString() ??
          '未知公司';

      return FundRankingDto(
        fundCode: fundCode,
        fundName: fundName,
        fundType: fundType,
        company: company,
        rankingPosition: 0, // 将在排序时设置
        totalCount: 100, // 默认总数，后续可以根据实际数据设置
        unitNav: unitNav,
        accumulatedNav: accumulatedNav,
        dailyReturn: dailyReturn,
        return1W: return1W,
        return1M: return1M,
        return3M: return3M,
        return6M: return6M,
        return1Y: return1Y,
        return2Y: return2Y,
        return3Y: return3Y,
        returnYTD: returnYTD,
        returnSinceInception: returnSinceInception,
        date: date,
        fee: fee,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FundRankingDto.fromJson 解析失败: $e');
        debugPrint('📄 原始JSON数据: $json');
      }

      // 返回一个默认的基金对象，避免崩溃
      return FundRankingDto(
        fundCode: 'ERROR_CODE',
        fundName: '解析失败',
        fundType: '未知类型',
        company: '未知公司',
        rankingPosition: 0,
        totalCount: 1,
        unitNav: 0.0,
        accumulatedNav: 0.0,
        dailyReturn: 0.0,
        return1W: 0.0,
        return1M: 0.0,
        return3M: 0.0,
        return6M: 0.0,
        return1Y: 0.0,
        return2Y: 0.0,
        return3Y: 0.0,
        returnYTD: 0.0,
        returnSinceInception: 0.0,
        date: DateTime.now().toString().substring(0, 10),
        fee: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '基金代码': fundCode,
      '基金简称': fundName,
      '基金类型': fundType,
      '基金公司': company,
      '序号': rankingPosition,
      '单位净值': unitNav,
      '累计净值': accumulatedNav,
      '日增长率': dailyReturn,
      '近1周': return1W,
      '近1月': return1M,
      '近3月': return3M,
      '近6月': return6M,
      '近1年': return1Y,
      '近2年': return2Y,
      '近3年': return3Y,
      '今年来': returnYTD,
      '成立来': returnSinceInception,
      '日期': date,
      '手续费': fee,
    };
  }

  /// 转换为领域模型
  FundRanking toDomainModel() {
    return FundRanking(
      fundCode: fundCode,
      fundName: fundName,
      fundType: fundType,
      company: company,
      rankingPosition: rankingPosition,
      totalCount: totalCount,
      unitNav: unitNav,
      accumulatedNav: accumulatedNav,
      dailyReturn: dailyReturn,
      return1W: return1W,
      return1M: return1M,
      return3M: return3M,
      return6M: return6M,
      return1Y: return1Y,
      return2Y: return2Y,
      return3Y: return3Y,
      returnYTD: returnYTD,
      returnSinceInception: returnSinceInception,
      date: date,
      fee: fee,
    );
  }
}

/// 基金经理数据传输对象
class FundManagerDto {
  final String managerCode;
  final String managerName;
  final String? avatarUrl;
  final String? educationBackground;
  final String? professionalExperience;
  final String? manageStartDate;
  final int totalManageDuration;
  final int currentFundCount;
  final double totalAssetUnderManagement;
  final double averageReturnRate;
  final double bestFundPerformance;
  final double riskAdjustedReturn;

  FundManagerDto({
    required this.managerCode,
    required this.managerName,
    this.avatarUrl,
    this.educationBackground,
    this.professionalExperience,
    this.manageStartDate,
    required this.totalManageDuration,
    required this.currentFundCount,
    required this.totalAssetUnderManagement,
    required this.averageReturnRate,
    required this.bestFundPerformance,
    required this.riskAdjustedReturn,
  });

  factory FundManagerDto.fromJson(Map<String, dynamic> json) {
    return FundManagerDto(
      managerCode: json['manager_code']?.toString() ?? '',
      managerName: json['manager_name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      educationBackground: json['education_background']?.toString(),
      professionalExperience: json['professional_experience']?.toString(),
      manageStartDate: json['manage_start_date']?.toString(),
      totalManageDuration:
          int.tryParse(json['total_manage_duration']?.toString() ?? '0') ?? 0,
      currentFundCount:
          int.tryParse(json['current_fund_count']?.toString() ?? '0') ?? 0,
      totalAssetUnderManagement:
          FundDto._parseDouble(json['total_asset_under_management']) ?? 0.0,
      averageReturnRate:
          FundDto._parseDouble(json['average_return_rate']) ?? 0.0,
      bestFundPerformance:
          FundDto._parseDouble(json['best_fund_performance']) ?? 0.0,
      riskAdjustedReturn:
          FundDto._parseDouble(json['risk_adjusted_return']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'manager_code': managerCode,
      'manager_name': managerName,
      'avatar_url': avatarUrl,
      'education_background': educationBackground,
      'professional_experience': professionalExperience,
      'manage_start_date': manageStartDate,
      'total_manage_duration': totalManageDuration,
      'current_fund_count': currentFundCount,
      'total_asset_under_management': totalAssetUnderManagement,
      'average_return_rate': averageReturnRate,
      'best_fund_performance': bestFundPerformance,
      'risk_adjusted_return': riskAdjustedReturn,
    };
  }
}

/// 基金公司数据传输对象
class FundCompanyDto {
  final String companyCode;
  final String companyName;
  final String? companyShortName;
  final String? establishmentDate;
  final double? registeredCapital;
  final String? companyType;
  final String? legalRepresentative;
  final String? headquartersLocation;
  final String? websiteUrl;
  final String? contactPhone;
  final int totalFundsUnderManagement;
  final double totalAssetUnderManagement;
  final String? companyRating;
  final String? ratingAgency;

  FundCompanyDto({
    required this.companyCode,
    required this.companyName,
    this.companyShortName,
    this.establishmentDate,
    this.registeredCapital,
    this.companyType,
    this.legalRepresentative,
    this.headquartersLocation,
    this.websiteUrl,
    this.contactPhone,
    required this.totalFundsUnderManagement,
    required this.totalAssetUnderManagement,
    this.companyRating,
    this.ratingAgency,
  });

  factory FundCompanyDto.fromJson(Map<String, dynamic> json) {
    return FundCompanyDto(
      companyCode: json['company_code']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      companyShortName: json['company_short_name']?.toString(),
      establishmentDate: json['establishment_date']?.toString(),
      registeredCapital: FundDto._parseDouble(json['registered_capital']),
      companyType: json['company_type']?.toString(),
      legalRepresentative: json['legal_representative']?.toString(),
      headquartersLocation: json['headquarters_location']?.toString(),
      websiteUrl: json['website_url']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      totalFundsUnderManagement: int.tryParse(
              json['total_funds_under_management']?.toString() ?? '0') ??
          0,
      totalAssetUnderManagement:
          FundDto._parseDouble(json['total_asset_under_management']) ?? 0.0,
      companyRating: json['company_rating']?.toString(),
      ratingAgency: json['rating_agency']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_code': companyCode,
      'company_name': companyName,
      'company_short_name': companyShortName,
      'establishment_date': establishmentDate,
      'registered_capital': registeredCapital,
      'company_type': companyType,
      'legal_representative': legalRepresentative,
      'headquarters_location': headquartersLocation,
      'website_url': websiteUrl,
      'contact_phone': contactPhone,
      'total_funds_under_management': totalFundsUnderManagement,
      'total_asset_under_management': totalAssetUnderManagement,
      'company_rating': companyRating,
      'rating_agency': ratingAgency,
    };
  }
}

/// 基金持仓数据传输对象
class FundHoldingDto {
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

  FundHoldingDto({
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

  factory FundHoldingDto.fromJson(Map<String, dynamic> json) {
    return FundHoldingDto(
      fundCode: json['fund_code']?.toString() ?? '',
      reportDate: json['report_date']?.toString() ?? '',
      holdingType: json['holding_type']?.toString() ?? 'stock',
      stockCode: json['stock_code']?.toString(),
      stockName: json['stock_name']?.toString(),
      holdingQuantity:
          int.tryParse(json['holding_quantity']?.toString() ?? '0'),
      holdingValue: FundDto._parseDouble(json['holding_value']),
      holdingPercentage: FundDto._parseDouble(json['holding_percentage']),
      marketValue: FundDto._parseDouble(json['market_value']),
      sector: json['sector']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fund_code': fundCode,
      'report_date': reportDate,
      'holding_type': holdingType,
      'stock_code': stockCode,
      'stock_name': stockName,
      'holding_quantity': holdingQuantity,
      'holding_value': holdingValue,
      'holding_percentage': holdingPercentage,
      'market_value': marketValue,
      'sector': sector,
    };
  }
}

/// 基金估值数据传输对象
class FundEstimateDto {
  final String fundCode;
  final double? estimateValue;
  final double? estimateReturn;
  final String? estimateTime;
  final double? previousNav;
  final String? previousNavDate;

  FundEstimateDto({
    required this.fundCode,
    this.estimateValue,
    this.estimateReturn,
    this.estimateTime,
    this.previousNav,
    this.previousNavDate,
  });

  factory FundEstimateDto.fromJson(Map<String, dynamic> json) {
    return FundEstimateDto(
      fundCode: json['fund_code']?.toString() ?? '',
      estimateValue: FundDto._parseDouble(json['estimate_value']),
      estimateReturn: FundDto._parseDouble(json['estimate_return']),
      estimateTime: json['estimate_time']?.toString(),
      previousNav: FundDto._parseDouble(json['previous_nav']),
      previousNavDate: json['previous_nav_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fund_code': fundCode,
      'estimate_value': estimateValue,
      'estimate_return': estimateReturn,
      'estimate_time': estimateTime,
      'previous_nav': previousNav,
      'previous_nav_date': previousNavDate,
    };
  }
}

/// 搜索结果数据传输对象
class SearchResultDto {
  final List<FundDto> funds;
  final List<String> suggestions;
  final Map<String, dynamic>? metadata;

  SearchResultDto({
    required this.funds,
    required this.suggestions,
    this.metadata,
  });

  factory SearchResultDto.fromJson(Map<String, dynamic> json) {
    return SearchResultDto(
      funds:
          (json['funds'] as List?)?.map((e) => FundDto.fromJson(e)).toList() ??
              [],
      suggestions:
          (json['suggestions'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'funds': funds.map((e) => e.toJson()).toList(),
      'suggestions': suggestions,
      'metadata': metadata,
    };
  }
}

/// 筛选结果数据传输对象
class FilterResultDto {
  final List<FundDto> funds;
  final int totalCount;
  final Map<String, dynamic>? metadata;

  FilterResultDto({
    required this.funds,
    required this.totalCount,
    this.metadata,
  });

  factory FilterResultDto.fromJson(Map<String, dynamic> json) {
    return FilterResultDto(
      funds:
          (json['funds'] as List?)?.map((e) => FundDto.fromJson(e)).toList() ??
              [],
      totalCount: json['total_count'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'funds': funds.map((e) => e.toJson()).toList(),
      'total_count': totalCount,
      'metadata': metadata,
    };
  }
}

/// API响应包装类
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? metadata;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.metadata,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message']?.toString(),
      statusCode: json['status_code'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'message': message,
      'status_code': statusCode,
      'metadata': metadata,
    };
  }
}

/// 分页响应包装类
class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;

  PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      items: (json['items'] as List?)?.map((e) => fromJsonT(e)).toList() ?? [],
      totalCount: json['total_count'] as int? ?? 0,
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrevious: json['has_previous'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items,
      'total_count': totalCount,
      'current_page': currentPage,
      'total_pages': totalPages,
      'page_size': pageSize,
      'has_next': hasNext,
      'has_previous': hasPrevious,
    };
  }
}
