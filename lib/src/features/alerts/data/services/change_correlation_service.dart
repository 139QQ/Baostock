import 'dart:async';

import '../../../../../src/models/fund_info.dart';
import '../models/market_change_event.dart';
import '../models/change_category.dart';

/// 变化关联服务
///
/// 负责分析市场变化与相关基金的关联关系
class ChangeCorrelationService {
  /// 基金-指数关联映射缓存
  final Map<String, List<String>> _fundIndexCorrelationCache = {};

  /// 指数-基金关联映射缓存
  final Map<String, List<String>> _indexFundCorrelationCache = {};

  /// 基金行业分类缓存
  final Map<String, String> _fundIndustryCache = {};

  /// 基金投资风格缓存
  final Map<String, String> _fundStyleCache = {};

  /// 相关基金查找结果缓存
  final Map<String, List<RelatedFundInfo>> _relatedFundsCache = {};

  /// 构造函数
  ChangeCorrelationService();

  /// 根据市场指数变化查找相关基金
  Future<List<RelatedFundInfo>> findRelatedFundsForMarketChange(
    MarketChangeEvent marketChange,
    List<FundInfo> allFunds,
  ) async {
    final cacheKey = '${marketChange.entityId}_${marketChange.category.name}';

    // 检查缓存
    if (_relatedFundsCache.containsKey(cacheKey)) {
      return _relatedFundsCache[cacheKey]!;
    }

    final relatedFunds = <RelatedFundInfo>[];

    for (final fund in allFunds) {
      final correlationScore = _calculateFundIndexCorrelation(
        fundCode: fund.code,
        fundName: fund.name,
        fundType: fund.type,
        indexCode: marketChange.entityId,
        changeCategory: marketChange.category,
      );

      if (correlationScore > 0.3) {
        // 相关性阈值
        relatedFunds.add(RelatedFundInfo(
          fundCode: fund.code,
          fundName: fund.name,
          fundType: fund.type,
          correlationScore: correlationScore,
          correlationReason: _getCorrelationReason(correlationScore),
        ));
      }
    }

    // 按相关性分数排序
    relatedFunds
        .sort((a, b) => b.correlationScore.compareTo(a.correlationScore));

    // 缓存结果
    _relatedFundsCache[cacheKey] = relatedFunds;

    return relatedFunds;
  }

  /// 根据基金变化查找其他相关基金
  Future<List<RelatedFundInfo>> findRelatedFundsForFundChange(
    MarketChangeEvent fundChange,
    List<FundInfo> allFunds,
  ) async {
    final relatedFunds = <RelatedFundInfo>[];

    // 获取变化基金的信息
    final changedFund = allFunds.firstWhere(
      (fund) => fund.code == fundChange.entityId,
      orElse: () => FundInfo.empty(),
    );

    for (final fund in allFunds) {
      if (fund.code == fundChange.entityId) continue; // 跳过自身

      final correlationScore = _calculateFundFundCorrelation(
        fund1Code: changedFund.code,
        fund1Type: changedFund.type,
        fund1Name: changedFund.name,
        fund2Code: fund.code,
        fund2Type: fund.type,
        fund2Name: fund.name,
      );

      if (correlationScore > 0.4) {
        // 基金间相关性阈值
        relatedFunds.add(RelatedFundInfo(
          fundCode: fund.code,
          fundName: fund.name,
          fundType: fund.type,
          correlationScore: correlationScore,
          correlationReason: _getFundCorrelationReason(correlationScore),
        ));
      }
    }

    // 按相关性分数排序
    relatedFunds
        .sort((a, b) => b.correlationScore.compareTo(a.correlationScore));

    return relatedFunds.take(10).toList(); // 最多返回10个相关基金
  }

  /// 计算基金与指数的相关性分数
  double _calculateFundIndexCorrelation({
    required String fundCode,
    required String fundName,
    required String fundType,
    required String indexCode,
    required ChangeCategory changeCategory,
  }) {
    var score = 0.0;

    // 基于基金类型的相关性
    score += _calculateTypeBasedCorrelation(fundType, indexCode);

    // 基于基金名称的相关性
    score += _calculateNameBasedCorrelation(fundName, indexCode);

    // 基于变化类别的相关性
    score += _calculateCategoryBasedCorrelation(changeCategory, fundType);

    // 确保分数在0-1之间
    return (score / 3.0).clamp(0.0, 1.0);
  }

