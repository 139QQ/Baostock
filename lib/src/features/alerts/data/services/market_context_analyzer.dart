import 'dart:async';
import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../../../market/models/market_index_data.dart';
import '../../../market/data/processors/market_index_data_manager.dart';
import '../../../market/data/cache/market_index_cache_manager.dart';
import '../models/market_change_event.dart';
import '../models/change_category.dart';
import '../models/change_severity.dart';
import '../processors/change_impact_assessor.dart';

/// 市场背景分析服务
///
/// 集成现有市场指数数据，为变化影响分析提供背景信息
class MarketContextAnalyzer {
  /// 市场指数数据管理器
  final MarketIndexDataManager _indexDataManager;

  /// 市场指数缓存管理器
  final MarketIndexCacheManager _cacheManager;

  /// 主要市场指数代码
  static const List<String> _majorIndices = [
    MarketIndexConstants.shanghaiComposite,
    MarketIndexConstants.shenzhenComponent,
    MarketIndexConstants.chiNext,
    MarketIndexConstants.csi300,
    MarketIndexConstants.hangSeng,
    MarketIndexConstants.dowJones,
    MarketIndexConstants.nasdaq,
  ];

  /// 行业指数映射
  static const Map<String, List<String>> _sectorIndices = {
    '科技': ['SZ399975', 'SH000995'], // 科创50, 中证全指
    '金融': ['SH000016', 'SH000688'], // 上证50, 科创50
    '消费': ['SZ399932', 'SH000300'], // 中证消费, 沪深300
    '医药': ['SZ399911', 'SH000905'], // 中证医药, 中证500
    '新能源': ['SZ399976', 'SH000852'], // 中证新能, 中证1000
  };

  /// 缓存的市场指数数据
  final Map<String, MarketIndexData> _cachedIndexData = {};

  /// 缓存过期时间（5分钟）
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// 上次更新时间
  DateTime _lastUpdateTime = DateTime.now();

  /// 构造函数
  MarketContextAnalyzer({
    MarketIndexDataManager? indexDataManager,
  })  : _indexDataManager = indexDataManager ?? MarketIndexDataManager(),
        _cacheManager = MarketIndexCacheManager();

  /// 分析市场背景
  Future<MarketBackgroundContext> analyzeMarketBackground({
    required MarketChangeEvent event,
    List<String>? relatedSectors,
  }) async {
    // 更新市场指数缓存
    await _updateIndexCache();

    // 获取主要市场指数表现
    final marketIndices = await _getMajorMarketIndices();

    // 获取相关行业指数表现
    final sectorIndices = await _getSectorIndices(relatedSectors);

    // 计算市场整体表现指标
    final marketPerformance = _calculateMarketPerformance(marketIndices);

    // 分析市场情绪
    final marketSentiment = _analyzeMarketSentiment(marketIndices, event);

    // 评估市场波动性
    final volatilityAnalysis = _analyzeVolatility(marketIndices);

    // 识别相关市场变化
    final relatedMarketChanges =
        _identifyRelatedMarketChanges(event, marketIndices);

    // 生成市场背景摘要
    final backgroundSummary = _generateBackgroundSummary(
      event,
      marketPerformance,
      marketSentiment,
      volatilityAnalysis,
    );

    return MarketBackgroundContext(
      eventTime: event.timestamp,
      marketPerformance: marketPerformance,
      marketSentiment: marketSentiment,
      volatilityAnalysis: volatilityAnalysis,
      majorIndices: marketIndices,
      sectorIndices: sectorIndices,
      relatedMarketChanges: relatedMarketChanges,
      backgroundSummary: backgroundSummary,
      analysisTimestamp: DateTime.now(),
    );
  }

  /// 更新指数缓存
  Future<void> _updateIndexCache() async {
    if (DateTime.now().difference(_lastUpdateTime) < _cacheExpiry) {
      return; // 缓存未过期，无需更新
    }

    try {
      final indices = _majorIndices;
      for (final code in indices) {
        try {
          final indexData = await _cacheManager.getCachedIndexData(code);
          if (indexData != null) {
            _cachedIndexData[code] = indexData;
          }
        } catch (e) {
          // 单个指数获取失败不影响其他指数
          continue;
        }
      }
      _lastUpdateTime = DateTime.now();
    } catch (e) {
      // 缓存更新失败，继续使用旧缓存
    }
  }

