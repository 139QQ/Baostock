import 'dart:collection';
import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../../models/market_index_data.dart';
import '../../models/index_change_data.dart';

/// 指数变化分析器
///
/// 负责检测和分析市场指数的变化趋势、重要变化点和技术信号
class IndexChangeAnalyzer {
  /// 变化历史记录 (每个指数保留最近的变化记录)
  final Map<String, Queue<IndexChangeData>> _changeHistory = {};

  /// 技术分析参数
  final TechnicalAnalysisParameters _parameters;

  /// 构造函数
  IndexChangeAnalyzer({
    TechnicalAnalysisParameters? parameters,
  }) : _parameters = parameters ?? TechnicalAnalysisParameters();

  /// 分析指数变化
  IndexChangeData analyzeChange(
      MarketIndexData currentData, MarketIndexData? previousData) {
    final indexCode = currentData.code;

    // 计算基本变化数据
    final changeData = IndexChangeData.calculateChange(
      currentData: currentData,
      previousData: previousData,
    );

    // 扩展技术分析
    final extendedChangeData =
        _performExtendedAnalysis(changeData, currentData, previousData);

    // 记录变化历史
    _recordChangeHistory(indexCode, extendedChangeData);

    return extendedChangeData;
  }

  /// 执行扩展技术分析
  IndexChangeData _performExtendedAnalysis(
    IndexChangeData basicChangeData,
    MarketIndexData currentData,
    MarketIndexData? previousData,
  ) {
    if (previousData == null) {
      return basicChangeData;
    }

    final technicalSignals = <TechnicalSignal>[];
    final changePercentage = basicChangeData.currentData.changePercentage;

    // 1. 大幅波动分析
    if (changePercentage.abs() >= _parameters.largeMoveThreshold) {
      technicalSignals.add(TechnicalSignal(
        type: SignalType.largeMove,
        strength: _calculateSignalStrength(changePercentage.abs()),
        description: '大幅波动 ${changePercentage.toStringAsFixed(2)}%',
        additionalData: {
          'changePercentage': changePercentage.toString(),
          'threshold': _parameters.largeMoveThreshold.toString(),
        },
      ));
    }

    // 2. 成交量异常分析
    final volumeChange = _analyzeVolumeChange(currentData, previousData);
    if (volumeChange.isAnomalous) {
      technicalSignals.add(TechnicalSignal(
        type: SignalType.volumeAnomaly,
        strength: volumeChange.strength,
        description: volumeChange.description,
        additionalData: {
          'currentVolume': currentData.volume,
          'previousVolume': previousData.volume,
          'changePercentage': volumeChange.changePercentage.toString(),
        },
      ));
    }

    // 3. 价格突破分析
    final breakoutAnalysis = _analyzePriceBreakout(currentData, previousData);
    if (breakoutAnalysis.hasBreakout &&
        breakoutAnalysis.type != null &&
        breakoutAnalysis.strength != null &&
        breakoutAnalysis.description != null) {
      technicalSignals.add(TechnicalSignal(
        type: breakoutAnalysis.type!,
        strength: breakoutAnalysis.strength!,
        description: breakoutAnalysis.description!,
        additionalData: breakoutAnalysis.additionalData,
      ));
    }

    // 4. 趋势分析
    final trendAnalysis = _analyzeTrend(currentData.code);
    if (trendAnalysis.hasReversal &&
        trendAnalysis.strength != null &&
        trendAnalysis.description != null &&
        trendAnalysis.previousTrend != null &&
        trendAnalysis.currentTrend != null) {
      technicalSignals.add(TechnicalSignal(
        type: SignalType.trendReversal,
        strength: trendAnalysis.strength!,
        description: trendAnalysis.description!,
        additionalData: {
          'previousTrend': trendAnalysis.previousTrend!.name,
          'currentTrend': trendAnalysis.currentTrend!.name,
        },
      ));
    }

    // 5. 支撑阻力位分析
    final supportResistanceAnalysis = _analyzeSupportResistance(currentData);
    if (supportResistanceAnalysis.hasSignal &&
        supportResistanceAnalysis.type != null &&
        supportResistanceAnalysis.strength != null &&
        supportResistanceAnalysis.description != null) {
      technicalSignals.add(TechnicalSignal(
        type: supportResistanceAnalysis.type!,
        strength: supportResistanceAnalysis.strength!,
        description: supportResistanceAnalysis.description!,
        additionalData: supportResistanceAnalysis.additionalData,
      ));
    }

    // 6. 波动率分析
    final volatilityAnalysis = _analyzeVolatility(currentData.code);
    if (volatilityAnalysis.isUnusual &&
        volatilityAnalysis.strength != null &&
        volatilityAnalysis.description != null &&
        volatilityAnalysis.currentVolatility != null &&
        volatilityAnalysis.averageVolatility != null &&
        volatilityAnalysis.volatilityRatio != null) {
      technicalSignals.add(TechnicalSignal(
        type: SignalType.largeMove, // 复用大幅波动类型
        strength: volatilityAnalysis.strength!,
        description: '波动率异常: ${volatilityAnalysis.description}',
        additionalData: {
          'currentVolatility': volatilityAnalysis.currentVolatility.toString(),
          'averageVolatility': volatilityAnalysis.averageVolatility.toString(),
          'volatilityRatio': volatilityAnalysis.volatilityRatio.toString(),
        },
      ));
    }

    return IndexChangeData(
      indexCode: basicChangeData.indexCode,
      indexName: basicChangeData.indexName,
      previousData: basicChangeData.previousData,
      currentData: basicChangeData.currentData,
      changeType: basicChangeData.changeType,
      magnitude: _enhanceMagnitude(basicChangeData.magnitude, technicalSignals),
      changeTime: basicChangeData.changeTime,
      isSignificant: _isSignificantChange(basicChangeData, technicalSignals),
      changeDescription: basicChangeData.changeDescription,
      technicalSignals: technicalSignals,
    );
  }

