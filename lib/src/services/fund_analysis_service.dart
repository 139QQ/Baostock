import 'dart:async';
import 'dart:math' as math;
import 'package:decimal/decimal.dart';
import '../models/fund_info.dart';
import '../core/cache/unified_hive_cache_manager.dart';
import 'high_performance_fund_service.dart';
import 'fund_api_service.dart';

/// 基金分析服务 - 业务逻辑层核心
///
/// 职责：
/// - 技术指标计算（MA、RSI、布林带等）
/// - 风险评估分析
/// - 收益率统计
/// - 基金评分和排序
class FundAnalysisService {
  static final FundAnalysisService _instance = FundAnalysisService._internal();
  factory FundAnalysisService() => _instance;
  FundAnalysisService._internal();

  final UnifiedHiveCacheManager _cacheManager =
      UnifiedHiveCacheManager.instance;

  final HighPerformanceFundService _fundService = HighPerformanceFundService();

  // 缓存配置
  static const String _analysisCachePrefix = 'fund_analysis_';
  static const Duration _analysisCacheExpiry = Duration(minutes: 30);

  /// 初始化分析服务
  Future<void> initialize() async {
    await _fundService.initialize();
  }

  // ========================================
  // 技术指标计算
  // ========================================

  /// 计算移动平均线 (MA)
  /// period: 周期，如5日、10日、20日等
  Future<List<MovingAverageData>> calculateMovingAverage(
    String fundCode, {
    int period = 5,
    bool useCache = true,
  }) async {
    final cacheKey = '${_analysisCachePrefix}ma_${fundCode}_${period}';

    if (useCache) {
      final cached = await _cacheManager.get<List<MovingAverageData>>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    try {
      // 获取基金净值历史数据
      final navHistory = await _getFundNavHistory(fundCode, period * 2);

      final maData = <MovingAverageData>[];
      for (int i = period - 1; i < navHistory.length; i++) {
        var sum = Decimal.fromInt(0);
        for (int j = 0; j < period; j++) {
          final navValueStr = navHistory[i - j].navValue.toString();
          final nav = Decimal.tryParse(navValueStr) ?? Decimal.fromInt(0);
          sum += nav;
        }

        final maValue = sum / Decimal.fromInt(period);
        maData.add(MovingAverageData(
          date: navHistory[i].date,
          value: maValue.toDouble(),
          period: period,
        ));
      }

      // 缓存结果
      if (useCache) {
        await _cacheManager.put(cacheKey, maData);
      }

      return maData;
    } catch (e) {
      throw Exception('计算移动平均线失败: $e');
    }
  }

  /// 计算相对强弱指数 (RSI)
  /// period: 通常使用14日
  Future<List<RSIData>> calculateRSI(
    String fundCode, {
    int period = 14,
    bool useCache = true,
  }) async {
    final cacheKey = '${_analysisCachePrefix}rsi_${fundCode}_${period}';

    if (useCache) {
      final cached = await _cacheManager.get<List<RSIData>>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    try {
      final navHistory = await _getFundNavHistory(fundCode, period * 3);

      if (navHistory.length < period + 1) {
        throw Exception('数据不足，无法计算RSI');
      }

      final rsiData = <RSIData>[];
      List<double> gains = [];
      List<double> losses = [];

      // 计算初始涨跌幅
      for (int i = 1; i <= period; i++) {
        final change = navHistory[i].navValue - navHistory[i - 1].navValue;
        if (change > 0) {
          gains.add(change);
          losses.add(0);
        } else {
          gains.add(0);
          losses.add(change.abs());
        }
      }

      // 计算RSI
      for (int i = period; i < navHistory.length; i++) {
        final avgGain = gains.reduce((a, b) => a + b) / gains.length;
        final avgLoss = losses.reduce((a, b) => a + b) / losses.length;

        final rs = avgGain / avgLoss;
        final rsi = 100 - (100 / (1 + rs));

        rsiData.add(RSIData(
          date: navHistory[i].date,
          value: rsi,
          period: period,
        ));

        // 滑动窗口更新
        if (i < navHistory.length - 1) {
          final nextChange =
              navHistory[i + 1].navValue - navHistory[i].navValue;

          gains.removeAt(0);
          losses.removeAt(0);

          if (nextChange > 0) {
            gains.add(nextChange);
            losses.add(0);
          } else {
            gains.add(0);
            losses.add(nextChange.abs());
          }
        }
      }

      // 缓存结果
      if (useCache) {
        await _cacheManager.put(cacheKey, rsiData);
      }

      return rsiData;
    } catch (e) {
      throw Exception('计算RSI失败: $e');
    }
  }

  /// 计算布林带 (Bollinger Bands)
  Future<List<BollingerBandsData>> calculateBollingerBands(
    String fundCode, {
    int period = 20,
    double stdDev = 2.0,
    bool useCache = true,
  }) async {
    final cacheKey =
        '${_analysisCachePrefix}bb_${fundCode}_${period}_${stdDev.toStringAsFixed(1)}';

    if (useCache) {
      final cached =
          await _cacheManager.get<List<BollingerBandsData>>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    try {
      final navHistory = await _getFundNavHistory(fundCode, period + 10);

      final bbData = <BollingerBandsData>[];

      for (int i = period - 1; i < navHistory.length; i++) {
        // 计算移动平均
        var sum = Decimal.fromInt(0);
        for (int j = 0; j < period; j++) {
          final navValueStr = navHistory[i - j].navValue.toString();
          final nav = Decimal.tryParse(navValueStr) ?? Decimal.fromInt(0);
          sum += nav;
        }
        final ma = sum / Decimal.fromInt(period);

        // 计算标准差
        double variance = 0;
        for (int j = 0; j < period; j++) {
          final navValueStr = navHistory[i - j].navValue.toString();
          final nav = Decimal.tryParse(navValueStr) ?? Decimal.fromInt(0);
          final diff = (nav.toDouble() - ma.toDouble());
          variance += diff * diff;
        }
        variance /= period;
        final standardDeviation = math.sqrt(variance);

        final upperBand =
            double.parse(ma.toString()) + (stdDev * standardDeviation);
        final lowerBand =
            double.parse(ma.toString()) - (stdDev * standardDeviation);

        bbData.add(BollingerBandsData(
          date: navHistory[i].date,
          middleBand: double.parse(ma.toString()),
          upperBand: upperBand,
          lowerBand: lowerBand,
          period: period,
          stdDev: stdDev,
        ));
      }

      // 缓存结果
      if (useCache) {
        await _cacheManager.put(cacheKey, bbData);
      }

      return bbData;
    } catch (e) {
      throw Exception('计算布林带失败: $e');
    }
  }

  // ========================================
  // 风险评估分析
  // ========================================

  /// 计算基金风险指标
  Future<FundRiskMetrics> calculateRiskMetrics(
    String fundCode, {
    int period = 252, // 一年交易日
    bool useCache = true,
  }) async {
    final cacheKey = '${_analysisCachePrefix}risk_${fundCode}_${period}';

    if (useCache) {
      final cached = await _cacheManager.get<FundRiskMetrics>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    try {
      final navHistory = await _getFundNavHistory(fundCode, period);

      if (navHistory.length < 30) {
        throw Exception('数据不足，无法计算风险指标');
      }

      // 计算日收益率
      final dailyReturns = <double>[];
      for (int i = 1; i < navHistory.length; i++) {
        final dailyReturn =
            (navHistory[i].navValue - navHistory[i - 1].navValue) /
                navHistory[i - 1].navValue;
        dailyReturns.add(dailyReturn);
      }

      // 计算平均收益率
      final avgReturn =
          dailyReturns.reduce((a, b) => a + b) / dailyReturns.length;

      // 计算波动率 (标准差)
      final variance = dailyReturns
              .map((r) => math.pow(r - avgReturn, 2))
              .reduce((a, b) => a + b) /
          dailyReturns.length;
      final volatility = math.sqrt(variance) * math.sqrt(252); // 年化波动率

      // 计算最大回撤
      double maxDrawdown = 0;
      double peak = navHistory[0].navValue;

      for (final nav in navHistory) {
        if (nav.navValue > peak) {
          peak = nav.navValue;
        } else {
          final drawdown = (peak - nav.navValue) / peak;
          if (drawdown > maxDrawdown) {
            maxDrawdown = drawdown;
          }
        }
      }

      // 计算夏普比率 (假设无风险利率为3%)
      final riskFreeRate = 0.03;
      final annualizedReturn = avgReturn * 252;
      final sharpeRatio = (annualizedReturn - riskFreeRate) / volatility;

      // 计算Beta系数 (假设市场基准年化收益为8%)
      final marketReturn = 0.08;
      final beta =
          (annualizedReturn - riskFreeRate) / (marketReturn - riskFreeRate);

      final riskMetrics = FundRiskMetrics(
        fundCode: fundCode,
        volatility: volatility,
        maxDrawdown: maxDrawdown,
        sharpeRatio: sharpeRatio,
        beta: beta,
        averageReturn: avgReturn,
        calculatedAt: DateTime.now(),
        period: period,
      );

      // 缓存结果
      if (useCache) {
        await _cacheManager.put(cacheKey, riskMetrics);
      }

      return riskMetrics;
    } catch (e) {
      throw Exception('计算风险指标失败: $e');
    }
  }

  // ========================================
  // 基金评分和排序
  // ========================================

  /// 计算基金综合评分
  Future<FundScore> calculateFundScore(String fundCode) async {
    try {
      // 获取风险指标
      final riskMetrics = await calculateRiskMetrics(fundCode);

      // 获取基金基本信息
      final funds = _fundService.searchFunds(fundCode, limit: 1);
      if (funds.isEmpty) {
        throw Exception('未找到基金信息');
      }
      final fund = funds.first;

      // 评分维度 (0-100分)
      double sharpeScore =
          _normalizeScore(riskMetrics.sharpeRatio, -1, 3, 0, 100);
      double volatilityScore =
          _normalizeScore(riskMetrics.volatility, 0.5, 0.05, 0, 100); // 波动率越低越好
      double drawdownScore =
          _normalizeScore(riskMetrics.maxDrawdown, 0, 0.3, 0, 100); // 回撤越小越好
      double returnScore =
          _normalizeScore(riskMetrics.averageReturn * 252, -0.1, 0.2, 0, 100);

      // 加权计算综合评分
      final totalScore = (sharpeScore * 0.3) +
          (volatilityScore * 0.25) +
          (drawdownScore * 0.25) +
          (returnScore * 0.2);

      // 风险等级评定
      String riskLevel;
      if (riskMetrics.volatility < 0.1) {
        riskLevel = '低风险';
      } else if (riskMetrics.volatility < 0.2) {
        riskLevel = '中等风险';
      } else {
        riskLevel = '高风险';
      }

      return FundScore(
        fundCode: fundCode,
        fundName: fund.name,
        fundType: fund.simplifiedType,
        totalScore: totalScore.round(),
        sharpeScore: sharpeScore.round(),
        volatilityScore: volatilityScore.round(),
        drawdownScore: drawdownScore.round(),
        returnScore: returnScore.round(),
        riskLevel: riskLevel,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('计算基金评分失败: $e');
    }
  }

  /// 获取推荐基金列表
  Future<List<FundScore>> getRecommendedFunds({
    String fundType = '全部',
    int limit = 10,
  }) async {
    try {
      // 获取基金列表
      final funds = fundType == '全部'
          ? _fundService.searchFunds('', limit: 100)
          : _fundService.searchFunds(fundType, limit: 100);

      if (funds.isEmpty) return [];

      // 并行计算评分
      final futures =
          funds.map((fund) => calculateFundScore(fund.code)).toList();
      final scores = await Future.wait(futures);

      // 按评分排序
      scores.sort((a, b) => b.totalScore.compareTo(a.totalScore));

      return scores.take(limit).toList();
    } catch (e) {
      throw Exception('获取推荐基金失败: $e');
    }
  }

  // ========================================
  // 私有辅助方法
  // ========================================

  /// 获取基金净值历史数据 (模拟)
  Future<List<FundNavData>> _getFundNavHistory(
      String fundCode, int days) async {
    // 这里应该调用实际的API获取历史数据
    // 暂时返回模拟数据
    final navHistory = <FundNavData>[];
    final random = math.Random();
    final now = DateTime.now();

    // 模拟一个净值数据
    double baseNav = 1.0 + (random.nextDouble() * 2.0);

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final change = (random.nextDouble() - 0.5) * 0.02; // -1% 到 +1% 的日变化
      baseNav = baseNav * (1 + change);

      navHistory.add(FundNavData(
        fundCode: fundCode,
        date: date,
        navValue: baseNav,
        accumulatedNav: baseNav * 1.15, // 假设累计净值更高
      ));
    }

    return navHistory;
  }

  /// 标准化分数到指定范围
  double _normalizeScore(double value, double minValue, double maxValue,
      double minScore, double maxScore) {
    if (maxValue - minValue == 0) return minScore;

    final normalized = (value - minValue) / (maxValue - minValue);
    final clampedValue = normalized.clamp(0.0, 1.0);

    return minScore + (clampedValue * (maxScore - minScore));
  }

  /// 清理分析缓存
  Future<void> clearAnalysisCache() async {
    try {
      // TODO: 实现缓存清理功能
      // await _cacheManager.removeByPattern('$_analysisCachePrefix*');
    } catch (e) {
      // 忽略清理错误
    }
  }

  /// 关闭服务
  Future<void> dispose() async {
    // 清理资源
  }
}

// ========================================
// 数据模型定义
// ========================================

/// 移动平均线数据
class MovingAverageData {
  final DateTime date;
  final double value;
  final int period;

  MovingAverageData({
    required this.date,
    required this.value,
    required this.period,
  });
}

/// RSI数据
class RSIData {
  final DateTime date;
  final double value;
  final int period;

  RSIData({
    required this.date,
    required this.value,
    required this.period,
  });
}

/// 布林带数据
class BollingerBandsData {
  final DateTime date;
  final double middleBand;
  final double upperBand;
  final double lowerBand;
  final int period;
  final double stdDev;

  BollingerBandsData({
    required this.date,
    required this.middleBand,
    required this.upperBand,
    required this.lowerBand,
    required this.period,
    required this.stdDev,
  });

  /// 获取带宽
  double get bandwidth => upperBand - lowerBand;

  /// 获取%B值 (价格在布林带中的位置)
  double calculatePercentB(double currentPrice) {
    return (currentPrice - lowerBand) / bandwidth;
  }
}

/// 基金风险指标
class FundRiskMetrics {
  final String fundCode;
  final double volatility; // 波动率
  final double maxDrawdown; // 最大回撤
  final double sharpeRatio; // 夏普比率
  final double beta; // Beta系数
  final double averageReturn; // 平均收益率
  final DateTime calculatedAt; // 计算时间
  final int period; // 数据周期

  FundRiskMetrics({
    required this.fundCode,
    required this.volatility,
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.beta,
    required this.averageReturn,
    required this.calculatedAt,
    required this.period,
  });

  Map<String, dynamic> toJson() {
    return {
      'fundCode': fundCode,
      'volatility': volatility,
      'maxDrawdown': maxDrawdown,
      'sharpeRatio': sharpeRatio,
      'beta': beta,
      'averageReturn': averageReturn,
      'calculatedAt': calculatedAt.toIso8601String(),
      'period': period,
    };
  }

  factory FundRiskMetrics.fromJson(Map<String, dynamic> json) {
    return FundRiskMetrics(
      fundCode: json['fundCode'],
      volatility: (json['volatility'] ?? 0).toDouble(),
      maxDrawdown: (json['maxDrawdown'] ?? 0).toDouble(),
      sharpeRatio: (json['sharpeRatio'] ?? 0).toDouble(),
      beta: (json['beta'] ?? 0).toDouble(),
      averageReturn: (json['averageReturn'] ?? 0).toDouble(),
      calculatedAt: DateTime.parse(json['calculatedAt']),
      period: json['period'] ?? 0,
    );
  }
}

/// 基金评分
class FundScore {
  final String fundCode;
  final String fundName;
  final String fundType;
  final int totalScore; // 综合评分
  final int sharpeScore; // 夏普比率评分
  final int volatilityScore; // 波动率评分
  final int drawdownScore; // 回撤评分
  final int returnScore; // 收益评分
  final String riskLevel; // 风险等级
  final DateTime calculatedAt; // 计算时间

  FundScore({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.totalScore,
    required this.sharpeScore,
    required this.volatilityScore,
    required this.drawdownScore,
    required this.returnScore,
    required this.riskLevel,
    required this.calculatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'fundCode': fundCode,
      'fundName': fundName,
      'fundType': fundType,
      'totalScore': totalScore,
      'sharpeScore': sharpeScore,
      'volatilityScore': volatilityScore,
      'drawdownScore': drawdownScore,
      'returnScore': returnScore,
      'riskLevel': riskLevel,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory FundScore.fromJson(Map<String, dynamic> json) {
    return FundScore(
      fundCode: json['fundCode'],
      fundName: json['fundName'],
      fundType: json['fundType'],
      totalScore: json['totalScore'] ?? 0,
      sharpeScore: json['sharpeScore'] ?? 0,
      volatilityScore: json['volatilityScore'] ?? 0,
      drawdownScore: json['drawdownScore'] ?? 0,
      returnScore: json['returnScore'] ?? 0,
      riskLevel: json['riskLevel'] ?? '',
      calculatedAt: DateTime.parse(json['calculatedAt']),
    );
  }
}

/// 基金净值数据
class FundNavData {
  final String fundCode;
  final DateTime date;
  final double navValue;
  final double accumulatedNav;

  FundNavData({
    required this.fundCode,
    required this.date,
    required this.navValue,
    required this.accumulatedNav,
  });

  Map<String, dynamic> toJson() {
    return {
      'fundCode': fundCode,
      'date': date.toIso8601String(),
      'navValue': navValue,
      'accumulatedNav': accumulatedNav,
    };
  }

  factory FundNavData.fromJson(Map<String, dynamic> json) {
    return FundNavData(
      fundCode: json['fundCode'],
      date: DateTime.parse(json['date']),
      navValue: (json['navValue'] ?? 0).toDouble(),
      accumulatedNav: (json['accumulatedNav'] ?? 0).toDouble(),
    );
  }
}
