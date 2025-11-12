import 'package:decimal/decimal.dart';

import '../../models/fund_nav_data.dart';
import '../../../../core/utils/logger.dart';

/// 净值变化检测器
///
/// 检测基金净值的变化趋势、幅度和类型
/// 支持多种变化检测算法和阈值配置
class NavChangeDetector {
  /// 默认显著变化阈值 (0.1%)
  static final Decimal _defaultSignificantThreshold = Decimal.parse('0.001');

  /// 默认大幅变化阈值 (2%)
  static final Decimal _defaultLargeChangeThreshold = Decimal.parse('0.02');

  /// 默认剧烈变化阈值 (5%)
  static final Decimal _defaultVolatilityThreshold = Decimal.parse('0.05');

  /// 显著变化阈值
  final Decimal significantThreshold;

  /// 大幅变化阈值
  final Decimal largeChangeThreshold;

  /// 剧烈变化阈值
  final Decimal volatilityThreshold;

  /// 是否启用趋势分析
  final bool enableTrendAnalysis;

  /// 历史数据窗口大小 (用于趋势分析)
  final int trendWindowSize;

  /// 历史数据缓存
  final Map<String, List<FundNavData>> _historyBuffer = {};

  /// 创建净值变化检测器
  NavChangeDetector({
    Decimal? significantThreshold,
    Decimal? largeChangeThreshold,
    Decimal? volatilityThreshold,
    this.enableTrendAnalysis = true,
    this.trendWindowSize = 10,
  })  : significantThreshold =
            significantThreshold ?? _defaultSignificantThreshold,
        largeChangeThreshold =
            largeChangeThreshold ?? _defaultLargeChangeThreshold,
        volatilityThreshold =
            volatilityThreshold ?? _defaultVolatilityThreshold;

