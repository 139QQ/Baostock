import 'package:equatable/equatable.dart';

/// 基金排行实体模型
///
/// 统一的基金数据模型，替代原有的多个相似模型
class FundRanking extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 基金名称
  final String fundName;

  /// 基金类型
  final String fundType;

  /// 排名
  final int rank;

  /// 单位净值
  final double nav;

  /// 日增长率
  final double dailyReturn;

  /// 近1年收益率
  final double oneYearReturn;

  /// 近3年收益率
  final double threeYearReturn;

  /// 近5年收益率
  final double fiveYearReturn;

  /// 成立以来收益率
  final double sinceInceptionReturn;

  /// 基金规模
  final double fundSize;

  /// 更新日期
  final DateTime updateDate;

  /// 基金公司
  final String fundCompany;

  /// 基金经理
  final String fundManager;

  /// 手续费
  final double managementFee;

  /// 是否为模拟数据
  final bool isMockData;

  const FundRanking({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.rank,
    required this.nav,
    required this.dailyReturn,
    required this.oneYearReturn,
    required this.threeYearReturn,
    this.fiveYearReturn = 0.0,
    this.sinceInceptionReturn = 0.0,
    this.fundSize = 0.0,
    required this.updateDate,
    this.fundCompany = '',
    this.fundManager = '',
    this.managementFee = 0.0,
    this.isMockData = false,
  });

  /// 从JSON创建FundRanking对象
  factory FundRanking.fromJson(Map<String, dynamic> json, int rank) {
    // 处理缺失字段的情况
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        final cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
        return double.tryParse(cleanValue) ?? 0.0;
      }
      return 0.0;
    }

    String parseString(dynamic value) {
      return value?.toString() ?? '';
    }

    final fundCode = parseString(json['基金代码']);
    final fundName = parseString(json['基金简称']);
    final nav = parseDouble(json['单位净值']);
    final dailyReturn = parseDouble(json['日增长率']);
    final oneYearReturn = parseDouble(json['近1年']);
    final threeYearReturn = parseDouble(json['近3年']);

    // 检测是否为模拟数据
    final isMockData = fundCode.startsWith('1000') &&
        int.tryParse(fundCode) != null &&
        (int.tryParse(fundCode)! - 100000) % 11 == 0;

    return FundRanking(
      fundCode: fundCode,
      fundName: fundName,
      fundType: parseString(json['基金类型']),
      rank: rank,
      nav: nav,
      dailyReturn: dailyReturn,
      oneYearReturn: oneYearReturn,
      threeYearReturn: threeYearReturn,
      fiveYearReturn: parseDouble(json['近5年']),
      sinceInceptionReturn: parseDouble(json['成立以来']),
      fundSize: parseDouble(json['基金规模']),
      updateDate: DateTime.now(), // API中没有日期字段，使用当前时间
      fundCompany: parseString(json['基金公司']),
      fundManager: parseString(json['基金经理']),
      managementFee: parseDouble(json['管理费']),
      isMockData: isMockData,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      '基金代码': fundCode,
      '基金简称': fundName,
      '基金类型': fundType,
      '排名': rank,
      '单位净值': nav,
      '日增长率': dailyReturn,
      '近1年': oneYearReturn,
      '近3年': threeYearReturn,
      '近5年': fiveYearReturn,
      '成立以来': sinceInceptionReturn,
      '基金规模': fundSize,
      '更新日期': updateDate.toIso8601String(),
      '基金公司': fundCompany,
      '基金经理': fundManager,
      '管理费': managementFee,
      'isMockData': isMockData,
    };
  }

  /// 转换为API格式（兼容现有API）
  Map<String, dynamic> toApiJson() {
    return {
      '基金代码': fundCode,
      '基金简称': fundName,
      '基金类型': fundType,
      '单位净值': nav.toString(),
      '日增长率': dailyReturn.toString(),
      '近1年': oneYearReturn.toString(),
      '近3年': threeYearReturn.toString(),
      '近5年': fiveYearReturn.toString(),
      '成立以来': sinceInceptionReturn.toString(),
      '基金规模': fundSize.toString(),
      '基金公司': fundCompany,
      '基金经理': fundManager,
      '管理费': managementFee.toString(),
    };
  }

  /// 复制并修改部分属性
  FundRanking copyWith({
    String? fundCode,
    String? fundName,
    String? fundType,
    int? rank,
    double? nav,
    double? dailyReturn,
    double? oneYearReturn,
    double? threeYearReturn,
    double? fiveYearReturn,
    double? sinceInceptionReturn,
    double? fundSize,
    DateTime? updateDate,
    String? fundCompany,
    String? fundManager,
    double? managementFee,
    bool? isMockData,
  }) {
    return FundRanking(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      fundType: fundType ?? this.fundType,
      rank: rank ?? this.rank,
      nav: nav ?? this.nav,
      dailyReturn: dailyReturn ?? this.dailyReturn,
      oneYearReturn: oneYearReturn ?? this.oneYearReturn,
      threeYearReturn: threeYearReturn ?? this.threeYearReturn,
      fiveYearReturn: fiveYearReturn ?? this.fiveYearReturn,
      sinceInceptionReturn: sinceInceptionReturn ?? this.sinceInceptionReturn,
      fundSize: fundSize ?? this.fundSize,
      updateDate: updateDate ?? this.updateDate,
      fundCompany: fundCompany ?? this.fundCompany,
      fundManager: fundManager ?? this.fundManager,
      managementFee: managementFee ?? this.managementFee,
      isMockData: isMockData ?? this.isMockData,
    );
  }

  /// 获取收益率等级
  ReturnLevel getReturnLevel(String period) {
    double returnValue;
    switch (period.toLowerCase()) {
      case '1y':
      case '1年':
        returnValue = oneYearReturn;
        break;
      case '3y':
      case '3年':
        returnValue = threeYearReturn;
        break;
      case '5y':
      case '5年':
        returnValue = fiveYearReturn;
        break;
      case 'daily':
      case '日':
        returnValue = dailyReturn;
        break;
      default:
        returnValue = oneYearReturn;
    }

    if (returnValue >= 20.0) {
      return ReturnLevel.excellent;
    } else if (returnValue >= 10.0) {
      return ReturnLevel.good;
    } else if (returnValue >= 0.0) {
      return ReturnLevel.moderate;
    } else {
      return ReturnLevel.poor;
    }
  }

  /// 获取风险等级（基于基金类型）
  RiskLevel getRiskLevel() {
    final type = fundType.toLowerCase();

    if (type.contains('货币') || type.contains('现金')) {
      return RiskLevel.low;
    } else if (type.contains('债券')) {
      return RiskLevel.lowToMedium;
    } else if (type.contains('混合') || type.contains('配置')) {
      return RiskLevel.medium;
    } else if (type.contains('股票') || type.contains('指数')) {
      return RiskLevel.high;
    } else if (type.contains('qdii') || type.contains('海外')) {
      return RiskLevel.veryHigh;
    } else {
      return RiskLevel.medium;
    }
  }

  /// 格式化收益率为字符串
  String formatReturn(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  /// 格式化规模为字符串
  String formatFundSize() {
    if (fundSize >= 100000000000) {
      return '${(fundSize / 100000000000).toStringAsFixed(1)}千亿';
    } else if (fundSize >= 100000000) {
      return '${(fundSize / 100000000).toStringAsFixed(1)}亿';
    } else if (fundSize >= 10000) {
      return '${(fundSize / 10000).toStringAsFixed(1)}万';
    } else {
      return fundSize.toStringAsFixed(2);
    }
  }

  @override
  List<Object?> get props => [
        fundCode,
        fundName,
        fundType,
        rank,
        nav,
        dailyReturn,
        oneYearReturn,
        threeYearReturn,
        fiveYearReturn,
        sinceInceptionReturn,
        fundSize,
        updateDate,
        fundCompany,
        fundManager,
        managementFee,
        isMockData,
      ];

  @override
  String toString() {
    return 'FundRanking(fundCode: $fundCode, fundName: $fundName, rank: $rank, oneYearReturn: ${formatReturn(oneYearReturn)})';
  }

  // 为了兼容性提供的别名getter
  /// 基金代码别名（兼容性）
  String get code => fundCode;

  /// 基金名称别名（兼容性）
  String get name => fundName;

  /// 基金经理别名（兼容性）
  String get manager => fundManager;

  /// 近1年收益率别名（兼容性）
  double get return1Y => oneYearReturn;

  /// 是否为热门基金
  bool get isHot {
    // 基于收益率和规模判断是否为热门基金
    return oneYearReturn > 5.0 && fundSize > 1000000000; // 1年收益>5%且规模>10亿
  }

  /// 综合评分（用于排序和推荐）
  double get comprehensiveScore {
    // 综合考虑收益率、规模、风险等因素的评分
    double score = 0.0;

    // 收益率评分（权重40%）
    score += (oneYearReturn / 100.0) * 0.4;

    // 规模评分（权重20%），规模适中得分更高
    final sizeScore = fundSize > 0
        ? (1.0 - (fundSize - 5000000000).abs() / 50000000000).clamp(0.0, 1.0)
        : 0.0;
    score += sizeScore * 0.2;

    // 风险评分（权重20%）
    final riskScore = switch (getRiskLevel()) {
      RiskLevel.low => 0.8,
      RiskLevel.lowToMedium => 0.9,
      RiskLevel.medium => 1.0,
      RiskLevel.high => 0.7,
      RiskLevel.veryHigh => 0.6,
    };
    score += riskScore * 0.2;

    // 稳定性评分（权重20%），基于3年收益率的一致性
    final stabilityScore = threeYearReturn > 0
        ? (oneYearReturn / threeYearReturn).clamp(0.5, 2.0) / 2.0
        : 0.5;
    score += stabilityScore * 0.2;

    return score * 100; // 返回0-100的评分
  }

  /// 基金类型简称
  String get shortType {
    if (fundType.isEmpty) return '其他';

    // 提取主要类型关键词
    if (fundType.contains('股票')) return '股票型';
    if (fundType.contains('债券')) return '债券型';
    if (fundType.contains('混合')) return '混合型';
    if (fundType.contains('货币')) return '货币型';
    if (fundType.contains('指数')) return '指数型';
    if (fundType.contains('QDII')) return 'QDII';
    if (fundType.contains('FOF')) return 'FOF';

    return fundType.length > 6 ? fundType.substring(0, 6) : fundType;
  }
}

