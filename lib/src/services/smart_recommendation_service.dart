import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../core/utils/logger.dart';
import '../core/cache/unified_hive_cache_manager.dart';
import '../features/fund/shared/services/fund_data_service.dart';
import '../features/fund/shared/models/fund_ranking.dart';

/// 智能推荐服务
///
/// 基于现有基金数据提供个性化推荐算法，包括：
/// - 收益率导向推荐
/// - 风险调整后收益推荐
/// - 规模偏好推荐
/// - 热门趋势推荐
class SmartRecommendationService {
  static const String _cacheKeyPrefix = 'smart_recommendations_';
  static const Duration _cacheExpireTime = Duration(minutes: 30); // 30分钟缓存
  static const int _maxRecommendations = 10; // 最大推荐数量

  final FundDataService _fundDataService;
  final UnifiedHiveCacheManager _cacheManager;

  // 推荐算法配置
  static const double _recentReturnWeight = 0.4; // 近期收益率权重
  static const double _totalReturnWeight = 0.3; // 总收益率权重
  static const double _fundSizeWeight = 0.2; // 基金规模权重
  static const double _riskLevelWeight = 0.1; // 风险等级权重

  SmartRecommendationService({
    required FundDataService fundDataService,
    required UnifiedHiveCacheManager cacheManager,
  })  : _fundDataService = fundDataService,
        _cacheManager = cacheManager;

  /// 获取智能推荐基金列表
  Future<RecommendationResult> getSmartRecommendations({
    RecommendationStrategy strategy = RecommendationStrategy.balanced,
    int limit = _maxRecommendations,
    bool forceRefresh = false,
    UserPreferences? userPreferences,
  }) async {
    AppLogger.info(
        '🎯 SmartRecommendationService: 开始获取智能推荐 (strategy: $strategy)');

    try {
      // 1. 检查缓存
      if (!forceRefresh) {
        final cachedRecommendations = await _getCachedRecommendations(strategy);
        if (cachedRecommendations != null) {
          AppLogger.info(
              '💾 推荐数据缓存命中 (${cachedRecommendations.recommendations.length}条)');
          return cachedRecommendations;
        }
      }

      // 2. 获取基础基金数据
      final fundsResult = await _fundDataService.getFundRankings();
      if (fundsResult.isFailure || fundsResult.data == null) {
        AppLogger.error('❌ 获取基金数据失败: ${fundsResult.errorMessage}',
            fundsResult.errorMessage);
        return RecommendationResult.failure(
            '获取基金数据失败: ${fundsResult.errorMessage ?? "未知错误"}');
      }

      final allFunds = fundsResult.data!;
      AppLogger.info('📊 获取到 ${allFunds.length} 只基金数据');

      // 3. 数据预处理和过滤
      final filteredFunds = _preprocessAndFilterFunds(allFunds);
      AppLogger.info('🔍 过滤后剩余 ${filteredFunds.length} 只有效基金');

      // 4. 应用推荐算法
      final recommendations = await _applyRecommendationAlgorithm(
        filteredFunds,
        strategy,
        userPreferences ?? UserPreferences.defaultPreferences(),
      );

      // 5. 限制推荐数量并排序
      final finalRecommendations = recommendations.take(limit).toList();
      AppLogger.info('✅ 生成 ${finalRecommendations.length} 条推荐');

      // 6. 缓存推荐结果
      final result = RecommendationResult.success(finalRecommendations);
      await _cacheRecommendations(strategy, result);

      return result;
    } catch (e) {
      AppLogger.error('❌ 获取智能推荐失败', e);
      return RecommendationResult.failure('获取推荐失败: $e');
    }
  }