  /// 获取主要市场指数
  Future<List<MarketIndexSnapshot>> _getMajorMarketIndices() async {
    final snapshots = <MarketIndexSnapshot>[];

    for (final code in _majorIndices) {
      final data = _cachedIndexData[code];
      if (data != null) {
        snapshots.add(MarketIndexSnapshot(
          code: data.code,
          name: MarketIndexConstants.getIndexName(data.code),
          currentValue: data.currentValue.toDouble(),
          changeAmount: data.changeAmount.toDouble(),
          changePercentage: data.changePercentage.toDouble(),
          volume: data.volume,
          marketStatus: data.marketStatus,
          updateTime: data.updateTime,
        ));
      }
    }

    return snapshots;
  }

  /// 获取行业指数
  Future<List<MarketIndexSnapshot>> _getSectorIndices(
      List<String>? sectors) async {
    if (sectors == null || sectors.isEmpty) return [];

    final snapshots = <MarketIndexSnapshot>[];

    for (final sector in sectors) {
      final sectorCodes = _sectorIndices[sector] ?? [];
      for (final code in sectorCodes) {
        final data = _cachedIndexData[code];
        if (data != null) {
          snapshots.add(MarketIndexSnapshot(
            code: data.code,
            name: '${MarketIndexConstants.getIndexName(data.code)}($sector)',
            currentValue: data.currentValue.toDouble(),
            changeAmount: data.changeAmount.toDouble(),
            changePercentage: data.changePercentage.toDouble(),
            volume: data.volume,
            marketStatus: data.marketStatus,
            updateTime: data.updateTime,
          ));
        }
      }
    }

    return snapshots;
  }

  /// 计算市场整体表现
  MarketPerformanceMetrics _calculateMarketPerformance(
    List<MarketIndexSnapshot> indices,
  ) {
    if (indices.isEmpty) {
      return MarketPerformanceMetrics(
        overallScore: 0.0,
        bullishCount: 0,
        bearishCount: 0,
        neutralCount: 0,
        averageChange: 0.0,
        volumeRatio: 1.0,
      );
    }

    final changes = indices.map((i) => i.changePercentage).toList();
    final averageChange = changes.reduce((a, b) => a + b) / changes.length;

    // 计算上涨/下跌指数数量
    var bullishCount = 0;
    var bearishCount = 0;
    var neutralCount = 0;

    for (final index in indices) {
      if (index.changePercentage > 0.5) {
        bullishCount++;
      } else if (index.changePercentage < -0.5) {
        bearishCount++;
      } else {
        neutralCount++;
      }
    }

    // 计算市场综合评分 (-100 到 +100)
    var overallScore = averageChange * 10; // 基础分数
    overallScore += (bullishCount - bearishCount) * 5; // 偏向调整
    overallScore = overallScore.clamp(-100.0, 100.0);

    // 计算成交量比率
    final totalVolume = indices.fold<int>(0, (sum, i) => sum + i.volume);
    final volumeRatio =
        totalVolume > 0 ? (totalVolume / 100000000).clamp(0.1, 10.0) : 1.0;

    return MarketPerformanceMetrics(
      overallScore: overallScore,
      bullishCount: bullishCount,
      bearishCount: bearishCount,
      neutralCount: neutralCount,
      averageChange: averageChange,
      volumeRatio: volumeRatio,
    );
  }

