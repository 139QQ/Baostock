import 'dart:collection';
import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../../../fund/models/fund_nav_data.dart';
import '../../../market/models/market_index_data.dart';
import '../models/market_change_event.dart';
import '../models/change_category.dart';
import '../models/change_severity.dart';

/// 智能市场变化检测器
///
/// 基于现有数据处理管道扩展，负责检测和分析市场数据变化
/// 支持基金净值和市场指数的智能变化检测和分类
class MarketChangeDetector {
  /// 变化检测阈值配置
  final ChangeDetectionThresholds _thresholds;

  /// 变化历史记录 (用于趋势分析)
  final Map<String, Queue<MarketChangeEvent>> _changeHistory = {};

  /// 相关基金映射缓存
  final Map<String, List<String>> _fundCorrelationCache = {};

  /// 构造函数
  MarketChangeDetector({
    ChangeDetectionThresholds? thresholds,
  }) : _thresholds = thresholds ?? ChangeDetectionThresholds();

  /// 检测基金净值变化
  Future<List<MarketChangeEvent>> detectFundNavChanges({
    required Map<String, FundNavData> currentData,
    required Map<String, FundNavData> previousData,
  }) async {
    final changes = <MarketChangeEvent>[];

    for (final entry in currentData.entries) {
      final fundCode = entry.key;
      final currentNav = entry.value;
      final previousNav = previousData[fundCode];

      if (previousNav != null) {
        final change = await _analyzeFundNavChange(
          fundCode: fundCode,
          currentNav: currentNav,
          previousNav: previousNav,
        );

        if (change != null) {
          changes.add(change);
        }
      }
    }

    return changes;
  }

  /// 检测市场指数变化
  Future<List<MarketChangeEvent>> detectMarketIndexChanges({
    required Map<String, MarketIndexData> currentData,
    required Map<String, MarketIndexData> previousData,
  }) async {
    final changes = <MarketChangeEvent>[];

    for (final entry in currentData.entries) {
      final indexCode = entry.key;
      final currentIndex = entry.value;
      final previousIndex = previousData[indexCode];

      if (previousIndex != null) {
        final change = await _analyzeMarketIndexChange(
          indexCode: indexCode,
          currentIndex: currentIndex,
          previousIndex: previousIndex,
        );

        if (change != null) {
          changes.add(change);
        }
      }
    }

    return changes;
  }

  /// 分析基金净值变化
  Future<MarketChangeEvent?> _analyzeFundNavChange({
    required String fundCode,
    required FundNavData currentNav,
    required FundNavData previousNav,
  }) async {
    // 使用现有的变化率计算
    final changeRate = currentNav.changeRate.toDouble();

    // 检查是否超过阈值
    if (changeRate.abs() < _thresholds.fundNavChangeThreshold) {
      return null;
    }

    // 确定变化类别
    final category = _categorizeFundNavChange(
      changeRate: changeRate,
      currentNav: currentNav,
      previousNav: previousNav,
    );

    // 计算变化重要性
    final importance = _calculateChangeImportance(
      category: category,
      changeRate: changeRate,
      dataVolume: '', // FundNavData没有交易量字段
    );

    // 创建变化事件
    final event = MarketChangeEvent(
      id: _generateEventId(),
      type: MarketChangeType.fundNav,
      entityId: fundCode,
      entityName: fundCode, // FundNavData没有基金名称字段
      category: category,
      severity: _calculateSeverity(importance),
      importance: importance,
      changeRate: changeRate,
      currentValue: currentNav.nav.toString(),
      previousValue: previousNav.nav.toString(),
      timestamp: DateTime.now(),
      metadata: {
        'fundCode': fundCode,
        'navType': currentNav.navType.name,
        'dataSource': currentNav.dataSource ?? '',
        'navDate': currentNav.navDate.toIso8601String(),
        'qualityScore': currentNav.qualityScore?.toString() ?? '',
      },
    );

    // 记录变化历史
    _recordChangeHistory(fundCode, event);

    return event;
  }