  /// 数据预处理和过滤
  List<FundRanking> _preprocessAndFilterFunds(List<FundRanking> funds) {
    return funds.where((fund) {
      // 过滤掉异常数据
      try {
        // 检查必要字段
        if (fund.fundName.isEmpty || fund.fundCode.isEmpty) {
          return false;
        }

        // 过滤收益率异常值
        if (fund.dailyReturn.abs() > 100) {
          // 单日涨跌幅超过100%视为异常
          return false;
        }

        // 过滤规模过小的基金（避免流动性风险）
        if (fund.fundSize < 100000000) {
          // 小于1亿的基金
          return false;
        }

        // 过滤模拟数据
        if (fund.isMockData) {
          return false;
        }

        return true;
      } catch (e) {
        AppLogger.debug('跳过异常基金数据: ${fund.fundCode} - $e');
        return false;
      }
    }).toList();
  }

  /// 应用推荐算法
  Future<List<RecommendationItem>> _applyRecommendationAlgorithm(
    List<FundRanking> funds,
    RecommendationStrategy strategy,
    UserPreferences preferences,
  ) async {
    final recommendations = <RecommendationItem>[];

    // 根据策略选择不同的算法
    switch (strategy) {
      case RecommendationStrategy.highReturn:
        recommendations.addAll(await _highReturnStrategy(funds, preferences));
        break;
      case RecommendationStrategy.stable:
        recommendations.addAll(await _stableStrategy(funds, preferences));
        break;
      case RecommendationStrategy.balanced:
        recommendations.addAll(await _balancedStrategy(funds, preferences));
        break;
      case RecommendationStrategy.trending:
        recommendations.addAll(await _trendingStrategy(funds, preferences));
        break;
      case RecommendationStrategy.personalized:
        recommendations.addAll(await _personalizedStrategy(funds, preferences));
        break;
    }

    // 按推荐分数排序
    recommendations.sort((a, b) => b.score.compareTo(a.score));

    return recommendations;
  }

  /// 高收益推荐策略
  Future<List<RecommendationItem>> _highReturnStrategy(
      List<FundRanking> funds, UserPreferences preferences) async {
    final recommendations = <RecommendationItem>[];

    for (final fund in funds) {
      final score = _calculateHighReturnScore(fund);
      final reason = _generateHighReturnReason(fund);

      recommendations.add(RecommendationItem(
        fund: fund,
        score: score,
        reason: reason,
        strategy: RecommendationStrategy.highReturn,
      ));
    }

    return recommendations;
  }

  /// 稳健推荐策略
  Future<List<RecommendationItem>> _stableStrategy(
      List<FundRanking> funds, UserPreferences preferences) async {
    final recommendations = <RecommendationItem>[];

    for (final fund in funds) {
      final score = _calculateStableScore(fund);
      final reason = _generateStableReason(fund);

      recommendations.add(RecommendationItem(
        fund: fund,
        score: score,
        reason: reason,
        strategy: RecommendationStrategy.stable,
      ));
    }

    return recommendations;
  }

  /// 平衡推荐策略
  Future<List<RecommendationItem>> _balancedStrategy(
      List<FundRanking> funds, UserPreferences preferences) async {
    final recommendations = <RecommendationItem>[];

    for (final fund in funds) {
      final score = _calculateBalancedScore(fund);
      final reason = _generateBalancedReason(fund);

      recommendations.add(RecommendationItem(
        fund: fund,
        score: score,
        reason: reason,
        strategy: RecommendationStrategy.balanced,
      ));
    }

    return recommendations;
  }

  /// 热门趋势推荐策略
  Future<List<RecommendationItem>> _trendingStrategy(
      List<FundRanking> funds, UserPreferences preferences) async {
    final recommendations = <RecommendationItem>[];

    // 分析近期热门基金（基于近期涨跌幅和规模）
    final sortedFunds = List<FundRanking>.from(funds)
      ..sort((a, b) => b.dailyReturn.compareTo(a.dailyReturn));

    final topFunds = sortedFunds.take(50).toList(); // 取前50只热门基金

    for (final fund in topFunds) {
      final score = _calculateTrendingScore(fund, topFunds);
      final reason = _generateTrendingReason(fund);

      recommendations.add(RecommendationItem(
        fund: fund,
        score: score,
        reason: reason,
        strategy: RecommendationStrategy.trending,
      ));
    }

    return recommendations;
  }