  /// 分析市场情绪
  MarketSentimentAnalysis _analyzeMarketSentiment(
    List<MarketIndexSnapshot> indices,
    MarketChangeEvent event,
  ) {
    if (indices.isEmpty) {
      return MarketSentimentAnalysis(
        sentiment: MarketSentiment.neutral,
        confidence: 0.0,
        sentimentFactors: [],
        trendDirection: TrendDirection.sideways,
        marketStrength: MarketStrength.weak,
      );
    }

    final factors = <SentimentFactor>[];
    var sentimentScore = 0.0;

    // 主要指数表现
    final majorIndices = indices
        .where((i) => i.code.contains('SH000') || i.code.contains('SZ399'))
        .toList();

    if (majorIndices.isNotEmpty) {
      final majorAvgChange =
          majorIndices.map((i) => i.changePercentage).reduce((a, b) => a + b) /
              majorIndices.length;

      if (majorAvgChange > 1.0) {
        sentimentScore += 30;
        factors.add(SentimentFactor(
          type: FactorType.majorIndexStrength,
          weight: 0.3,
          value: majorAvgChange,
          description: '主要指数表现强势',
        ));
      } else if (majorAvgChange < -1.0) {
        sentimentScore -= 30;
        factors.add(SentimentFactor(
          type: FactorType.majorIndexWeakness,
          weight: 0.3,
          value: majorAvgChange,
          description: '主要指数表现疲软',
        ));
      }
    }

    // 事件影响分析
    if (event.category == ChangeCategory.abnormalEvent) {
      if (event.severity == ChangeSeverity.high) {
        sentimentScore -= 20;
        factors.add(SentimentFactor(
          type: FactorType.abnormalEvent,
          weight: 0.2,
          value: -1.0,
          description: '出现重大异常事件',
        ));
      }
    }

    // 计算综合情绪
    MarketSentiment sentiment;
    if (sentimentScore > 20) {
      sentiment = MarketSentiment.bullish;
    } else if (sentimentScore < -20) {
      sentiment = MarketSentiment.bearish;
    } else {
      sentiment = MarketSentiment.neutral;
    }

    // 计算趋势方向
    TrendDirection trendDirection;
    if (indices.any((i) => i.changePercentage > 2.0)) {
      trendDirection = TrendDirection.upward;
    } else if (indices.any((i) => i.changePercentage < -2.0)) {
      trendDirection = TrendDirection.downward;
    } else {
      trendDirection = TrendDirection.sideways;
    }

    // 计算市场强度
    var marketStrength = MarketStrength.weak;
    final strongMoves =
        indices.where((i) => i.changePercentage.abs() > 1.0).length;
    final totalIndices = indices.length;

    if (strongMoves / totalIndices > 0.6) {
      marketStrength = MarketStrength.strong;
    } else if (strongMoves / totalIndices > 0.3) {
      marketStrength = MarketStrength.moderate;
    }

    return MarketSentimentAnalysis(
      sentiment: sentiment,
      confidence: (sentimentScore.abs() / 50.0).clamp(0.0, 1.0),
      sentimentFactors: factors,
      trendDirection: trendDirection,
      marketStrength: marketStrength,
    );
  }

  /// 分析市场波动性
  VolatilityAnalysis _analyzeVolatility(List<MarketIndexSnapshot> indices) {
    if (indices.isEmpty) {
      return VolatilityAnalysis(
        currentVolatility: VolatilityLevel.low,
        volatilityTrend: VolatilityTrend.stable,
        volatilityScore: 0.0,
        riskFactors: [],
      );
    }

    // 计算波动性分数
    final changes = indices.map((i) => i.changePercentage.abs()).toList();
    final avgVolatility = changes.reduce((a, b) => a + b) / changes.length;
    final maxVolatility = changes.reduce(math.max);

    var volatilityScore = 0.0;
    final riskFactors = <VolatilityRiskFactor>[];

    // 平均波动性评分
    volatilityScore += avgVolatility * 2;

    // 最大波动性评分
    volatilityScore += maxVolatility;

    // 成交量波动性
    final volumes = indices.map((i) => i.volume.toDouble()).toList();
    if (volumes.isNotEmpty) {
      final avgVolume = volumes.reduce((a, b) => a + b) / volumes.length;
      final volumeVariance = volumes
              .map((v) => math.pow(v - avgVolume, 2))
              .reduce((a, b) => a + b) /
          volumes.length;
      volatilityScore += math.sqrt(volumeVariance) / 1000000; // 归一化

      if (volumeVariance > 1e12) {
        riskFactors.add(VolatilityRiskFactor(
          type: RiskFactorType.volumeVolatility,
          severity: RiskSeverity.medium,
          description: '成交量波动较大',
        ));
      }
    }

    // 判断波动性水平
    VolatilityLevel currentVolatility;
    if (volatilityScore > 5.0) {
      currentVolatility = VolatilityLevel.high;
    } else if (volatilityScore > 2.5) {
      currentVolatility = VolatilityLevel.medium;
    } else {
      currentVolatility = VolatilityLevel.low;
    }

    // 判断波动性趋势（简化实现）
    final volatilityTrend = VolatilityTrend.stable; // 需要历史数据支持

    return VolatilityAnalysis(
      currentVolatility: currentVolatility,
      volatilityTrend: volatilityTrend,
      volatilityScore: volatilityScore,
      riskFactors: riskFactors,
    );
  }