/// 收益率等级枚举
enum ReturnLevel {
  excellent, // 优秀 (>=20%)
  good, // 良好 (>=10%)
  moderate, // 中等 (>=0%)
  poor, // 较差 (<0%)
}

/// 风险等级枚举
enum RiskLevel {
  low, // 低风险
  lowToMedium, // 中低风险
  medium, // 中等风险
  high, // 高风险
  veryHigh, // 极高风险
}

/// ReturnLevel扩展
extension ReturnLevelExtension on ReturnLevel {
  String get displayName {
    switch (this) {
      case ReturnLevel.excellent:
        return '优秀';
      case ReturnLevel.good:
        return '良好';
      case ReturnLevel.moderate:
        return '中等';
      case ReturnLevel.poor:
        return '较差';
    }
  }

  String get colorHex {
    switch (this) {
      case ReturnLevel.excellent:
        return '#4CAF50'; // 绿色
      case ReturnLevel.good:
        return '#8BC34A'; // 浅绿色
      case ReturnLevel.moderate:
        return '#FF9800'; // 橙色
      case ReturnLevel.poor:
        return '#F44336'; // 红色
    }
  }
}

/// RiskLevel扩展
extension RiskLevelExtension on RiskLevel {
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return '低风险';
      case RiskLevel.lowToMedium:
        return '中低风险';
      case RiskLevel.medium:
        return '中等风险';
      case RiskLevel.high:
        return '高风险';
      case RiskLevel.veryHigh:
        return '极高风险';
    }
  }

  String get colorHex {
    switch (this) {
      case RiskLevel.low:
        return '#4CAF50'; // 绿色
      case RiskLevel.lowToMedium:
        return '#8BC34A'; // 浅绿色
      case RiskLevel.medium:
        return '#FF9800'; // 橙色
      case RiskLevel.high:
        return '#FF5722'; // 深橙色
      case RiskLevel.veryHigh:
        return '#F44336'; // 红色
    }
  }

  int get level {
    switch (this) {
      case RiskLevel.low:
        return 1;
      case RiskLevel.lowToMedium:
        return 2;
      case RiskLevel.medium:
        return 3;
      case RiskLevel.high:
        return 4;
      case RiskLevel.veryHigh:
        return 5;
    }
  }
}