  /// 分析市场指数变化
  Future<MarketChangeEvent?> _analyzeMarketIndexChange({
    required String indexCode,
    required MarketIndexData currentIndex,
    required MarketIndexData previousIndex,
  }) async {
    // 使用现有的变化率计算
    final changeRate = currentIndex.changePercentage.toDouble();

    // 检查是否超过阈值
    if (changeRate.abs() < _thresholds.marketIndexChangeThreshold) {
      return null;
    }

    // 确定变化类别
    final category = _categorizeMarketIndexChange(
      changeRate: changeRate,
      currentIndex: currentIndex,
      previousIndex: previousIndex,
    );

    // 计算变化重要性
    final importance = _calculateChangeImportance(
      category: category,
      changeRate: changeRate,
      dataVolume: currentIndex.volume.toString(),
    );

    // 创建变化事件
    final event = MarketChangeEvent(
      id: _generateEventId(),
      type: MarketChangeType.marketIndex,
      entityId: indexCode,
      entityName: currentIndex.name,
      category: category,
      severity: _calculateSeverity(importance),
      importance: importance,
      changeRate: changeRate,
      currentValue: currentIndex.currentValue.toString(),
      previousValue: previousIndex.currentValue.toString(),
      timestamp: DateTime.now(),
      metadata: {
        'indexCode': indexCode,
        'changeAmount': currentIndex.changeAmount.toString(),
        'changePercentage': currentIndex.changePercentage.toString(),
        'volume': currentIndex.volume.toString(),
        'turnover': currentIndex.turnover.toString(),
        'updateTime': currentIndex.updateTime.toIso8601String(),
        'marketStatus': currentIndex.marketStatus.name,
      },
    );

    // 记录变化历史
    _recordChangeHistory(indexCode, event);

    return event;
  }

  /// 分类基金净值变化
  ChangeCategory _categorizeFundNavChange({
    required double changeRate,
    required FundNavData currentNav,
    required FundNavData previousNav,
  }) {
    // 异常事件检测
    if (changeRate.abs() > _thresholds.abnormalChangeThreshold) {
      return ChangeCategory.abnormalEvent;
    }

    // 趋势变化检测
    final history = _changeHistory[currentNav.fundCode];
    if (history != null &&
        history.isNotEmpty &&
        _detectTrendReversal(history, changeRate)) {
      return ChangeCategory.trendChange;
    }

    // 大幅价格变化
    if (changeRate.abs() > _thresholds.significantPriceChangeThreshold) {
      return ChangeCategory.priceChange;
    }

    // 默认为常规价格波动
    return ChangeCategory.priceChange;
  }

  /// 分类市场指数变化
  ChangeCategory _categorizeMarketIndexChange({
    required double changeRate,
    required MarketIndexData currentIndex,
    required MarketIndexData previousIndex,
  }) {
    // 异常事件检测
    if (changeRate.abs() > _thresholds.abnormalChangeThreshold) {
      return ChangeCategory.abnormalEvent;
    }

    // 重要指数突破
    if (_isImportantIndexBreakthrough(
        currentIndex, previousIndex, changeRate)) {
      return ChangeCategory.priceChange;
    }

    // 趋势变化检测
    final history = _changeHistory[currentIndex.code];
    if (history != null &&
        history.isNotEmpty &&
        _detectTrendReversal(history, changeRate)) {
      return ChangeCategory.trendChange;
    }

    // 默认为常规价格波动
    return ChangeCategory.priceChange;
  }