  /// 检测净值变化
  NavChangeInfo detectChange(FundNavData previousNav, FundNavData currentNav) {
    try {
      // 计算基础变化指标
      final Decimal changeAmount = currentNav.nav - previousNav.nav;
      final Decimal changeRate = previousNav.nav > Decimal.zero
          ? Decimal.parse(
              (changeAmount.toDouble() / previousNav.nav.toDouble()).toString())
          : Decimal.zero;

      // 确定变化类型
      final changeType = _determineChangeType(changeRate);

      // 计算变化强度
      final changeIntensity = _calculateChangeIntensity(changeRate);

      // 检测是否为显著变化
      final isSignificant =
          (changeRate.abs() as Decimal) >= significantThreshold;

      // 检测是否为大幅变化
      final isLargeChange =
          (changeRate.abs() as Decimal) >= largeChangeThreshold;

      // 检测是否为剧烈变化
      final isVolatile = (changeRate.abs() as Decimal) >= volatilityThreshold;

      // 趋势分析
      NavTrend? trend;
      if (enableTrendAnalysis) {
        trend = _analyzeTrend(currentNav.fundCode, currentNav);
      }

      // 异常检测
      final anomalyInfo = _detectAnomaly(previousNav, currentNav, changeRate);

      // 生成变化描述
      final description = _generateChangeDescription(
        changeType,
        changeRate,
        isSignificant,
        isLargeChange,
        isVolatile,
        trend,
        anomalyInfo,
      );

      return NavChangeInfo(
        changeType: changeType,
        changeAmount: changeAmount,
        changeRate: changeRate,
        changePercentage: changeRate * Decimal.fromInt(100),
        isSignificant: isSignificant,
        isLargeChange: isLargeChange,
        isVolatile: isVolatile,
        changeIntensity: changeIntensity,
        trend: trend,
        anomalyInfo: anomalyInfo,
        description: description,
        previousNav: previousNav,
        currentNav: currentNav,
        detectionTime: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('Failed to detect NAV change', e);
      return _createErrorChangeInfo(previousNav, currentNav, e);
    }
  }

  /// 确定变化类型
  NavChangeType _determineChangeType(Decimal changeRate) {
    if (changeRate > Decimal.zero) {
      if (changeRate >= largeChangeThreshold) {
        return NavChangeType.surge; // 激增
      } else if (changeRate >= significantThreshold) {
        return NavChangeType.rise; // 上涨
      } else {
        return NavChangeType.slightRise; // 小幅上涨
      }
    } else if (changeRate < Decimal.zero) {
      if (changeRate <= -largeChangeThreshold) {
        return NavChangeType.plunge; // 暴跌
      } else if (changeRate <= -significantThreshold) {
        return NavChangeType.fall; // 下跌
      } else {
        return NavChangeType.slightFall; // 小幅下跌
      }
    } else {
      return NavChangeType.flat; // 持平
    }
  }

  /// 计算变化强度 (0-1)
  double _calculateChangeIntensity(Decimal changeRate) {
    final absoluteRate = changeRate.abs();

    if (absoluteRate >= volatilityThreshold) {
      return 1.0; // 剧烈变化
    } else if (absoluteRate >= largeChangeThreshold) {
      return 0.8; // 大幅变化
    } else if (absoluteRate >= significantThreshold) {
      return 0.5; // 显著变化
    } else {
      // 线性插值计算小幅变化的强度
      final ratio = (absoluteRate / significantThreshold).toDouble();
      return (ratio * 0.4).clamp(0.0, 0.4);
    }
  }

  /// 分析趋势
  NavTrend? _analyzeTrend(String fundCode, FundNavData currentNav) {
    try {
      // 更新历史缓存
      _updateHistoryBuffer(fundCode, currentNav);

      final history = _historyBuffer[fundCode] ?? [];
      if (history.length < 3) {
        return null; // 数据不足，无法分析趋势
      }

      // 计算趋势指标
      final recentData = history.take(trendWindowSize).toList();
      final trendDirection = _calculateTrendDirection(recentData);
      final volatility = _calculateVolatility(recentData);
      final momentum = _calculateMomentum(recentData);

      return NavTrend(
        direction: trendDirection,
        strength: _calculateTrendStrength(recentData, trendDirection),
        volatility: volatility,
        momentum: momentum,
        duration: _calculateTrendDuration(recentData, trendDirection),
        confidence: _calculateTrendConfidence(recentData, trendDirection),
      );
    } catch (e) {
      AppLogger.warn('Failed to analyze trend for fund $fundCode: $e');
      return null;
    }
  }

  /// 更新历史缓存
  void _updateHistoryBuffer(String fundCode, FundNavData navData) {
    if (!_historyBuffer.containsKey(fundCode)) {
      _historyBuffer[fundCode] = [];
    }

    final buffer = _historyBuffer[fundCode]!;

    // 添加新数据
    buffer.add(navData);

    // 保持窗口大小
    while (buffer.length > trendWindowSize) {
      buffer.removeAt(0);
    }
  }

  /// 计算趋势方向
  TrendDirection _calculateTrendDirection(List<FundNavData> data) {
    if (data.length < 2) return TrendDirection.unknown;

    // 使用线性回归计算趋势
    final n = data.length;
    final sumX = (n * (n - 1) / 2).toDouble(); // 0 + 1 + 2 + ... + (n-1)
    final sumY = data.fold<double>(0, (sum, item) => sum + item.nav.toDouble());
    final sumXY = data.fold<double>(0, (sum, item) {
      final x = data.indexOf(item).toDouble();
      return sum + (x * item.nav.toDouble());
    });
    final sumX2 = (n * (n - 1) * (2 * n - 1) / 6)
        .toDouble(); // 0^2 + 1^2 + 2^2 + ... + (n-1)^2

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    if (slope > 0.001) {
      return TrendDirection.upward;
    } else if (slope < -0.001) {
      return TrendDirection.downward;
    } else {
      return TrendDirection.sideways;
    }
  }

  /// 计算波动率
  double _calculateVolatility(List<FundNavData> data) {
    if (data.length < 2) return 0.0;

    final returns = <double>[];
    for (int i = 1; i < data.length; i++) {
      final previousNav = data[i - 1].nav.toDouble();
      final currentNav = data[i].nav.toDouble();
      if (previousNav > 0) {
        returns.add((currentNav - previousNav) / previousNav);
      }
    }

    if (returns.isEmpty) return 0.0;

    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.fold(0.0, (sum, ret) {
          return sum + (ret - mean) * (ret - mean);
        }) /
        returns.length;

    return variance > 0 ? variance : 0.0;
  }

  /// 计算动量
  double _calculateMomentum(List<FundNavData> data) {
    if (data.length < 2) return 0.0;

    final oldest = data.first.nav.toDouble();
    final newest = data.last.nav.toDouble();

    return oldest > 0 ? (newest - oldest) / oldest : 0.0;
  }

  /// 计算趋势强度
  double _calculateTrendStrength(
      List<FundNavData> data, TrendDirection direction) {
    if (data.length < 3) return 0.0;

    // 计算趋势一致性
    int consistentCount = 0;
    for (int i = 1; i < data.length; i++) {
      final change = data[i].nav - data[i - 1].nav;
      if ((direction == TrendDirection.upward && change > Decimal.zero) ||
          (direction == TrendDirection.downward && change < Decimal.zero) ||
          (direction == TrendDirection.sideways &&
              change.abs() <= Decimal.parse('0.001'))) {
        consistentCount++;
      }
    }

    return consistentCount / (data.length - 1);
  }

  /// 计算趋势持续时间
  int _calculateTrendDuration(
      List<FundNavData> data, TrendDirection direction) {
    int duration = 0;
    for (int i = data.length - 1; i >= 1; i--) {
      final change = data[i].nav - data[i - 1].nav;
      final isConsistent =
          (direction == TrendDirection.upward && change > Decimal.zero) ||
              (direction == TrendDirection.downward && change < Decimal.zero) ||
              (direction == TrendDirection.sideways &&
                  change.abs() <= Decimal.parse('0.001'));

      if (isConsistent) {
        duration++;
      } else {
        break;
      }
    }
    return duration;
  }

  /// 计算趋势置信度
  double _calculateTrendConfidence(
      List<FundNavData> data, TrendDirection direction) {
    if (data.length < 3) return 0.0;

    final strength = _calculateTrendStrength(data, direction);
    final volatility = _calculateVolatility(data);

    // 低波动率和高一致性的趋势置信度更高
    return strength * (1.0 - (volatility.clamp(0.0, 1.0) * 0.5));
  }

  /// 检测异常
  NavAnomalyInfo _detectAnomaly(
    FundNavData previousNav,
    FundNavData currentNav,
    Decimal changeRate,
  ) {
    final isAnomaly = changeRate.abs() >= volatilityThreshold;

    if (!isAnomaly) {
      return const NavAnomalyInfo(
        isAnomaly: false,
        anomalyType: null,
        severity: AnomalySeverity.none,
        confidence: 0.0,
        description: '无异常',
      );
    }

    // 确定异常类型
    AnomalyType anomalyType;
    AnomalySeverity severity;
    String description;

    if (changeRate >= volatilityThreshold * Decimal.parse('2')) {
      anomalyType = AnomalyType.extremeSpike;
      severity = AnomalySeverity.critical;
      description = '极端异常：净值出现异常激增';
    } else if (changeRate >= volatilityThreshold) {
      anomalyType = AnomalyType.significantSpike;
      severity = AnomalySeverity.high;
      description = '显著异常：净值出现大幅变化';
    } else if (changeRate <= -volatilityThreshold * Decimal.parse('2')) {
      anomalyType = AnomalyType.extremeDrop;
      severity = AnomalySeverity.critical;
      description = '极端异常：净值出现异常暴跌';
    } else {
      anomalyType = AnomalyType.significantDrop;
      severity = AnomalySeverity.high;
      description = '显著异常：净值出现大幅下跌';
    }

    // 计算置信度 (基于变化幅度)
    final confidence =
        (changeRate.abs() / volatilityThreshold).toDouble().clamp(0.0, 1.0);

    return NavAnomalyInfo(
      isAnomaly: true,
      anomalyType: anomalyType,
      severity: severity,
      confidence: confidence,
      description: description,
    );
  }

  /// 生成变化描述
  String _generateChangeDescription(
    NavChangeType changeType,
    Decimal changeRate,
    bool isSignificant,
    bool isLargeChange,
    bool isVolatile,
    NavTrend? trend,
    NavAnomalyInfo anomalyInfo,
  ) {
    final buffer = StringBuffer();

    // 基础变化描述
    switch (changeType) {
      case NavChangeType.surge:
        buffer.write('净值激增');
        break;
      case NavChangeType.rise:
        buffer.write('净值上涨');
        break;
      case NavChangeType.slightRise:
        buffer.write('净值小幅上涨');
        break;
      case NavChangeType.flat:
        buffer.write('净值持平');
        break;
      case NavChangeType.slightFall:
        buffer.write('净值小幅下跌');
        break;
      case NavChangeType.fall:
        buffer.write('净值下跌');
        break;
      case NavChangeType.plunge:
        buffer.write('净值暴跌');
        break;
      case NavChangeType.none:
        buffer.write('净值无变化');
        break;
      case NavChangeType.dataError:
        buffer.write('数据错误');
        break;
      case NavChangeType.unknown:
        buffer.write('未知变化');
        break;
    }

    // 添加变化幅度
    final percentage = (changeRate * Decimal.fromInt(100)).toStringAsFixed(2);
    buffer.write(' $percentage%');

    // 添加强度描述
    if (isVolatile) {
      buffer.write(' (剧烈变化)');
    } else if (isLargeChange) {
      buffer.write(' (大幅变化)');
    } else if (isSignificant) {
      buffer.write(' (显著变化)');
    }

    // 添加趋势信息
    if (trend != null) {
      buffer.write('，趋势');
      switch (trend.direction) {
        case TrendDirection.upward:
          buffer.write('向上');
          break;
        case TrendDirection.downward:
          buffer.write('向下');
          break;
        case TrendDirection.sideways:
          buffer.write('平稳');
          break;
        case TrendDirection.unknown:
          break;
      }
      if (trend.strength > 0.7) {
        buffer.write(' (强劲)');
      } else if (trend.strength < 0.3) {
        buffer.write(' (疲软)');
      }
    }

    // 添加异常信息
    if (anomalyInfo.isAnomaly) {
      buffer.write('，${anomalyInfo.description}');
    }

    return buffer.toString();
  }

  /// 创建错误变化信息
  NavChangeInfo _createErrorChangeInfo(
    FundNavData previousNav,
    FundNavData currentNav,
    dynamic error,
  ) {
    return NavChangeInfo(
      changeType: NavChangeType.dataError,
      changeAmount: currentNav.nav - previousNav.nav,
      changeRate: Decimal.zero,
      changePercentage: Decimal.zero,
      isSignificant: false,
      isLargeChange: false,
      isVolatile: false,
      changeIntensity: 0.0,
      trend: null,
      anomalyInfo: const NavAnomalyInfo(
        isAnomaly: true,
        anomalyType: AnomalyType.dataError,
        severity: AnomalySeverity.medium,
        confidence: 1.0,
        description: '数据检测异常',
      ),
      description: '变化检测失败: $error',
      previousNav: previousNav,
      currentNav: currentNav,
      detectionTime: DateTime.now(),
    );
  }

  /// 清理指定基金的历史缓存
  void clearHistory(String fundCode) {
    _historyBuffer.remove(fundCode);
  }

  /// 清理所有历史缓存
  void clearAllHistory() {
    _historyBuffer.clear();
  }

  /// 获取历史缓存大小
  int getHistorySize(String fundCode) {
    return _historyBuffer[fundCode]?.length ?? 0;
  }

  /// 获取所有缓存的基金代码
  Set<String> get cachedFundCodes => _historyBuffer.keys.toSet();
}

/// 净值变化信息
class NavChangeInfo {
  /// 变化类型
  final NavChangeType changeType;