  /// 识别相关市场变化
  List<RelatedMarketChange> _identifyRelatedMarketChanges(
    MarketChangeEvent event,
    List<MarketIndexSnapshot> indices,
  ) {
    final relatedChanges = <RelatedMarketChange>[];

    for (final index in indices) {
      // 如果变化幅度超过阈值，认为是相关变化
      if (index.changePercentage.abs() > 1.0) {
        var correlation = MarketCorrelation.unknown;

        // 简单的相关性判断
        if (event.type == MarketChangeType.fundNav &&
            index.name.contains('指数')) {
          correlation = MarketCorrelation.high;
        } else if (event.type == MarketChangeType.marketIndex &&
            index.code != event.entityId) {
          correlation = MarketCorrelation.medium;
        }

        if (correlation != MarketCorrelation.unknown) {
          relatedChanges.add(RelatedMarketChange(
            entityCode: index.code,
            entityName: index.name,
            changeType:
                index.changePercentage > 0 ? ChangeType.rise : ChangeType.fall,
            changeAmount: index.changePercentage.abs(),
            correlation: correlation,
            impact: _assessRelatedChangeImpact(index),
          ));
        }
      }
    }

    // 按相关性排序
    relatedChanges
        .sort((a, b) => b.correlation.index.compareTo(a.correlation.index));

    return relatedChanges.take(5).toList(); // 最多返回5个相关变化
  }

  /// 评估相关变化的影响
  ImpactLevel _assessRelatedChangeImpact(MarketIndexSnapshot index) {
    if (index.changePercentage.abs() > 3.0) {
      return ImpactLevel.critical;
    } else if (index.changePercentage.abs() > 2.0) {
      return ImpactLevel.significant;
    } else if (index.changePercentage.abs() > 1.0) {
      return ImpactLevel.moderate;
    }
    return ImpactLevel.minor;
  }

  /// 生成背景摘要
  String _generateBackgroundSummary(
    MarketChangeEvent event,
    MarketPerformanceMetrics performance,
    MarketSentimentAnalysis sentiment,
    VolatilityAnalysis volatility,
  ) {
    final buffer = StringBuffer();

    // 市场整体表现
    buffer.write('当前市场${sentiment.sentiment.name}，');
    buffer.write(
        '主要指数${performance.bullishCount > performance.bearishCount ? "多数上涨" : "多数下跌"}，');
    buffer.write('平均涨跌幅${performance.averageChange.toStringAsFixed(2)}%。');

    // 市场情绪
    buffer.write('市场情绪${sentiment.marketStrength.name}，');
    buffer.write('趋势${sentiment.trendDirection.name}。');

    // 波动性
    buffer.write('波动性${volatility.currentVolatility.name}，');
    if (volatility.riskFactors.isNotEmpty) {
      buffer.write('存在${volatility.riskFactors.length}个风险因素。');
    }

    return buffer.toString();
  }
}

/// 市场背景上下文
class MarketBackgroundContext {
  /// 事件时间
  final DateTime eventTime;

  /// 市场表现指标
  final MarketPerformanceMetrics marketPerformance;

  /// 市场情绪分析
  final MarketSentimentAnalysis marketSentiment;

  /// 波动性分析
  final VolatilityAnalysis volatilityAnalysis;

  /// 主要指数快照
  final List<MarketIndexSnapshot> majorIndices;

  /// 行业指数快照
  final List<MarketIndexSnapshot> sectorIndices;

  /// 相关市场变化
  final List<RelatedMarketChange> relatedMarketChanges;

  /// 背景摘要
  final String backgroundSummary;

  /// 分析时间戳
  final DateTime analysisTimestamp;

  const MarketBackgroundContext({
    required this.eventTime,
    required this.marketPerformance,
    required this.marketSentiment,
    required this.volatilityAnalysis,
    required this.majorIndices,
    required this.sectorIndices,
    required this.relatedMarketChanges,
    required this.backgroundSummary,
    required this.analysisTimestamp,
  });
}

