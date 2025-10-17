import 'dart:ui';

/// 基金基础信息模型
class Fund {
  final String code;
  final String name;
  final String type;
  final String company;
  final String manager;
  final double return1W;
  final double return1M;
  final double return3M;
  final double return6M;
  final double return1Y;
  final double return3Y;
  final double? returnYTD;
  final double? returnSinceInception;
  final double scale;
  final String riskLevel;
  final String status;
  final double? unitNav;
  final double? accumulatedNav;
  final double? dailyReturn;
  final DateTime? establishDate;
  final double? managementFee;
  final double? custodyFee;
  final double? purchaseFee;
  final double? redemptionFee;
  final double? minimumInvestment;
  final String? performanceBenchmark;
  final String? investmentTarget;
  final String? investmentScope;
  final String? currency;
  final DateTime? listingDate;
  final DateTime? delistingDate;
  final bool isFavorite;

  Fund({
    required this.code,
    required this.name,
    required this.type,
    required this.company,
    required this.manager,
    required this.return1W,
    required this.return1M,
    required this.return3M,
    required this.return6M,
    required this.return1Y,
    required this.return3Y,
    this.returnYTD,
    this.returnSinceInception,
    required this.scale,
    required this.riskLevel,
    required this.status,
    this.unitNav,
    this.accumulatedNav,
    this.dailyReturn,
    this.establishDate,
    this.managementFee,
    this.custodyFee,
    this.purchaseFee,
    this.redemptionFee,
    this.minimumInvestment,
    this.performanceBenchmark,
    this.investmentTarget,
    this.investmentScope,
    this.currency,
    this.listingDate,
    this.delistingDate,
    this.isFavorite = false,
  });