  /// 变化金额
  final Decimal changeAmount;

  /// 变化率 (小数形式，如：0.0234)
  final Decimal changeRate;

  /// 变化百分比 (如：2.34)
  final Decimal changePercentage;

  /// 是否为显著变化
  final bool isSignificant;

  /// 是否为大幅变化
  final bool isLargeChange;

  /// 是否为剧烈变化
  final bool isVolatile;

  /// 变化强度 (0-1)
  final double changeIntensity;

  /// 趋势信息
  final NavTrend? trend;

  /// 异常信息
  final NavAnomalyInfo anomalyInfo;

  /// 变化描述
  final String description;

  /// 前一个净值数据
  final FundNavData previousNav;

  /// 当前净值数据
  final FundNavData currentNav;

  /// 检测时间
  final DateTime detectionTime;

  /// 是否有变化
  bool get hasChange => changeType != NavChangeType.flat;

  const NavChangeInfo({
    required this.changeType,
    required this.changeAmount,
    required this.changeRate,
    required this.changePercentage,
    required this.isSignificant,
    required this.isLargeChange,
    required this.isVolatile,
    required this.changeIntensity,
    this.trend,
    required this.anomalyInfo,
    required this.description,
    required this.previousNav,
    required this.currentNav,
    required this.detectionTime,
  });