  /// 计算变化重要性
  double _calculateChangeImportance({
    required ChangeCategory category,
    required double changeRate,
    required String dataVolume,
  }) {
    // 基础重要性分数
    var importance = changeRate.abs();

    // 根据类别调整
    switch (category) {
      case ChangeCategory.abnormalEvent:
        importance *= 2.0; // 异常事件重要性翻倍
        break;
      case ChangeCategory.trendChange:
        importance *= 1.5; // 趋势变化重要性增加50%
        break;
      case ChangeCategory.priceChange:
        importance *= 1.0; // 价格变化保持基础重要性
        break;
    }

    // 根据交易量调整
    final volume = Decimal.tryParse(dataVolume) ?? Decimal.zero;
    if (volume > Decimal.fromInt(1000000)) {
      // 100万以上
      importance *= 1.2;
    }

    // 确保重要性分数在0-100之间
    return math.min(100.0, importance);
  }

  /// 计算变化严重程度
  ChangeSeverity _calculateSeverity(double importance) {
    if (importance >= _thresholds.highSeverityThreshold) {
      return ChangeSeverity.high;
    } else if (importance >= _thresholds.mediumSeverityThreshold) {
      return ChangeSeverity.medium;
    } else {
      return ChangeSeverity.low;
    }
  }

  /// 检测趋势反转
  bool _detectTrendReversal(
      Queue<MarketChangeEvent> history, double currentChangeRate) {
    if (history.length < 3) return false;

    final recentChanges = history.take(3).toList();
    final avgChangeRate =
        recentChanges.map((e) => e.changeRate).reduce((a, b) => a + b) /
            recentChanges.length;

    // 如果当前变化方向与近期趋势相反，且幅度较大，则认为是趋势反转
    return (avgChangeRate * currentChangeRate < 0) &&
        (currentChangeRate.abs() > avgChangeRate.abs() * 1.5);
  }

  /// 检测重要指数突破
  bool _isImportantIndexBreakthrough(
    MarketIndexData currentIndex,
    MarketIndexData previousIndex,
    double changeRate,
  ) {
    // 检查是否突破重要整数关口
    final currentPoint = currentIndex.currentValue.toDouble();
    final previousPoint = previousIndex.currentValue.toDouble();

    // 检查千点、百点关口突破
    for (final milestone in [1000, 2000, 3000, 4000, 5000]) {
      if ((previousPoint < milestone && currentPoint >= milestone) ||
          (previousPoint > milestone && currentPoint <= milestone)) {
        return true;
      }
    }

    return false;
  }

  /// 记录变化历史
  void _recordChangeHistory(String entityId, MarketChangeEvent event) {
    final history =
        _changeHistory.putIfAbsent(entityId, () => Queue<MarketChangeEvent>());
    history.addFirst(event);

    // 保持历史记录大小
    while (history.length > 50) {
      history.removeLast();
    }
  }

  /// 生成事件ID
  String _generateEventId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  /// 获取相关基金
  Future<List<String>> getRelatedFunds(String marketIndexCode) async {
    // 这里应该实现相关基金关联逻辑
    // 暂时返回空列表，后续实现
    return _fundCorrelationCache[marketIndexCode] ?? [];
  }

  /// 清理缓存
  void clearCache() {
    _changeHistory.clear();
    _fundCorrelationCache.clear();
  }
}

/// 变化检测阈值配置
class ChangeDetectionThresholds {
  /// 基金净值变化阈值 (百分比)
  final double fundNavChangeThreshold;

  /// 市场指数变化阈值 (百分比)
  final double marketIndexChangeThreshold;

  /// 异常变化阈值 (百分比)
  final double abnormalChangeThreshold;

  /// 重要价格变化阈值 (百分比)
  final double significantPriceChangeThreshold;

  /// 高严重程度阈值
  final double highSeverityThreshold;

  /// 中等严重程度阈值
  final double mediumSeverityThreshold;

  const ChangeDetectionThresholds({
    this.fundNavChangeThreshold = 0.5, // 0.5%
    this.marketIndexChangeThreshold = 0.3, // 0.3%
    this.abnormalChangeThreshold = 5.0, // 5%
    this.significantPriceChangeThreshold = 2.0, // 2%
    this.highSeverityThreshold = 5.0, // 5分以上
    this.mediumSeverityThreshold = 2.0, // 2分以上
  });
}