  /// 个性化推荐策略
  Future<List<RecommendationItem>> _personalizedStrategy(
      List<FundRanking> funds, UserPreferences preferences) async {
    final recommendations = <RecommendationItem>[];

    for (final fund in funds) {
      final score = _calculatePersonalizedScore(fund, preferences);
      final reason = _generatePersonalizedReason(fund, preferences);

      recommendations.add(RecommendationItem(
        fund: fund,
        score: score,
        reason: reason,
        strategy: RecommendationStrategy.personalized,
      ));
    }

    return recommendations;
  }

  /// 计算高收益推荐分数
  double _calculateHighReturnScore(FundRanking fund) {
    try {
      final dailyReturn = fund.dailyReturn;
      final oneYearReturn = fund.oneYearReturn;
      final riskLevel = _getRiskLevelScore(fund.getRiskLevel());

      // 主要考虑收益率，适度考虑风险
      double score = 0.0;

      // 近期日收益率权重60%
      score += (dailyReturn > 0 ? dailyReturn : 0) * 0.6;

      // 年收益率权重30%
      score += (oneYearReturn > 0 ? oneYearReturn : 0) * 0.3;

      // 风险惩罚（风险越高，分数越低）权重10%
      score += (5 - riskLevel) * 2 * 0.1;

      return max(0, score);
    } catch (e) {
      AppLogger.debug('计算高收益分数失败: ${fund.fundCode} - $e');
      return 0.0;
    }
  }