  /// 计算基金间的相关性分数
  double _calculateFundFundCorrelation({
    required String fund1Code,
    required String fund1Type,
    required String fund1Name,
    required String fund2Code,
    required String fund2Type,
    required String fund2Name,
  }) {
    var score = 0.0;

    // 基于基金类型的相关性
    if (fund1Type == fund2Type) {
      score += 0.6;
    } else if (_areCompatibleTypes(fund1Type, fund2Type)) {
      score += 0.3;
    }

    // 基于基金名称的相关性（同一基金公司、同一投资主题等）
    score += _calculateFundNameSimilarity(fund1Name, fund2Name);

    // 确保分数在0-1之间
    return (score / 2.0).clamp(0.0, 1.0);
  }

  /// 基于基金类型计算与指数的相关性
  double _calculateTypeBasedCorrelation(String fundType, String indexCode) {
    // 股票型基金与股票指数相关性高
    if (_isStockFund(fundType) && _isStockIndex(indexCode)) {
      return 0.8;
    }

    // 债券型基金与债券指数相关性高
    if (_isBondFund(fundType) && _isBondIndex(indexCode)) {
      return 0.8;
    }

    // 混合型基金与主要指数都有一定相关性
    if (_isHybridFund(fundType)) {
      return 0.5;
    }

    // 指数型基金与对应指数相关性极高
    if (_isIndexFund(fundType) && _fundMatchesIndex(fundType, indexCode)) {
      return 0.95;
    }

    return 0.1;
  }

  /// 基于基金名称计算与指数的相关性
  double _calculateNameBasedCorrelation(String fundName, String indexCode) {
    final fundNameLower = fundName.toLowerCase();
    final indexCodeLower = indexCode.toLowerCase();

    // 基金名称中包含指数代码
    if (fundNameLower.contains(indexCodeLower)) {
      return 0.9;
    }

    // 基金名称中包含指数关键词
    final indexKeywords = _getIndexKeywords(indexCode);
    int matchCount = 0;
    for (final keyword in indexKeywords) {
      if (fundNameLower.contains(keyword)) {
        matchCount++;
      }
    }

    if (matchCount > 0) {
      return 0.3 + (matchCount * 0.2);
    }

    return 0.0;
  }

  /// 基于变化类别计算相关性
  double _calculateCategoryBasedCorrelation(
      ChangeCategory category, String fundType) {
    switch (category) {
      case ChangeCategory.abnormalEvent:
        // 异常事件对所有基金都有一定影响
        return 0.6;
      case ChangeCategory.trendChange:
        // 趋势变化对特定类型基金影响较大
        if (_isStockFund(fundType) || _isIndexFund(fundType)) {
          return 0.7;
        }
        return 0.4;
      case ChangeCategory.priceChange:
        // 价格变化对活跃基金影响较大
        if (_isStockFund(fundType)) {
          return 0.6;
        }
        return 0.3;
    }
  }

  /// 计算基金名称相似性
  double _calculateFundNameSimilarity(String name1, String name2) {
    final name1Lower = name1.toLowerCase();

    // 同一基金公司
    final company1 = _extractCompanyName(name1);
    final company2 = _extractCompanyName(name2);
    if (company1.isNotEmpty && company1 == company2) {
      return 0.3;
    }

    // 相同投资主题
    final themes1 = _extractInvestmentThemes(name1);
    final themes2 = _extractInvestmentThemes(name2);
    final commonThemes =
        themes1.where((theme) => themes2.contains(theme)).length;

    if (commonThemes > 0) {
      return 0.2 + (commonThemes * 0.1);
    }

    return 0.0;
  }

  /// 获取相关性原因描述
  String _getCorrelationReason(double score) {
    if (score >= 0.8) {
      return '高度相关';
    } else if (score >= 0.6) {
      return '较强相关';
    } else if (score >= 0.4) {
      return '中等相关';
    } else {
      return '弱相关';
    }
  }

  /// 获取基金间相关性原因描述
  String _getFundCorrelationReason(double score) {
    if (score >= 0.7) {
      return '同类型基金';
    } else if (score >= 0.5) {
      return '相似投资策略';
    } else {
      return '潜在关联';
    }
  }

  // 辅助方法
  bool _isStockFund(String fundType) {
    return fundType.contains('股票') ||
        fundType.contains('Stock') ||
        fundType.contains('权益');
  }