  /// 复制构造函数
  Fund copyWith({
    String? code,
    String? name,
    String? type,
    String? company,
    String? manager,
    double? return1W,
    double? return1M,
    double? return3M,
    double? return6M,
    double? return1Y,
    double? return3Y,
    double? returnYTD,
    double? returnSinceInception,
    double? scale,
    String? riskLevel,
    String? status,
    double? unitNav,
    double? accumulatedNav,
    double? dailyReturn,
    DateTime? establishDate,
    double? managementFee,
    double? custodyFee,
    double? purchaseFee,
    double? redemptionFee,
    double? minimumInvestment,
    String? performanceBenchmark,
    String? investmentTarget,
    String? investmentScope,
    String? currency,
    DateTime? listingDate,
    DateTime? delistingDate,
    bool? isFavorite,
  }) {
    return Fund(
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      company: company ?? this.company,
      manager: manager ?? this.manager,
      return1W: return1W ?? this.return1W,
      return1M: return1M ?? this.return1M,
      return3M: return3M ?? this.return3M,
      return6M: return6M ?? this.return6M,
      return1Y: return1Y ?? this.return1Y,
      return3Y: return3Y ?? this.return3Y,
      returnYTD: returnYTD ?? this.returnYTD,
      returnSinceInception: returnSinceInception ?? this.returnSinceInception,
      scale: scale ?? this.scale,
      riskLevel: riskLevel ?? this.riskLevel,
      status: status ?? this.status,
      unitNav: unitNav ?? this.unitNav,
      accumulatedNav: accumulatedNav ?? this.accumulatedNav,
      dailyReturn: dailyReturn ?? this.dailyReturn,
      establishDate: establishDate ?? this.establishDate,
      managementFee: managementFee ?? this.managementFee,
      custodyFee: custodyFee ?? this.custodyFee,
      purchaseFee: purchaseFee ?? this.purchaseFee,
      redemptionFee: redemptionFee ?? this.redemptionFee,
      minimumInvestment: minimumInvestment ?? this.minimumInvestment,
      performanceBenchmark: performanceBenchmark ?? this.performanceBenchmark,
      investmentTarget: investmentTarget ?? this.investmentTarget,
      investmentScope: investmentScope ?? this.investmentScope,
      currency: currency ?? this.currency,
      listingDate: listingDate ?? this.listingDate,
      delistingDate: delistingDate ?? this.delistingDate,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// 获取风险等级数值
  int get riskLevelValue {
    switch (riskLevel) {
      case 'R1':
        return 1;
      case 'R2':
        return 2;
      case 'R3':
        return 3;
      case 'R4':
        return 4;
      case 'R5':
        return 5;
      default:
        return 3;
    }
  }

  /// 获取基金类型颜色
  static Color getFundTypeColor(String type) {
    switch (type) {
      case '股票型':
        return const Color(0xFFEF4444);
      case '债券型':
        return const Color(0xFF10B981);
      case '混合型':
        return const Color(0xFFF59E0B);
      case '货币型':
        return const Color(0xFF3B82F6);
      case '指数型':
        return const Color(0xFF8B5CF6);
      case 'QDII':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  /// 获取风险等级颜色
  static Color getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'R1':
      case 'R2':
        return const Color(0xFF10B981); // 绿色 - 低风险
      case 'R3':
        return const Color(0xFFF59E0B); // 黄色 - 中等风险
      case 'R4':
      case 'R5':
        return const Color(0xFFEF4444); // 红色 - 高风险
      default:
        return const Color(0xFF6B7280);
    }
  }

  /// 获取收益率颜色（中国股市：红涨绿跌）
  static Color getReturnColor(double returnRate) {
    if (returnRate > 0) {
      return const Color(0xFFEF4444); // 红色 - 上涨
    } else if (returnRate < 0) {
      return const Color(0xFF10B981); // 绿色 - 下跌
    } else {
      return const Color(0xFF6B7280); // 灰色 - 持平
    }
  }

  /// 转换为JSON格式（用于缓存和序列化）
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'type': type,
      'company': company,
      'manager': manager,
      'return1W': return1W,
      'return1M': return1M,
      'return3M': return3M,
      'return6M': return6M,
      'return1Y': return1Y,
      'return3Y': return3Y,
      'returnYTD': returnYTD,
      'returnSinceInception': returnSinceInception,
      'scale': scale,
      'riskLevel': riskLevel,
      'status': status,
      'unitNav': unitNav,
      'accumulatedNav': accumulatedNav,
      'dailyReturn': dailyReturn,
      'establishDate': establishDate?.toIso8601String(),
      'managementFee': managementFee,
      'custodyFee': custodyFee,
      'purchaseFee': purchaseFee,
      'redemptionFee': redemptionFee,
      'minimumInvestment': minimumInvestment,
      'performanceBenchmark': performanceBenchmark,
      'investmentTarget': investmentTarget,
      'investmentScope': investmentScope,
      'currency': currency,
      'listingDate': listingDate?.toIso8601String(),
      'delistingDate': delistingDate?.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  /// 从JSON创建基金对象（用于缓存和反序列化）
  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      code: json['code'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      company: json['company'] as String,
      manager: json['manager'] as String,
      return1W: (json['return1W'] as num).toDouble(),
      return1M: (json['return1M'] as num).toDouble(),
      return3M: (json['return3M'] as num).toDouble(),
      return6M: (json['return6M'] as num).toDouble(),
      return1Y: (json['return1Y'] as num).toDouble(),
      return3Y: (json['return3Y'] as num).toDouble(),
      returnYTD: json['returnYTD'] != null
          ? (json['returnYTD'] as num).toDouble()
          : null,
      returnSinceInception: json['returnSinceInception'] != null
          ? (json['returnSinceInception'] as num).toDouble()
          : null,
      scale: (json['scale'] as num).toDouble(),
      riskLevel: json['riskLevel'] as String,
      status: json['status'] as String,
      unitNav:
          json['unitNav'] != null ? (json['unitNav'] as num).toDouble() : null,
      accumulatedNav: json['accumulatedNav'] != null
          ? (json['accumulatedNav'] as num).toDouble()
          : null,
      dailyReturn: json['dailyReturn'] != null
          ? (json['dailyReturn'] as num).toDouble()
          : null,
      establishDate: json['establishDate'] != null
          ? DateTime.parse(json['establishDate'] as String)
          : null,
      managementFee: json['managementFee'] != null
          ? (json['managementFee'] as num).toDouble()
          : null,
      custodyFee: json['custodyFee'] != null
          ? (json['custodyFee'] as num).toDouble()
          : null,
      purchaseFee: json['purchaseFee'] != null
          ? (json['purchaseFee'] as num).toDouble()
          : null,
      redemptionFee: json['redemptionFee'] != null
          ? (json['redemptionFee'] as num).toDouble()
          : null,
      minimumInvestment: json['minimumInvestment'] != null
          ? (json['minimumInvestment'] as num).toDouble()
          : null,
      performanceBenchmark: json['performanceBenchmark'] as String?,
      investmentTarget: json['investmentTarget'] as String?,
      investmentScope: json['investmentScope'] as String?,
      currency: json['currency'] as String?,
      listingDate: json['listingDate'] != null
          ? DateTime.parse(json['listingDate'] as String)
          : null,
      delistingDate: json['delistingDate'] != null
          ? DateTime.parse(json['delistingDate'] as String)
          : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'Fund(code: $code, name: $name, type: $type, company: $company, manager: $manager, return1Y: $return1Y%, scale: $scale亿)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Fund && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

/// 基金排行信息模型 - 基于AKShare fund_open_fund_rank_em API
class FundRanking {
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

  FundRanking({
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

  /// 计算排名百分位
  double get rankingPercentile {
    return (rankingPosition / totalCount) * 100;
  }

  /// 获取排名颜色
  static Color getRankingColor(int position) {
    if (position <= 3) return const Color(0xFFFFD700); // 金色
    if (position <= 10) return const Color(0xFF1E40AF); // 蓝色
    if (position <= 50) return const Color(0xFF10B981); // 绿色
    return const Color(0xFF6B7280); // 灰色
  }

  /// 获取排名徽章颜色
  static Color getRankingBadgeColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700); // 金色
      case 2:
        return const Color(0xFFC0C0C0); // 银色
      case 3:
        return const Color(0xFFCD7F32); // 铜色
      default:
        return const Color(0xFF6B7280);
    }
  }

  /// 复制并更新模型 - 用于排序后重新计算排名
  FundRanking copyWith({
    String? fundCode,
    String? fundName,
    String? fundType,
    String? company,
    int? rankingPosition,
    int? totalCount,
    double? unitNav,
    double? accumulatedNav,
    double? dailyReturn,
    double? return1W,
    double? return1M,
    double? return3M,
    double? return6M,
    double? return1Y,
    double? return2Y,
    double? return3Y,
    double? returnYTD,
    double? returnSinceInception,
    String? date,
    double? fee,
  }) {
    return FundRanking(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      fundType: fundType ?? this.fundType,
      company: company ?? this.company,
      rankingPosition: rankingPosition ?? this.rankingPosition,
      totalCount: totalCount ?? this.totalCount,
      unitNav: unitNav ?? this.unitNav,
      accumulatedNav: accumulatedNav ?? this.accumulatedNav,
      dailyReturn: dailyReturn ?? this.dailyReturn,
      return1W: return1W ?? this.return1W,
      return1M: return1M ?? this.return1M,
      return3M: return3M ?? this.return3M,
      return6M: return6M ?? this.return6M,
      return1Y: return1Y ?? this.return1Y,
      return2Y: return2Y ?? this.return2Y,
      return3Y: return3Y ?? this.return3Y,
      returnYTD: returnYTD ?? this.returnYTD,
      returnSinceInception: returnSinceInception ?? this.returnSinceInception,
      date: date ?? this.date,
      fee: fee ?? this.fee,
    );
  }
}

/// 基金经理信息模型
class FundManager {
  final String managerCode;
  final String managerName;
  final String? avatarUrl;
  final String? educationBackground;
  final String? professionalExperience;
  final DateTime? manageStartDate;
  final int totalManageDuration;
  final int currentFundCount;
  final double totalAssetUnderManagement;
  final double averageReturnRate;
  final double bestFundPerformance;
  final double riskAdjustedReturn;

  FundManager({
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

  /// 获取从业年限
  double get yearsOfExperience {
    return totalManageDuration / 365.0;
  }

  /// 格式化资产管理规模
  String get formattedAUM {
    if (totalAssetUnderManagement >= 100) {
      return '${(totalAssetUnderManagement / 100).toStringAsFixed(1)}百亿';
    } else {
      return '${totalAssetUnderManagement.toStringAsFixed(1)}亿';
    }
  }
}

/// 基金公司信息模型
class FundCompany {
  final String companyCode;
  final String companyName;
  final String? companyShortName;
  final DateTime? establishmentDate;
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

  FundCompany({
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

  /// 格式化资产管理规模
  String get formattedAUM {
    if (totalAssetUnderManagement >= 1000) {
      return '${(totalAssetUnderManagement / 1000).toStringAsFixed(1)}千亿';
    } else if (totalAssetUnderManagement >= 100) {
      return '${(totalAssetUnderManagement / 100).toStringAsFixed(1)}百亿';
    } else {
      return '${totalAssetUnderManagement.toStringAsFixed(1)}亿';
    }
  }
}