  /// 计算信号强度
  SignalStrength _calculateSignalStrength(Decimal changePercentage) {
    if (changePercentage.abs() >= Decimal.fromInt(5)) {
      return SignalStrength.strong;
    } else if (changePercentage.abs() >= Decimal.fromInt(2)) {
      return SignalStrength.moderate;
    } else {
      return SignalStrength.weak;
    }
  }

  /// 分析成交量变化
  VolumeChangeAnalysis _analyzeVolumeChange(
      MarketIndexData currentData, MarketIndexData previousData) {
    final currentVolume = currentData.volume;
    final previousVolume = previousData.volume;

    if (previousVolume == 0) {
      return VolumeChangeAnalysis(
        isAnomalous: false,
        strength: SignalStrength.weak,
        description: '无历史成交量数据',
        changePercentage: Decimal.zero,
      );
    }

    final volumeChange = currentVolume - previousVolume;
    final Decimal changePercentage = Decimal.parse(
        (Decimal.fromInt(volumeChange) *
                Decimal.fromInt(100) /
                Decimal.fromInt(previousVolume))
            .toString());

    // 成交量变化超过100%认为是异常
    final isAnomalous = changePercentage.abs() >= Decimal.fromInt(100);
    final strength = changePercentage.abs() >= Decimal.fromInt(200)
        ? SignalStrength.strong
        : SignalStrength.moderate;

    return VolumeChangeAnalysis(
      isAnomalous: isAnomalous,
      strength: strength,
      description:
          '成交量${changePercentage > Decimal.zero ? '增加' : '减少'}${changePercentage.abs().toStringAsFixed(1)}%',
      changePercentage: changePercentage,
    );
  }

  /// 分析价格突破
  PriceBreakoutAnalysis _analyzePriceBreakout(
      MarketIndexData currentData, MarketIndexData previousData) {
    final signals = <PriceBreakoutAnalysis>[];

    // 突破新高
    if (currentData.currentValue > currentData.highPrice) {
      final strength = currentData.changePercentage.abs() >= Decimal.fromInt(2)
          ? SignalStrength.strong
          : SignalStrength.moderate;

      signals.add(PriceBreakoutAnalysis(
        hasBreakout: true,
        type: SignalType.breakout,
        strength: strength,
        description: '突破当日新高 ${currentData.highPrice.toString()}',
        additionalData: {
          'newHigh': currentData.currentValue.toString(),
          'previousHigh': currentData.highPrice.toString(),
          'breakoutPercentage':
              ((currentData.currentValue - currentData.highPrice) *
                      Decimal.fromInt(100) /
                      currentData.highPrice)
                  .toString(),
        },
      ));
    }

    // 跌破新低
    if (currentData.currentValue < currentData.lowPrice) {
      final strength = currentData.changePercentage.abs() >= Decimal.fromInt(2)
          ? SignalStrength.strong
          : SignalStrength.moderate;

      signals.add(PriceBreakoutAnalysis(
        hasBreakout: true,
        type: SignalType.breakdown,
        strength: strength,
        description: '跌破当日新低 ${currentData.lowPrice.toString()}',
        additionalData: {
          'newLow': currentData.currentValue.toString(),
          'previousLow': currentData.lowPrice.toString(),
          'breakdownPercentage':
              ((currentData.lowPrice - currentData.currentValue) *
                      Decimal.fromInt(100) /
                      currentData.lowPrice)
                  .toString(),
        },
      ));
    }

    return signals.isNotEmpty
        ? signals.first
        : PriceBreakoutAnalysis(hasBreakout: false);
  }