  bool _isBondFund(String fundType) {
    return fundType.contains('债券') ||
        fundType.contains('Bond') ||
        fundType.contains('固收');
  }

  bool _isHybridFund(String fundType) {
    return fundType.contains('混合') ||
        fundType.contains('Hybrid') ||
        fundType.contains('配置');
  }

  bool _isIndexFund(String fundType) {
    return fundType.contains('指数') ||
        fundType.contains('Index') ||
        fundType.contains('ETF');
  }

  bool _isStockIndex(String indexCode) {
    return indexCode.startsWith('000') || // 沪深指数
        indexCode.startsWith('399') || // 深证指数
        indexCode.contains('SH') ||
        indexCode.contains('SZ');
  }

  bool _isBondIndex(String indexCode) {
    return indexCode.startsWith('CBA') || // 中债指数
        indexCode.contains('Bond') ||
        indexCode.contains('债券');
  }

  bool _areCompatibleTypes(String type1, String type2) {
    // 股票型和混合型兼容
    if ((_isStockFund(type1) || _isHybridFund(type1)) &&
        (_isStockFund(type2) || _isHybridFund(type2))) {
      return true;
    }

    // 债券型和混合型兼容
    if ((_isBondFund(type1) || _isHybridFund(type1)) &&
        (_isBondFund(type2) || _isHybridFund(type2))) {
      return true;
    }

    return false;
  }

  bool _fundMatchesIndex(String fundType, String indexCode) {
    final fundTypeLower = fundType.toLowerCase();
    if (indexCode.contains('000001') && fundTypeLower.contains('沪深300'))
      return true;
    if (indexCode.contains('000300') && fundTypeLower.contains('沪深300'))
      return true;
    if (indexCode.contains('399001') && fundTypeLower.contains('深证成指'))
      return true;
    if (indexCode.contains('999987') && fundTypeLower.contains('中证1000'))
      return true;
    return false;
  }

  List<String> _getIndexKeywords(String indexCode) {
    switch (indexCode) {
      case '000001':
      case '000300':
        return ['沪深', '300', 'hs300'];
      case '399001':
        return ['深证', '成指', 'szcz'];
      case '000016':
        return ['上证', '50', 'sse50'];
      case '000905':
        return ['中证', '500', 'csi500'];
      case '999987':
        return ['中证', '1000', 'csi1000'];
      default:
        return [];
    }
  }

  String _extractCompanyName(String fundName) {
    // 简单的基金公司名称提取逻辑
    final companies = [
      '华夏',
      '易方达',
      '南方',
      '博时',
      '嘉实',
      '汇添富',
      '富国',
      '工银瑞信',
      '建信',
      '中银',
      '招商',
      '兴业',
      '广发',
      '华安',
      '交银施罗德',
      '银华',
    ];

    for (final company in companies) {
      if (fundName.startsWith(company)) {
        return company;
      }
    }

    return '';
  }

  List<String> _extractInvestmentThemes(String fundName) {
    final themes = <String>[];
    final nameLower = fundName.toLowerCase();

    if (nameLower.contains('消费')) themes.add('消费');
    if (nameLower.contains('医疗')) themes.add('医疗');
    if (nameLower.contains('科技')) themes.add('科技');
    if (nameLower.contains('新能源')) themes.add('新能源');
    if (nameLower.contains('半导体')) themes.add('半导体');
    if (nameLower.contains('军工')) themes.add('军工');
    if (nameLower.contains('银行')) themes.add('银行');
    if (nameLower.contains('地产')) themes.add('地产');

    return themes;
  }

  /// 清理缓存
  void clearCache() {
    _fundIndexCorrelationCache.clear();
    _indexFundCorrelationCache.clear();
    _fundIndustryCache.clear();
    _fundStyleCache.clear();
    _relatedFundsCache.clear();
  }
}

/// 相关基金信息
class RelatedFundInfo {
  /// 基金代码
  final String fundCode;

  /// 基金名称
  final String fundName;

  /// 基金类型
  final String fundType;

  /// 相关性分数 (0-1)
  final double correlationScore;

  /// 相关性原因
  final String correlationReason;

  const RelatedFundInfo({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.correlationScore,
    required this.correlationReason,
  });

  @override
  String toString() {
    return 'RelatedFundInfo(fundCode: $fundCode, fundName: $fundName, score: $correlationScore)';
  }
}