  @override
  String toString() {
    return 'NavChangeInfo(type: $changeType, rate: ${changePercentage.toStringAsFixed(2)}%, description: $description)';
  }
}

/// 净值变化类型
enum NavChangeType {
  /// 激增 (≥2%)
  surge,

  /// 上涨 (≥0.1% 且 <2%)
  rise,

  /// 小幅上涨 (>0% 且 <0.1%)
  slightRise,

  /// 持平 (=0%)
  flat,

  /// 小幅下跌 (<0% 且 >-0.1%)
  slightFall,

  /// 下跌 (≤-0.1% 且 >-2%)
  fall,

  /// 暴跌 (≤-2%)
  plunge,

  /// 无变化
  none,

  /// 数据错误
  dataError,

  /// 未知
  unknown;

  String get description {
    switch (this) {
      case NavChangeType.surge:
        return '激增';
      case NavChangeType.rise:
        return '上涨';
      case NavChangeType.slightRise:
        return '小幅上涨';
      case NavChangeType.flat:
        return '持平';
      case NavChangeType.slightFall:
        return '小幅下跌';
      case NavChangeType.fall:
        return '下跌';
      case NavChangeType.plunge:
        return '暴跌';
      case NavChangeType.none:
        return '无变化';
      case NavChangeType.dataError:
        return '数据错误';
      case NavChangeType.unknown:
        return '未知';
    }
  }
}

/// 趋势方向
enum TrendDirection {
  /// 向上
  upward,