  /// 分析趋势
  TrendAnalysis _analyzeTrend(String indexCode) {
    final history = _changeHistory[indexCode];
    if (history == null || history.length < _parameters.minHistoryForTrend) {
      return TrendAnalysis(hasReversal: false);
    }

    final recentChanges = history.take(_parameters.trendPeriod).toList();

    // 计算短期和长期趋势
    final shortTermTrend = _calculateTrend(
        recentChanges.take(_parameters.shortTermPeriod).toList());
    final longTermTrend = _calculateTrend(recentChanges);

    // 检测趋势反转
    if (shortTermTrend != longTermTrend &&
        shortTermTrend != TrendDirection.neutral) {
      final strength = _calculateTrendReversalStrength(
          recentChanges, shortTermTrend, longTermTrend);

      return TrendAnalysis(
        hasReversal: true,
        previousTrend: longTermTrend,
        currentTrend: shortTermTrend,
        strength: strength,
        description:
            '趋势反转: ${_getTrendDescription(longTermTrend)} → ${_getTrendDescription(shortTermTrend)}',
      );
    }

    return TrendAnalysis(hasReversal: false);
  }

  /// 计算趋势方向
  TrendDirection _calculateTrend(List<IndexChangeData> changes) {
    if (changes.isEmpty) return TrendDirection.neutral;

    int risingCount = 0;
    int fallingCount = 0;

    for (final change in changes) {
      if (change.currentData.isRising) {
        risingCount++;
      } else if (change.currentData.isFalling) {
        fallingCount++;
      }
    }

    final total = changes.length;
    final risingRatio = risingCount / total;
    final fallingRatio = fallingCount / total;

    if (risingRatio >= _parameters.trendThreshold) {
      return TrendDirection.upward;
    } else if (fallingRatio >= _parameters.trendThreshold) {
      return TrendDirection.downward;
    } else {
      return TrendDirection.neutral;
    }
  }

  /// 计算趋势反转强度
  SignalStrength _calculateTrendReversalStrength(
    List<IndexChangeData> changes,
    TrendDirection shortTerm,
    TrendDirection longTerm,
  ) {
    // 基于最近变化的幅度计算反转强度
    final recentChanges = changes.take(_parameters.shortTermPeriod).toList();
    Decimal totalChange = Decimal.zero;

    for (final change in recentChanges) {
      totalChange += change.currentData.changePercentage.abs();
    }

    final Decimal averageChange = Decimal.parse(
        (totalChange / Decimal.fromInt(recentChanges.length)).toString());

    if (averageChange >= Decimal.fromInt(2)) {
      return SignalStrength.strong;
    } else if (averageChange >= Decimal.fromInt(1)) {
      return SignalStrength.moderate;
    } else {
      return SignalStrength.weak;
    }
  }