/// 市场表现指标
class MarketPerformanceMetrics {
  /// 综合评分 (-100 到 +100)
  final double overallScore;

  /// 上涨指数数量
  final int bullishCount;

  /// 下跌指数数量
  final int bearishCount;

  /// 平盘指数数量
  final int neutralCount;

  /// 平均变化百分比
  final double averageChange;

  /// 成交量比率
  final double volumeRatio;

  const MarketPerformanceMetrics({
    required this.overallScore,
    required this.bullishCount,
    required this.bearishCount,
    required this.neutralCount,
    required this.averageChange,
    required this.volumeRatio,
  });
}

/// 市场情绪分析
class MarketSentimentAnalysis {
  /// 市场情绪
  final MarketSentiment sentiment;

  /// 置信度 (0-1)
  final double confidence;

  /// 情绪影响因素
  final List<SentimentFactor> sentimentFactors;

  /// 趋势方向
  final TrendDirection trendDirection;

  /// 市场强度
  final MarketStrength marketStrength;

  const MarketSentimentAnalysis({
    required this.sentiment,
    required this.confidence,
    required this.sentimentFactors,
    required this.trendDirection,
    required this.marketStrength,
  });
}

/// 情绪影响因素
class SentimentFactor {
  /// 因素类型
  final FactorType type;

  /// 权重 (0-1)
  final double weight;

  /// 因素值
  final double value;

  /// 描述
  final String description;

  const SentimentFactor({
    required this.type,
    required this.weight,
    required this.value,
    required this.description,
  });
}

/// 波动性分析
class VolatilityAnalysis {
  /// 当前波动性水平
  final VolatilityLevel currentVolatility;

  /// 波动性趋势
  final VolatilityTrend volatilityTrend;

  /// 波动性分数
  final double volatilityScore;

  /// 风险因素
  final List<VolatilityRiskFactor> riskFactors;

  const VolatilityAnalysis({
    required this.currentVolatility,
    required this.volatilityTrend,
    required this.volatilityScore,
    required this.riskFactors,
  });
}

/// 波动性风险因素
class VolatilityRiskFactor {
  /// 风险类型
  final RiskFactorType type;

  /// 严重程度
  final RiskSeverity severity;

  /// 描述
  final String description;

  const VolatilityRiskFactor({
    required this.type,
    required this.severity,
    required this.description,
  });
}

/// 市场指数快照
class MarketIndexSnapshot {
  /// 指数代码
  final String code;

  /// 指数名称
  final String name;

  /// 当前值
  final double currentValue;

  /// 变化点数
  final double changeAmount;

  /// 变化百分比
  final double changePercentage;

  /// 成交量
  final int volume;

  /// 市场状态
  final MarketStatus marketStatus;

  /// 更新时间
  final DateTime updateTime;

  const MarketIndexSnapshot({
    required this.code,
    required this.name,
    required this.currentValue,
    required this.changeAmount,
    required this.changePercentage,
    required this.volume,
    required this.marketStatus,
    required this.updateTime,
  });
}

/// 相关市场变化
class RelatedMarketChange {
  /// 实体代码
  final String entityCode;

  /// 实体名称
  final String entityName;

  /// 变化类型
  final ChangeType changeType;

  /// 变化幅度
  final double changeAmount;

  /// 相关性
  final MarketCorrelation correlation;

  /// 影响
  final ImpactLevel impact;

  const RelatedMarketChange({
    required this.entityCode,
    required this.entityName,
    required this.changeType,
    required this.changeAmount,
    required this.correlation,
    required this.impact,
  });
}

// 枚举定义
enum FactorType {
  majorIndexStrength,
  majorIndexWeakness,
  abnormalEvent,
  volumeAnomaly
}

enum TrendDirection { upward, downward, sideways }

enum MarketStrength { weak, moderate, strong }

enum VolatilityLevel { low, medium, high }

enum VolatilityTrend { decreasing, stable, increasing }

enum RiskFactorType { priceVolatility, volumeVolatility, marketSentiment }

enum RiskSeverity { low, medium, high }

enum ChangeType { rise, fall, flat }

enum MarketCorrelation { high, medium, low, unknown }