/// 基金排行扩展方法
extension FundRankingExtensions on FundRanking {
  /// 是否为正收益
  bool get isPositive => oneYearReturn >= 0;

  /// 日收益是否为正
  bool get isDailyPositive => dailyReturn >= 0;

  /// 获取简短的基金名称（用于显示）
  String get shortName {
    if (fundName.length <= 12) return fundName;

    // 尝试在常见分隔符处截断
    final separators = ['(', '（', 'A', 'B', 'C'];
    for (final sep in separators) {
      final index = fundName.indexOf(sep);
      if (index > 0 && index <= 12) {
        return fundName.substring(0, index);
      }
    }

    return '${fundName.substring(0, 10)}...';
  }

  /// 获取基金类型的简称
  String get shortType {
    if (fundType.contains('股票')) return '股票型';
    if (fundType.contains('债券')) return '债券型';
    if (fundType.contains('混合')) return '混合型';
    if (fundType.contains('货币')) return '货币型';
    if (fundType.contains('指数')) return '指数型';
    if (fundType.contains('QDII')) return 'QDII';
    return fundType;
  }

  /// 是否为热门基金（基于收益率和规模）
  bool get isHot {
    return oneYearReturn >= 15.0 && fundSize >= 1000000000; // 15%以上且规模大于10亿
  }

  /// 计算综合评分（0-100）
  double get comprehensiveScore {
    double score = 0;

    // 收益率评分 (40%)
    score += (oneYearReturn.clamp(-20, 50) + 20) / 70 * 40;

    // 规模评分 (20%)
    final sizeScore = (fundSize.clamp(0, 100000000000) / 100000000000) * 20;
    score += sizeScore;

    // 风险调整评分 (40%) - 风险越低评分越高
    final riskLevel = getRiskLevel();
    switch (riskLevel) {
      case RiskLevel.low:
        score += 40;
        break;
      case RiskLevel.lowToMedium:
        score += 32;
        break;
      case RiskLevel.medium:
        score += 24;
        break;
      case RiskLevel.high:
        score += 16;
        break;
      case RiskLevel.veryHigh:
        score += 8;
        break;
    }

    return score.clamp(0, 100);
  }
}