  /// 获取趋势描述
  String _getTrendDescription(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.upward:
        return '上升';
      case TrendDirection.downward:
        return '下降';
      case TrendDirection.neutral:
        return '横盘';
    }
  }

  /// 分析支撑阻力位
  SupportResistanceAnalysis _analyzeSupportResistance(
      MarketIndexData currentData) {
    // 这里可以实现更复杂的支撑阻力位算法
    // 暂时使用简单的价格水平分析

    final currentPrice = currentData.currentValue;
    final changePercentage = currentData.changePercentage.abs();

    // 检查是否接近重要的整数关口
    final priceLevel = currentPrice.toDouble();
    final nearbyLevel = (priceLevel / 100).round() * 100; // 最近的100点关口
    final distanceToLevel = (priceLevel - nearbyLevel).abs();

    if (distanceToLevel <= 5 && changePercentage >= Decimal.parse('0.5')) {
      return SupportResistanceAnalysis(
        hasSignal: true,
        type: currentData.isRising
            ? SignalType.resistanceTest
            : SignalType.supportTest,
        strength: SignalStrength.moderate,
        description: '测试${currentData.isRising ? '阻力' : '支撑'}位 $nearbyLevel',
        additionalData: {
          'priceLevel': nearbyLevel.toString(),
          'currentPrice': currentPrice.toString(),
          'distance': distanceToLevel.toString(),
        },
      );
    }

    return SupportResistanceAnalysis(hasSignal: false);
  }

  /// 分析波动率
  VolatilityAnalysis _analyzeVolatility(String indexCode) {
    final history = _changeHistory[indexCode];
    if (history == null ||
        history.length < _parameters.minHistoryForVolatility) {
      return VolatilityAnalysis(isUnusual: false);
    }

    final recentChanges = history.take(_parameters.volatilityPeriod).toList();

    // 计算变化百分比的标准差
    final changes =
        recentChanges.map((c) => c.currentData.changePercentage).toList();
    final currentVolatility = _calculateStandardDeviation(changes);

    // 计算历史平均波动率
    final allChanges =
        history.map((c) => c.currentData.changePercentage).toList();
    final averageVolatility = _calculateStandardDeviation(allChanges);

    if (averageVolatility == Decimal.zero) {
      return VolatilityAnalysis(isUnusual: false);
    }

    final Decimal volatilityRatio =
        Decimal.parse((currentVolatility / averageVolatility).toString());
    final isUnusual = volatilityRatio >= Decimal.fromInt(2); // 当前波动率是平均的2倍以上

    return VolatilityAnalysis(
      isUnusual: isUnusual,
      currentVolatility: currentVolatility,
      averageVolatility: averageVolatility,
      volatilityRatio: volatilityRatio,
      strength: volatilityRatio >= Decimal.fromInt(3)
          ? SignalStrength.strong
          : SignalStrength.moderate,
      description:
          '当前波动率${(volatilityRatio * Decimal.fromInt(100)).truncate()}%${isUnusual ? '异常' : ''}',
    );
  }

  /// 计算标准差
  Decimal _calculateStandardDeviation(List<Decimal> values) {
    if (values.isEmpty) return Decimal.zero;

    final Decimal mean = Decimal.parse(
        (values.reduce((a, b) => a + b) / Decimal.fromInt(values.length))
            .toString());
    final squaredDifferences = values.map((v) {
      final diff = v - mean;
      return diff * diff;
    });

    final Decimal variance = Decimal.parse(
        (squaredDifferences.reduce((a, b) => a + b) /
                Decimal.fromInt(values.length))
            .toString());

    // 简化的平方根计算
    return _sqrt(variance);
  }

  /// 简化的平方根计算
  Decimal _sqrt(Decimal value) {
    if (value <= Decimal.zero) return Decimal.zero;

    double v = value.toDouble();
    return Decimal.parse(math.sqrt(v).toStringAsFixed(6));
  }

  /// 增强变化幅度等级
  ChangeMagnitude _enhanceMagnitude(
      ChangeMagnitude originalMagnitude, List<TechnicalSignal> signals) {
    // 如果有强信号，提升幅度等级
    final hasStrongSignal =
        signals.any((s) => s.strength == SignalStrength.strong);

    if (hasStrongSignal) {
      switch (originalMagnitude) {
        case ChangeMagnitude.minimal:
          return ChangeMagnitude.minor;
        case ChangeMagnitude.minor:
          return ChangeMagnitude.moderate;
        case ChangeMagnitude.moderate:
          return ChangeMagnitude.major;
        case ChangeMagnitude.major:
          return ChangeMagnitude.major; // 已经是最高级
      }
    }

    return originalMagnitude;
  }

  /// 判断是否为显著变化
  bool _isSignificantChange(
      IndexChangeData basicChangeData, List<TechnicalSignal> signals) {
    // 原始显著变化判断
    if (basicChangeData.isSignificant) return true;

    // 有强技术信号也认为是显著的
    return signals.any((s) => s.strength == SignalStrength.strong);
  }

  /// 记录变化历史
  void _recordChangeHistory(String indexCode, IndexChangeData changeData) {
    if (!_changeHistory.containsKey(indexCode)) {
      _changeHistory[indexCode] = Queue<IndexChangeData>();
    }

    final history = _changeHistory[indexCode]!;
    history.add(changeData);

    // 保持历史记录在合理范围内
    while (history.length > _parameters.maxHistoryLength) {
      history.removeFirst();
    }
  }

  /// 获取指数的变化历史
  List<IndexChangeData> getChangeHistory(String indexCode) {
    final history = _changeHistory[indexCode];
    return history?.toList() ?? [];
  }

  /// 清除指数的历史记录
  void clearHistory(String indexCode) {
    _changeHistory.remove(indexCode);
  }

  /// 获取所有指数的统计信息
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};

    for (final entry in _changeHistory.entries) {
      final indexCode = entry.key;
      final history = entry.value;

      if (history.isNotEmpty) {
        final totalChanges = history.length;
        final significantChanges = history.where((c) => c.isSignificant).length;
        final lastChange = history.last;

        stats[indexCode] = {
          'totalChanges': totalChanges,
          'significantChanges': significantChanges,
          'lastChangeTime': lastChange.changeTime.toIso8601String(),
          'lastChangeDescription': lastChange.changeDescription,
          'currentTrend':
              _calculateTrend(history.take(_parameters.trendPeriod).toList())
                  .name,
        };
      }
    }

    return stats;
  }
}