  /// 向下
  downward,

  /// 横盘
  sideways,

  /// 未知
  unknown;

  String get description {
    switch (this) {
      case TrendDirection.upward:
        return '向上';
      case TrendDirection.downward:
        return '向下';
      case TrendDirection.sideways:
        return '横盘';
      case TrendDirection.unknown:
        return '未知';
    }
  }
}

/// 趋势信息
class NavTrend {
  /// 趋势方向
  final TrendDirection direction;

  /// 趋势强度 (0-1)
  final double strength;

  /// 波动率
  final double volatility;

  /// 动量
  final double momentum;

  /// 持续时间 (天数)
  final int duration;

  /// 置信度 (0-1)
  final double confidence;

  const NavTrend({
    required this.direction,
    required this.strength,
    required this.volatility,
    required this.momentum,
    required this.duration,
    required this.confidence,
  });

  @override
  String toString() {
    return 'NavTrend(direction: $direction, strength: ${(strength * 100).toStringAsFixed(1)}%, duration: ${duration}天)';
  }
}

/// 异常信息
class NavAnomalyInfo {
  /// 是否为异常
  final bool isAnomaly;

  /// 异常类型
  final AnomalyType? anomalyType;

  /// 异常严重程度
  final AnomalySeverity severity;

  /// 置信度 (0-1)
  final double confidence;

  /// 异常描述
  final String description;

  const NavAnomalyInfo({
    required this.isAnomaly,
    this.anomalyType,
    required this.severity,
    required this.confidence,
    required this.description,
  });

  @override
  String toString() {
    if (!isAnomaly) return '无异常';
    return 'NavAnomaly(type: $anomalyType, severity: $severity, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

/// 异常类型
enum AnomalyType {
  /// 极端激增
  extremeSpike,

  /// 显著激增
  significantSpike,

  /// 极端暴跌
  extremeDrop,

  /// 显著下跌
  significantDrop,

  /// 数据错误
  dataError,

  /// 其他异常
  other;

  String get description {
    switch (this) {
      case AnomalyType.extremeSpike:
        return '极端激增';
      case AnomalyType.significantSpike:
        return '显著激增';
      case AnomalyType.extremeDrop:
        return '极端暴跌';
      case AnomalyType.significantDrop:
        return '显著下跌';
      case AnomalyType.dataError:
        return '数据错误';
      case AnomalyType.other:
        return '其他异常';
    }
  }
}

/// 异常严重程度
enum AnomalySeverity {
  /// 无异常
  none,

  /// 轻微
  low,

  /// 中等
  medium,

  /// 高
  high,

  /// 严重
  critical;

  String get description {
    switch (this) {
      case AnomalySeverity.none:
        return '无';
      case AnomalySeverity.low:
        return '轻微';
      case AnomalySeverity.medium:
        return '中等';
      case AnomalySeverity.high:
        return '高';
      case AnomalySeverity.critical:
        return '严重';
    }
  }
}