  /// 将RiskLevel转换为数值分数
  double _getRiskLevelScore(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return 1.0;
      case RiskLevel.lowToMedium:
        return 2.0;
      case RiskLevel.medium:
        return 3.0;
      case RiskLevel.high:
        return 4.0;
      case RiskLevel.veryHigh:
        return 5.0;
    }
  }

  /// 计算稳健推荐分数
  double _calculateStableScore(FundRanking fund) {
    try {
      final dailyReturn = fund.dailyReturn;
      final oneYearReturn = fund.oneYearReturn;
      final fundSize = fund.fundSize;
      final riskLevel = _getRiskLevelScore(fund.getRiskLevel());

      double score = 0.0;

      // 风险权重40%（风险越低分数越高）
      score += (5 - riskLevel) * 10 * 0.4;

      // 基金规模权重30%（规模越大越稳定）
      score += min(fundSize / 10000000000, 10) * 0.3; // 100亿为满分

      // 收益率稳定性权重20%（避免大幅波动）
      final volatility = (dailyReturn - oneYearReturn / 12).abs(); // 简化波动率计算
      score += max(0, 10 - volatility) * 0.2;

      // 正收益奖励权重10%
      score += (dailyReturn > 0 && oneYearReturn > 0 ? 10 : 0) * 0.1;

      return max(0, score);
    } catch (e) {
      AppLogger.debug('计算稳健分数失败: ${fund.fundCode} - $e');
      return 0.0;
    }
  }

  /// 计算平衡推荐分数
  double _calculateBalancedScore(FundRanking fund) {
    try {
      final dailyReturn = fund.dailyReturn;
      final oneYearReturn = fund.oneYearReturn;
      final fundSize = fund.fundSize;
      final riskLevel = _getRiskLevelScore(fund.getRiskLevel());

      // 使用故事中提供的算法
      double sizeScore = min(fundSize / 10000000000, 10) / 10; // 归一化到0-1
      double riskScore = (5 - riskLevel) / 5; // 风险分数，低风险高分

      double score = dailyReturn * _recentReturnWeight +
          oneYearReturn * _totalReturnWeight +
          sizeScore * _fundSizeWeight +
          riskScore * _riskLevelWeight;

      return max(0, score * 10); // 放大到0-10范围
    } catch (e) {
      AppLogger.debug('计算平衡分数失败: ${fund.fundCode} - $e');
      return 0.0;
    }
  }

  /// 计算热门趋势分数
  double _calculateTrendingScore(FundRanking fund, List<FundRanking> topFunds) {
    try {
      final dailyReturn = fund.dailyReturn;
      final rank = topFunds.indexOf(fund) + 1; // 排名（1-based）

      // 排名权重50%（排名越高分数越高）
      double rankScore = max(0, (51 - rank) / 50);

      // 收益率权重50%
      double returnScore = min(dailyReturn / 10, 1); // 假设10%为满分

      return (rankScore * 0.5 + returnScore * 0.5) * 10;
    } catch (e) {
      AppLogger.debug('计算热门趋势分数失败: ${fund.fundCode} - $e');
      return 0.0;
    }
  }

  /// 计算个性化推荐分数
  double _calculatePersonalizedScore(
      FundRanking fund, UserPreferences preferences) {
    try {
      final dailyReturn = fund.dailyReturn;
      final oneYearReturn = fund.oneYearReturn;
      final fundSize = fund.fundSize;
      final riskLevel = _getRiskLevelScore(fund.getRiskLevel());

      double score = 0.0;

      // 根据用户风险偏好调整分数
      switch (preferences.riskTolerance) {
        case RiskTolerance.low:
          // 低风险偏好：重视稳定性和低风险
          score += (5 - riskLevel) * 8 * 0.4;
          score += min(fundSize / 10000000000, 10) * 0.3;
          score += (dailyReturn > 0 ? min(dailyReturn, 5) : 0) * 0.3;
          break;
        case RiskTolerance.medium:
          // 中等风险偏好：平衡收益和风险
          score += _calculateBalancedScore(fund);
          break;
        case RiskTolerance.high:
          // 高风险偏好：重视高收益
          score += _calculateHighReturnScore(fund);
          break;
      }

      // 根据用户投资期限调整
      switch (preferences.investmentHorizon) {
        case InvestmentHorizon.short:
          // 短期：更看重近期表现
          score += dailyReturn * 0.2;
          break;
        case InvestmentHorizon.medium:
          // 中期：平衡近期和长期表现
          score += (dailyReturn + oneYearReturn / 12) * 0.1;
          break;
        case InvestmentHorizon.long:
          // 长期：更看重长期表现
          score += oneYearReturn * 0.05;
          break;
      }

      return max(0, score);
    } catch (e) {
      AppLogger.debug('计算个性化分数失败: ${fund.fundCode} - $e');
      return 0.0;
    }
  }

  /// 生成高收益推荐理由
  String _generateHighReturnReason(FundRanking fund) {
    if (fund.dailyReturn > 5) {
      return '近期表现优异，日涨跌幅${fund.dailyReturn.toStringAsFixed(2)}%';
    } else if (fund.oneYearReturn > 50) {
      return '长期收益突出，年收益率${fund.oneYearReturn.toStringAsFixed(2)}%';
    } else {
      return '收益稳健增长';
    }
  }

  /// 生成稳健推荐理由
  String _generateStableReason(FundRanking fund) {
    final riskLevel = _getRiskLevelScore(fund.getRiskLevel());
    if (riskLevel <= 2) {
      return '低风险稳健型基金，适合保守投资';
    } else if (fund.fundSize > 10000000000) {
      return '大规模基金，流动性强波动小';
    } else {
      return '风险收益平衡，长期持有稳健';
    }
  }

  /// 生成平衡推荐理由
  String _generateBalancedReason(FundRanking fund) {
    final riskLevel = _getRiskLevelScore(fund.getRiskLevel());
    if (fund.dailyReturn > 2 && riskLevel <= 3) {
      return '收益与风险平衡，攻守兼备';
    } else if (fund.fundSize > 5000000000 && fund.oneYearReturn > 20) {
      return '规模适中收益良好，长期配置优选';
    } else {
      return '综合表现优秀，值得配置';
    }
  }

  /// 生成热门趋势推荐理由
  String _generateTrendingReason(FundRanking fund) {
    if (fund.dailyReturn > 8) {
      return '市场热门基金，近期强势上涨${fund.dailyReturn.toStringAsFixed(2)}%';
    } else if (fund.dailyReturn > 3) {
      return '市场关注度较高，表现活跃';
    } else {
      return '趋势向好，值得关注';
    }
  }

  /// 生成个性化推荐理由
  String _generatePersonalizedReason(
      FundRanking fund, UserPreferences preferences) {
    final riskLevel = _getRiskLevelScore(fund.getRiskLevel());
    switch (preferences.riskTolerance) {
      case RiskTolerance.low:
        if (riskLevel <= 2) {
          return '符合您的低风险偏好，稳健增值';
        } else {
          return '风险可控，适合您的投资风格';
        }
      case RiskTolerance.medium:
        return '风险收益平衡，契合您的投资需求';
      case RiskTolerance.high:
        if (fund.dailyReturn > 5) {
          return '高收益潜力，符合您的风险偏好';
        } else {
          return '具备较好成长性，值得关注';
        }
    }
  }

  /// 从缓存获取推荐数据
  Future<RecommendationResult?> _getCachedRecommendations(
      RecommendationStrategy strategy) async {
    try {
      final cacheKey = '$_cacheKeyPrefix${strategy.name}_${DateTime.now().day}';
      final cachedData = _cacheManager.get<String>(cacheKey);

      if (cachedData == null) {
        return null;
      }

      final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;

      // 检查缓存是否过期
      final timestamp = DateTime.parse(jsonData['timestamp'] as String);
      if (DateTime.now().difference(timestamp) > _cacheExpireTime) {
        await _cacheManager.remove(cacheKey);
        return null;
      }

      final recommendationsList = jsonData['recommendations'] as List<dynamic>;
      final recommendations = recommendationsList
          .map((item) =>
              RecommendationItem.fromJson(item as Map<String, dynamic>))
          .toList();

      return RecommendationResult.success(recommendations);
    } catch (e) {
      AppLogger.error('❌ 缓存推荐数据解析失败', e);
      return null;
    }
  }

  /// 缓存推荐数据
  Future<void> _cacheRecommendations(
      RecommendationStrategy strategy, RecommendationResult result) async {
    try {
      if (result.isFailure) return;

      final cacheKey = '$_cacheKeyPrefix${strategy.name}_${DateTime.now().day}';
      final cacheData = {
        'recommendations': result.data!.map((item) => item.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'strategy': strategy.name,
      };

      await _cacheManager.put(
        cacheKey,
        jsonEncode(cacheData),
        expiration: _cacheExpireTime,
      );

      AppLogger.info('💾 智能推荐数据已缓存: $cacheKey');
    } catch (e) {
      AppLogger.warn('⚠️ 缓存推荐数据失败，但不影响正常流程: $e');
    }
  }

  /// 清除推荐缓存
  Future<void> clearRecommendationCache(
      {RecommendationStrategy? strategy}) async {
    try {
      if (strategy != null) {
        final cacheKey =
            '$_cacheKeyPrefix${strategy.name}_${DateTime.now().day}';
        await _cacheManager.remove(cacheKey);
        AppLogger.info('🗑️ 已清除 ${strategy.name} 推荐缓存');
      } else {
        // 清除所有推荐缓存（简化实现）
        AppLogger.info('🗑️ 推荐缓存清除功能需要更精细的实现');
      }
    } catch (e) {
      AppLogger.error('❌ 清除推荐缓存失败', e);
    }
  }

  /// 获取推荐统计信息
  Future<Map<String, dynamic>> getRecommendationStats() async {
    try {
      // 这里可以实现更详细的统计功能
      return {
        'cache_expiration_minutes': _cacheExpireTime.inMinutes,
        'max_recommendations': _maxRecommendations,
        'supported_strategies':
            RecommendationStrategy.values.map((s) => s.name).toList(),
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.error('❌ 获取推荐统计失败', e);
      return {'error': e.toString()};
    }
  }
}

/// 推荐策略枚举
enum RecommendationStrategy {
  highReturn, // 高收益策略
  stable, // 稳健策略
  balanced, // 平衡策略
  trending, // 热门趋势策略
  personalized, // 个性化策略
}

/// 用户风险偏好枚举
enum RiskTolerance {
  low, // 低风险偏好
  medium, // 中等风险偏好
  high, // 高风险偏好
}

/// 投资期限枚举
enum InvestmentHorizon {
  short, // 短期（<1年）
  medium, // 中期（1-3年）
  long, // 长期（>3年）
}

/// 用户偏好设置
class UserPreferences {
  final RiskTolerance riskTolerance;
  final InvestmentHorizon investmentHorizon;
  final List<String> preferredFundTypes; // 偏好的基金类型
  final List<String> excludedFundTypes; // 排除的基金类型
  final double minFundSize; // 最小基金规模
  final int maxRiskLevel; // 最大风险等级

  const UserPreferences({
    required this.riskTolerance,
    required this.investmentHorizon,
    this.preferredFundTypes = const [],
    this.excludedFundTypes = const [],
    this.minFundSize = 100000000, // 1亿
    this.maxRiskLevel = 5,
  });

  /// 默认用户偏好
  static UserPreferences defaultPreferences() {
    return const UserPreferences(
      riskTolerance: RiskTolerance.medium,
      investmentHorizon: InvestmentHorizon.medium,
    );
  }
}

/// 推荐结果封装
class RecommendationResult {
  final List<RecommendationItem>? data;
  final String? errorMessage;
  final bool isSuccess;

  const RecommendationResult._({
    this.data,
    this.errorMessage,
    required this.isSuccess,
  });

  factory RecommendationResult.success(
      List<RecommendationItem> recommendations) {
    return RecommendationResult._(
      data: recommendations,
      isSuccess: true,
    );
  }

  factory RecommendationResult.failure(String errorMessage) {
    return RecommendationResult._(
      errorMessage: errorMessage,
      isSuccess: false,
    );
  }

  bool get isFailure => !isSuccess;

  List<RecommendationItem> get recommendations => data ?? [];

  /// 获取数据或抛出异常
  List<RecommendationItem> get dataOrThrow {
    if (isSuccess) {
      return data!;
    } else {
      throw Exception(errorMessage);
    }
  }
}

/// 推荐项目
class RecommendationItem {
  final FundRanking fund;
  final double score; // 推荐分数 (0-10)
  final String reason; // 推荐理由
  final RecommendationStrategy strategy; // 推荐策略

  RecommendationItem({
    required this.fund,
    required this.score,
    required this.reason,
    required this.strategy,
  });

  /// 收益率显示文本
  String get returnDisplayText {
    if (fund.dailyReturn > 0) {
      return '+${fund.dailyReturn.toStringAsFixed(2)}%';
    } else {
      return '${fund.dailyReturn.toStringAsFixed(2)}%';
    }
  }

  /// 是否为正收益
  bool get isPositiveReturn => fund.dailyReturn > 0;

  /// 基金规模显示文本
  String get fundSizeDisplay {
    final sizeInYi = fund.fundSize / 100000000; // 转换为亿
    if (sizeInYi >= 10000) {
      return '${(sizeInYi / 10000).toStringAsFixed(1)}万亿';
    } else if (sizeInYi >= 100) {
      return '${(sizeInYi / 100).toStringAsFixed(1)}千亿';
    } else {
      return '${sizeInYi.toStringAsFixed(1)}亿';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'fund': fund.toJson(),
      'score': score,
      'reason': reason,
      'strategy': strategy.name,
    };
  }

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      fund: FundRanking.fromJson(json['fund'] as Map<String, dynamic>, 0),
      score: (json['score'] as num).toDouble(),
      reason: json['reason'] as String,
      strategy: RecommendationStrategy.values.firstWhere(
        (s) => s.name == json['strategy'],
        orElse: () => RecommendationStrategy.balanced,
      ),
    );
  }

  @override
  String toString() {
    return 'RecommendationItem(fund: ${fund.fundName}, score: $score, reason: $reason)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationItem &&
          runtimeType == other.runtimeType &&
          fund.fundCode == other.fund.fundCode &&
          score == other.score;

  @override
  int get hashCode => fund.fundCode.hashCode ^ score.hashCode;
}