/// 技术分析参数
class TechnicalAnalysisParameters {
  /// 大幅波动阈值
  final Decimal largeMoveThreshold;

  /// 趋势判断阈值
  final double trendThreshold;

  /// 最小历史记录数(用于趋势分析)
  final int minHistoryForTrend;

  /// 最小历史记录数(用于波动率分析)
  final int minHistoryForVolatility;

  /// 最大历史记录长度
  final int maxHistoryLength;

  /// 趋势分析周期
  final int trendPeriod;

  /// 短期趋势周期
  final int shortTermPeriod;

  /// 波动率分析周期
  final int volatilityPeriod;

  TechnicalAnalysisParameters({
    Decimal? largeMoveThreshold,
    this.trendThreshold = 0.6,
    this.minHistoryForTrend = 5,
    this.minHistoryForVolatility = 10,
    this.maxHistoryLength = 100,
    this.trendPeriod = 20,
    this.shortTermPeriod = 5,
    this.volatilityPeriod = 30,
  }) : largeMoveThreshold = largeMoveThreshold ?? Decimal.parse('2');
}

/// 成交量变化分析结果
class VolumeChangeAnalysis {
  final bool isAnomalous;
  final SignalStrength strength;
  final String description;
  final Decimal changePercentage;

  const VolumeChangeAnalysis({
    required this.isAnomalous,
    required this.strength,
    required this.description,
    required this.changePercentage,
  });
}

/// 价格突破分析结果
class PriceBreakoutAnalysis {
  final bool hasBreakout;
  final SignalType? type;
  final SignalStrength? strength;
  final String? description;
  final Map<String, String>? additionalData;

  const PriceBreakoutAnalysis({
    required this.hasBreakout,
    this.type,
    this.strength,
    this.description,
    this.additionalData,
  });
}

/// 趋势分析结果
class TrendAnalysis {
  final bool hasReversal;
  final TrendDirection? previousTrend;
  final TrendDirection? currentTrend;
  final SignalStrength? strength;
  final String? description;

  const TrendAnalysis({
    required this.hasReversal,
    this.previousTrend,
    this.currentTrend,
    this.strength,
    this.description,
  });
}

/// 支撑阻力位分析结果
class SupportResistanceAnalysis {
  final bool hasSignal;
  final SignalType? type;
  final SignalStrength? strength;
  final String? description;
  final Map<String, String>? additionalData;

  const SupportResistanceAnalysis({
    required this.hasSignal,
    this.type,
    this.strength,
    this.description,
    this.additionalData,
  });
}

/// 波动率分析结果
class VolatilityAnalysis {
  final bool isUnusual;
  final Decimal? currentVolatility;
  final Decimal? averageVolatility;
  final Decimal? volatilityRatio;
  final SignalStrength? strength;
  final String? description;

  const VolatilityAnalysis({
    required this.isUnusual,
    this.currentVolatility,
    this.averageVolatility,
    this.volatilityRatio,
    this.strength,
    this.description,
  });
}

/// 趋势方向枚举
enum TrendDirection {
  upward,
  downward,
  neutral;

  String get description {
    switch (this) {
      case TrendDirection.upward:
        return '上升';
      case TrendDirection.downward:
        return '下降';
      case TrendDirection.neutral:
        return '横盘';
    }
  }
}
